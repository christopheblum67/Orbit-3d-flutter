import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

/// Parseur XMLTV mono-passe (SAX-like) sans construction de DOM.
///
/// Traitement séquentiel du texte brut : on repère les balises `<programme>`
/// par position, puis on extrait les attributs (`channel`, `start`, `stop`)
/// et les contenus des sous-éléments (`<title>`, `<desc>`) sans jamais
/// instancier de nœud [XmlDocument].
///
/// Avantages par rapport à `XmlDocument.parse` :
///  - Pas d'allocation de l'arbre complet (~94 000 nœuds → 0).
///  - Même mémoire constante : seule la dernière entrée en cours de
///    traitement est en vie (les programmes déjà parsés sont des objets
///    Dart légers).
///  - Adapté au traitement en isolate (pas de dépendance xml).
class EpgStreamParser {
  EpgStreamParser._();

  /// Parse le contenu XMLTV complet et retourne la liste des programmes.
  static List<EPGProgram> parse(String content) {
    final programs = <EPGProgram>[];
    var pos = 0;

    while (pos < content.length) {
      final openIdx = content.indexOf('<programme', pos);
      if (openIdx == -1) break;

      final tagEnd = content.indexOf('>', openIdx);
      if (tagEnd == -1) break;

      final tagText = content.substring(openIdx, tagEnd + 1);

      // Recherche de la fin de cet élément (balise fermante associée) ou
      // du prochain `<programme>` (si auto-fermante ou le parser est souple).
      final closeIdx = _findEndOfElement(content, tagEnd + 1);

      // Attributs du tag d'ouverture.
      final channelId = _extractAttr(tagText, 'channel') ?? '';
      final startRaw = _extractAttr(tagText, 'start');
      final stopRaw = _extractAttr(tagText, 'stop');

      if (startRaw == null || stopRaw == null || channelId.isEmpty) {
        pos = closeIdx;
        continue;
      }

      final start = parseXmltvDate(startRaw);
      final end = parseXmltvDate(stopRaw);
      if (start == null || end == null) {
        pos = closeIdx;
        continue;
      }

      // Corps du bloc : entre la fin du tag d'ouverture et closeIdx.
      final body = content.substring(tagEnd + 1, closeIdx);
      final title = _extractElement(body, 'title');
      final desc = _extractElement(body, 'desc');

      programs.add(
        EPGProgram(
          channelId: channelId,
          title: title,
          description: desc,
          start: start,
          end: end,
        ),
      );

      pos = closeIdx;
    }

    // Les consommateurs (index global, `epgCurrentProgram`, `epgNextProgram`)
    // locating par dichotomie supposent une liste triee par `start`. Or l'ordre
    // du XMLTV n'est pas garanti : certains panels livrent les programmes dans
    // le desordre, et `get_short_epg` renvoie frequemment une seule journee
    // melee avec celle d'avant. Sans ce tri, la dichotomie renvoie un
    // programme arbitraire — typiquement vide — alors que la grille parait
    // correctement remplie.
    if (programs.length > 1) {
      programs.sort((a, b) => a.start.compareTo(b.start));
    }

    return programs;
  }

  // ─── Helpers internes ──────────────────────────────────────────────

  /// Extrait la valeur d'un attribut XML dans un tag brut.
  /// `name="value"` → `"value"`. Gère les guillemets simples/ doubles.
  static String? _extractAttr(String tag, String name) {
    // Recherche la séquence `name=` suivi de la valeur entre quotes.
    final idx = tag.indexOf('$name=');
    if (idx == -1) return null;
    final afterEq = idx + name.length + 1;
    if (afterEq >= tag.length) return null;
    final quote = tag[afterEq];
    if (quote != '"' && quote != "'") return null;
    final endQuote = tag.indexOf(quote, afterEq + 1);
    if (endQuote == -1) return null;
    return tag.substring(afterEq + 1, endQuote);
  }

