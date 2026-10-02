import 'package:flutter/foundation.dart';

import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Contexte permettant de transformer une annonce « fr » en URL
/// téléchargeable.
///
/// Un panel Xtream sert ses sous-titres externes selon la convention
/// `{base}/subtitles/{user}/{pass}/{streamId}_{lang}.srt`. C'est la seule façon
/// d'exploiter le format le plus répandu — une simple liste de codes langue
/// (`"subtitles": ["fr","en"]`), qui ne contient aucune URL.
@immutable
class SubtitleDiscoveryContext {
  const SubtitleDiscoveryContext({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.streamId,
  });

  /// URL de base du panel (`http://host:port`).
  final String baseUrl;
  final String username;
  final String password;

  /// Identifiant du FLUX : `vod_id` pour un film, **stream id d'épisode** pour
  /// une série. `null` si l'appelant ne le connaît pas — la synthèse est alors
  /// impossible et l'on ne déduit rien (mieux vaut une liste vide qu'une piste
  /// pointant sur le mauvais média).
  final String? streamId;

  String get _base {
    final b = baseUrl.trim();
    return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
  }

  /// URL d'un sous-titre externe pour [language], ou `null` si le contexte ne
  /// permet pas de la construire.
  String? urlForLanguage(String language) {
    final id = streamId?.trim();
    final code = language.trim().toLowerCase();
    if (id == null || id.isEmpty || code.isEmpty) return null;
    return '$_base/subtitles/$username/$password/${id}_$code.srt';
  }

  /// Résout un chemin relatif renvoyé par le panel (`1234_fr.srt`).
  ///
  /// Certains panels omettent le nom d'hôte et renvoient un chemin relatif à la
  /// racine du site.
  String? resolvePath(String path) {
    final p = path.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return p.startsWith('/') ? '$_base$p' : '$_base/$p';
  }
}

/// Une piste de sous-titres *annoncée* par le panel, avant tout téléchargement.
///
/// Elle ne contient pas encore les cues : [SubtitleController] ne les charge
/// qu'au moment où l'utilisateur la sélectionne. C'est ce qui permet
/// d'afficher une liste de pistes même quand aucun sous-titre n'a encore été
/// récupéré.
@immutable
class SubtitleTrackRef {
  const SubtitleTrackRef({
    required this.url,
    required this.language,
    required this.label,
    this.cues,
  });

  /// URL de téléchargement renvoyée par le panel.
  final String url;

  /// Code langue (`fre`, `eng`, `sub`, ...). Conservé tel quel : les panels
  /// n'utilisent pas toujours les codes ISO.
  final String language;

  /// Libellé affiché (« Français », « English », ...). Falls back sur le code.
  final String label;

  /// Rempli après téléchargement ([SubtitleController.loadAndSetTrack]).
  ///
  /// `null` tant que la piste n'a pas été chargée : l'interface masque alors le
  /// nombre de cues, qui serait trompeur.
  final List<SubtitleCue>? cues;

  @override
  bool operator ==(Object other) =>
      other is SubtitleTrackRef &&
      other.url == url &&
      other.language == language;

  @override
  int get hashCode => Object.hash(url, language);

  @override
  String toString() => 'SubtitleTrackRef($language, $label)';
}

/// Découvre les pistes de sous-titres annoncées par un panel Xtream.
///
/// ## Pourquoi un service à part
///
/// `SubtitleController.availableTracks` ne liste que les pistes **déjà
/// chargées en mémoire**. Rien n'interrogeait le panel : l'onglet sous-titres
/// était donc vide (« aucune piste disponible ») sur la quasi-totalité des
/// films, alors que le panel en publie. Ce service comble ce trou.
///
/// ## Tolérance aux formats
///
/// Aucun standard n'impose le format de retour, et les panels divergent :
///
/// ```json
/// { "info": { "subtitles": [ {"url": "...", "name": "Français"} ] } }   // A
/// { "info": { "subtitles": [ ["fre", "Français", "http://..."] ] } }     // B
/// { "info": { "subtitle":    [ {"file_name": "...", "url": "..."} ] } }  // C
/// { "epg_channel_id": ..., "info": { "subtitles": "http://...srt" } }    // D
/// ```
///
/// Le parseur accepte ces variantes, ignore les entrées inexploitables et ne
/// lève jamais : une découverte ratée doit laisser l'interface simplement vide,
/// pas faire échouer l'ouverture de la fiche.
class SubtitleDiscovery {
  SubtitleDiscovery._();