  /// Trouve la fin d'un élément XML ouvre `{`.
  /// Cherche `</nom>` ou s'il n'existe pas, le prochain `<` ou la fin du texte.
  /// Approche : on cherche la balise fermante `</programme>` ou, à défaut, le
  /// prochain `<` (auto-fermant ou mal formé).
  static int _findEndOfElement(String content, int searchFrom) {
    // On cherche `</programme>` en priorité.
    final endTag = content.indexOf('</programme>', searchFrom);
    if (endTag != -1) return endTag + '</programme>'.length;

    // Sinon : prochain `<` (indique la fin ou le prochain élément).
    final nextTag = content.indexOf('<', searchFrom);
    if (nextTag == -1) return content.length;
    return nextTag;
  }

  /// Extrait le contenu texte d'un sous-élément dans un bloc de texte brut.
  /// `<title>Mon programme</title>` → `"Mon programme"`.
  ///
  /// Le texte est dé-échappé : le XMLTV échappe l'apostrophe en `&apos;` et les
  /// guillemets en `&quot;`, et le parseur travaille sur la chaîne BRUTE (pas
  /// via un DOM XML), donc ces entités arrivaient telles quelles jusqu'à
  /// l'écran. L'utilisateur lisait « C dans l&apos;achat ».
  ///
  /// `&amp;` est traité en DERNIER : un seul passage de dé-échappement, sinon
  /// `&amp;apos;` se transformerait à tort en apostrophe.
  /// Extrait le texte d'un élément, **attributs compris**.
  ///
  /// ## Pourquoi ce n'est pas un `indexOf`
  ///
  /// La version précédente cherchait le littéral `<title>`. Or le XMLTV
  /// standard qualifie presque toujours l'élément d'une langue :
  /// `<title lang="fr">Le Journal</title>`. Cette chaîne n'y apparaît jamais,
  /// la recherche renvoyait -1, et le titre revenait VIDE.
  ///
  /// Conséquence à l'écran : les programmes étaient chargés, placés et
  /// coloriés, mais leur texte manquait — donc des cases mauves entièrement
  /// vides. Ce qui expliquait aussi que le journal annonçât « 210 lignes avec
  /// vrais programmes » pour un écran perçu comme vide : la PRÉSENCE était
  /// mesurée, pas le CONTENU.
  ///
  /// `(\s[^>]*)?` tolère les attributs sans les laisser glisser dans le texte.
  /// Il exige soit la fin immédiate de la balise, soit une espace : `<titlefoo>`
  /// ne peut donc pas être confondu avec `<title>`.
  static String _extractElement(String body, String name) {
    final match = RegExp(
      '<$name(\\s[^>]*)?>([\\s\\S]*?)</$name>',
      caseSensitive: false,
    ).firstMatch(body);
    if (match != null) {
      return _unescapeXml(match.group(2)!.trim());
    }
    // Pas de balise fermante : prendre jusqu'à la fin du bloc, comme avant.
    final open = RegExp(
      '<$name(\\s[^>]*)?>',
      caseSensitive: false,
    ).firstMatch(body);
    if (open == null) return '';
    return _unescapeXml(body.substring(open.end).trim());
  }

  /// Résout les cinq entités XML standard, plus les références numériques
  /// (`&#39;`, `&#x27;`).
  static String _unescapeXml(String value) {
    if (!value.contains('&')) return value;
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) {
        final code = int.tryParse(m.group(1)!);
        if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
        return String.fromCharCode(code);
      },
    ).replaceAllMapped(
      RegExp(r'&#[xX]([0-9a-fA-F]+);'),
      (m) {
        final code = int.tryParse(m.group(1)!, radix: 16);
        if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
        return String.fromCharCode(code);
      },
    )
        // En dernier : `&amp;lt;` doit donner `&lt;` et non `<`.
        .replaceAll('&amp;', '&');
  }
}