  /// Clés sous lesquelles un panel peut placer la liste des sous-titres.
  static const List<String> _containerKeys = [
    'subtitles',
    'subtitle',
    'subs',
    'subtitles_list',
    'subtitle_tracks',
    'streams',
  ];

  /// Clés d'URL, par ordre de préférence.
  static const List<String> _urlKeys = [
    'url',
    'file',
    'file_name',
    'path',
    'src',
    'link'
  ];

  /// Clés de langue / libellé.
  static const List<String> _langKeys = [
    'language',
    'lang',
    'name',
    'label',
    'title'
  ];
  static const List<String> _labelKeys = [
    'name',
    'label',
    'title',
    'language',
    'lang'
  ];

  /// Extractions des pistes depuis la réponse `player_api.php`.
  ///
  /// [context] est optionnel mais fortement recommandé : sans lui, les
  /// formats les plus courants (liste de codes langue, chemins relatifs) ne
  /// contiennent aucune URL et sont donc ignorés.
  ///
  /// Retourne une liste vide si rien n'est exploitable — jamais d'exception.
  /// Codes langue Announces par le panel, cherchés dans TOUTE la réponse.
  ///
  /// /// Pourquoi une recherche large
  ///
  /// Un panel peut placer ses sous-titres à la racine, dans `info`, ou — pour
  /// une série — **dans chaque objet épisode**. Le champ n'a pas d'emplacement
  /// normalisé : sur le panel testé, `get_series_info` n'en exposait aucun à la
  /// racine, et les pistes étaient.portées par les épisodes.
  ///
  /// On ne récupère que les CODES, jamais les URL : pour une série, l'URL
  /// d'une piste se construit avec le stream id de l'épisode PLAYED, pas avec
  /// celui de l'épisode porteur de la déclaration. La synthèse se fait donc
  /// dans [ApiService.discoverSubtitles], qui connaît l'épisode courant.
  static Set<String> collectLanguageCodes(Object? data) {
    final codes = <String>{};
    var depth = 0;
    void walk(Object? node) {
      if (depth > 6) return;
      depth++;
      if (node is Map) {
        for (final entry in node.entries) {
          final key = entry.key.toString().toLowerCase();
          if (_containerKeys.contains(key)) {
            _addCodes(entry.value, codes);
          } else {
            walk(entry.value);
          }
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(data);
    return codes;
  }

  /// Extrait des codes langue d'un champ heterogene : liste de chaînes, liste
  /// d'objets, chaîne seule.
  static void _addCodes(Object? node, Set<String> out) {
    if (node is String) {
      final code = node.trim();
      // On écarte ce qui ressemble à une URL : c'est une piste déjà adressable,
      // pas un code langue.
      if (code.isNotEmpty && !code.contains('/') && code.length <= 12) {
        out.add(code.toLowerCase());
      }
      return;
    }
    if (node is List) {
      for (final item in node) {
        _addCodes(item, out);
      }
      return;
    }
    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      for (final key in const ['lang', 'language', 'code', 'name', 'label']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          out.add(value.trim().toLowerCase());
          return;
        }
      }
    }
  }

  /// Construit une piste par convention d'URL, pour les panels qui ne
  /// déclarent rien.
  ///
  /// L'URL ne peut pas être devinée : `/subtitles/{user}/{pass}/{id}_{lang}.srt`
  /// est la convention Xtream, mais rien ne garantit qu'elle s'applique. La
  /// piste est donc marquée comme CONVENTIONNELLE, et l'interface ne présente
  /// jamais cela comme une certitude.
  static List<SubtitleTrackRef> synthesizeFromConvention({
    required SubtitleDiscoveryContext context,
    required Iterable<String> languages,
  }) {
    if (context.streamId == null || context.streamId!.isEmpty) {
      return const <SubtitleTrackRef>[];
    }
    final out = <SubtitleTrackRef>[];
    final seen = <String>{};
    for (final lang in languages) {
      final code = lang.trim().toLowerCase();
      if (code.isEmpty || !seen.add(code)) continue;
      final url = context.urlForLanguage(code);
      if (url == null) continue;
      out.add(
        SubtitleTrackRef(
          url: url,
          language: code,
          label: _labelFromLanguage(code),
        ),
      );
    }
    return out;
  }

  /// Langues candidates lorsqu'un panel ne déclare RIEN.
  ///
  /// /// Pourquoi deviner, et pourquoi peu
  ///
  /// Certains panels ne publient aucune déclaration de sous-titre — mesuré sur
  /// un panel réel : `get_series_info` ne contient ni champ ni code langue, sur
  /// aucune profondeur — tout en servant bien les fichiers. Leur interface
  /// construit alors l'URL par convention, avec une liste de langues qu'elle
  /// connaît par ailleurs. Sans candidate, l'app ne peut rien proposer, alors
  /// que la piste existe.
  ///
  /// On reste donc restreint : la langue de l'appareil, l'anglais et le
  /// français, sous forme courte (2 lettres) ET longue (3 lettres), car les
  /// fichiers de panel suivent les deux (`12345_fr.srt` comme `12345_fre.srt`).
  /// Une piste devinée qui n'existe pas se signale d'elle-même à l'activation,
  /// et l'interface affiche l'erreur par piste.
  static List<String> defaultConventionLanguages({
    String? deviceLanguageCode,
  }) {
    final base = <String>{
      (deviceLanguageCode ?? '').trim().toLowerCase(),
      'fr',
      'en',
    }..removeWhere((e) => e.isEmpty);
    final out = <String>[];
    const longForms = {
      'fr': 'fre',
      'en': 'eng',
      'de': 'ger',
      'es': 'spa',
      'it': 'ita',
      'nl': 'dut',
      'pt': 'por',
    };
    for (final code in base) {
      out.add(code);
      final long = longForms[code];
      if (long != null) out.add(long);
    }
    return out;
  }

  static List<SubtitleTrackRef> parse(
    Object? response, {
    SubtitleDiscoveryContext? context,
  }) {
    final out = <SubtitleTrackRef>[];
    final seen = <String>{};

    void add(SubtitleTrackRef t) {
      // Déduplication par URL : certains panels listent la même piste deux fois
      // (une entrée « auto » + une entrée nommée).
      if (seen.add(t.url)) out.add(t);
    }

    // La réponse peut être la map racine, ou déjà le bloc `info`.
    final roots = <Map<String, dynamic>>[];
    void collectMap(Object? node, {int depth = 0}) {
      if (depth > 4 || node is! Map) return;
      final map = Map<String, dynamic>.from(node);
      roots.add(map);
      final info = map['info'];
      if (info != null && info is Map) {
        collectMap(info, depth: depth + 1);
      }
    }

    collectMap(response);

    for (final root in roots) {
      for (final key in _containerKeys) {
        final node = root[key];
        if (node == null) continue;

        // Variante D : une simple chaîne d'URL.
        if (node is String) {
          if (_looksLikeSubtitleUrl(node)) {
            add(SubtitleTrackRef(
              url: node,
              language: _langFromUrl(node),
              label: _labelFromLanguage(_langFromUrl(node)),
            ));
          }
          continue;
        }

        if (node is! List) continue;

        for (final entry in node) {
          // FORMAT LE PLUS RÉPANDU : une simple liste de codes langue
          // (`["fre","eng"]`) ou de noms (`"French"`). Aucune URL : sans
          // [context] il n'y a rien à télécharger, donc la piste est ignorée —
          // c'est ce qui faisait afficher « aucune piste disponible » sur la
          // plupart des films.
          if (entry is String) {
            final raw = entry.trim();
            if (raw.isEmpty) continue;
            final lang = _looksLikeSubtitleUrl(raw) ? _langFromUrl(raw) : raw;
            var url =
                _looksLikeSubtitleUrl(raw) ? raw : context?.urlForLanguage(raw);
            // Un chemin relatif (`1234_fr.srt`) se résout sur le panel.
            if (url == null && context != null) {
              final resolved = context.resolvePath(raw);
              if (resolved != null && _looksLikeSubtitleUrl(resolved)) {
                url = resolved;
              }
            }
            if (url == null) continue;
            add(SubtitleTrackRef(
              url: url,
              language: _normaliseLang(lang),
              label: _labelFromLanguage(lang),
            ));
            continue;
          }

          // Variante B : liste positionnelle [lang, label, url].
          if (entry is List) {
            if (entry.length >= 3) {
              final url = entry[2].toString().trim();
              final lang = entry[0].toString().trim();
              final label = entry[1].toString().trim();
              if (_looksLikeSubtitleUrl(url)) {
                add(SubtitleTrackRef(
                  url: url,
                  language: lang.isEmpty ? _langFromUrl(url) : lang,
                  label: label.isEmpty ? _labelFromLanguage(lang) : label,
                ));
              }
            }
            continue;
          }

          if (entry is! Map) continue;

          final map = Map<String, dynamic>.from(entry);

          // Variante C : le nom de fichier porte l'URL, le champ `url` non.
          String? url;
          for (final k in _urlKeys) {
            final v = map[k]?.toString().trim();
            if (v == null || v.isEmpty) continue;
            if (_looksLikeSubtitleUrl(v)) {
              url = v;
              break;
            }
            // Chemin relatif (`1234_fr.srt`) : résolu sur le panel.
            final resolved = context?.resolvePath(v);
            if (resolved != null && _looksLikeSubtitleUrl(resolved)) {
              url = resolved;
              break;
            }
          }
          if (url == null) continue;

          var lang = '';
          for (final k in _langKeys) {
            final v = map[k]?.toString().trim();
            if (v != null && v.isNotEmpty && !_looksLikeSubtitleUrl(v)) {
              lang = v;
              break;
            }
          }
          if (lang.isEmpty) lang = _langFromUrl(url);

          var label = '';
          for (final k in _labelKeys) {
            final v = map[k]?.toString().trim();
            if (v != null && v.isNotEmpty) {
              label = v;
              break;
            }
          }
          // Un libellé qui n'est que le code langue (« fre ») n'est pas un
          // libellé : la chaîne de fallback atteint `language` quand le panel
          // ne fournit ni `name` ni `label`, et l'utilisateur lisait « fre »
          // dans la liste. On le traduit alors.
          if (label.isEmpty || _normaliseLang(label) == lang) {
            label = _labelFromLanguage(lang);
          }

          add(SubtitleTrackRef(url: url, language: lang, label: label));
        }
      }
    }

    return out;
  }

  /// Une entrée n'est retenue que si son URL ressemble bien à un sous-titre.
  ///
  /// Sans ce filtre, un panel qui liste ses propres flux dans le même champ
  /// (`streams`) ferait apparaître des pistes « sous-titres » illisibles.
  static bool _looksLikeSubtitleUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    final lower = url.toLowerCase();
    const exts = ['.srt', '.vtt', '.ass', '.ssa', '.sub', '.smi', '.txt'];
    if (exts.any(lower.contains)) return true;
    // Certains panels servent des sous-titres via une route sans extension
    // (`/subtitles/123/fr`). On retient alors si le chemin mentionne le
    // concept, mais on rejette les URLs de flux.
    if (lower.contains('/sub') || lower.contains('subtitle')) return true;
    if (lower.contains('live/') ||
        lower.contains('/movie/') ||
        lower.contains('/series/')) {
      return lower.contains('sub');
    }
    return false;
  }

  /// Devine la langue depuis l'URL (`.../fre.srt` -> `fre`).
  ///
  /// On travaille sur le NOM DE FICHIER et on retient son DERNIER segment :
  /// la regex précédente (`([a-z]{2,3})` collée à l'extension) capturait n'importe
  /// quelles lettres et renvoyait « nly » pour `.../only_fr.srt` — donc un
  /// libellé faux, affiché tel quel à l'utilisateur.
  static String _langFromUrl(String url) {
    var path = url.split('?').first;
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash >= 0) path = path.substring(lastSlash + 1);
    final dot = path.lastIndexOf('.');
    if (dot <= 0) return 'und';
    final stem = path.substring(0, dot);
    // `1234_fr`, `movie.en`, `sous-titre` : le code est le dernier segment.
    final parts = stem.split(RegExp(r'[._\-\s]')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'und';
    final candidate = parts.last.toLowerCase();
    // Un segment n'est un code langue que s'il ressemble à un code court
    // (2-3 lettres, éventuellement suivi d'une région). `film` ou `version`
    // ne le sont pas.
    if (RegExp(r'^[a-z]{2,3}(-[a-z]{2})?$').hasMatch(candidate)) {
      return candidate;
    }
    return 'und';
  }

  /// Normalise un code langue paniqué par un panel (`FRE`, `fre-FR`, `French`).
  static String _normaliseLang(String lang) {
    final v = lang.trim();
    if (v.isEmpty) return 'und';
    return v.toLowerCase();
  }

  /// Libellé lisible à partir d'un code langue.
  /// Traduit un code langue en nom affichable.
  ///
  /// La table vit dans [LanguageLabel], partagée avec les pistes audio : la
  /// garder ici aurait produit deux listes divergentes, dont une seule audible
  /// par l'utilisateur.
  static String _labelFromLanguage(String lang) => LanguageLabel.of(lang);
}
