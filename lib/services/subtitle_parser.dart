import 'dart:async';

/// Erreur levée quand une URL de sous-titre répond sans contenu exploitable.
///
/// Distincte d'une erreur réseau : le réseau a marché, c'est le panel
/// qui n'a pas servi de sous-titre.
import 'dart:convert';
import 'dart:io';
// BytesBuilder est exporte par dart:io, mais son usage indirect est
// depreciee : l'import explicite evite l'avertissement.
import 'dart:typed_data' show BytesBuilder;

/// Erreur levée quand une URL de sous-titre répond sans contenu exploitable.
///
/// Distincte d'une erreur réseau : le réseau a marché, c'est le panel qui
/// n'a pas servi de sous-titre.
class SubtitlePayloadException implements Exception {
  final String message;
  const SubtitlePayloadException(this.message);

  @override
  String toString() => 'SubtitlePayloadException: $message';
}

/// Modèle d'une ligne de sous-titre (cue).
class SubtitleCue {
  final int startMs;
  final int endMs;
  final String text;

  const SubtitleCue({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  bool isActiveAt(int positionMs) =>
      positionMs >= startMs && positionMs < endMs;

  @override
  String toString() => 'SubtitleCue($startMs-$endMs: "$text")';
}

/// Résultat du parsing d'un fichier de sous-titres.
class SubtitleTrack {
  final String language;
  final String label;
  final List<SubtitleCue> cues;

  const SubtitleTrack({
    required this.language,
    required this.label,
    required this.cues,
  });

  /// Retourne le cue actif à la position donnée, ou null.
  SubtitleCue? activeCueAt(int positionMs) {
    // Les cues sont triés par startMs → recherche binaire possible.
    for (final cue in cues) {
      if (cue.isActiveAt(positionMs)) return cue;
      if (cue.startMs > positionMs) break;
    }
    return null;
  }
}

/// Parser pour formats SRT et VTT (WebVTT).
class SubtitleParser {
  /// Charge une piste et la valide avant de la renvoyer.
  ///
  /// Un panel répond volontiers `200 OK` avec une page HTML d'erreur ou un
  /// corps vide à une URL de sous-titre inexistante. Une telle piste s'affichait
  /// dans la liste, se chargeait sans erreur, et n'affichait jamais rien à
  /// l'écran — impossible à distinguer d'un bug de rendu. On préfère donc
  /// refuser explicitement un contenu qui n'est pas un sous-titre.
  static Future<SubtitleTrack> parseFromUrl(
    String url, {
    String language = 'und',
    String? label,
  }) async {
    final response = await _fetchWithTimeout(url);
    final track = parse(response, language: language, label: label);
    if (!isUsable(response, track)) {
      throw SubtitlePayloadException(
        'Contenu non exploitable pour « ${label ?? language} » '
        '(${track.cues.length} cue(s))',
      );
    }
    return track;
  }

  /// Un contenu est exploitable s'il ressemble à un sous-titre et contient au
  /// moins un cue.
  ///
  /// On refuse le HTML même s'il contient des chiffres : une balise `<html>`
  /// servie par le panel en guise de sous-titre est le cas le plus fréquent,
  /// et elle produit une piste muette.
  static bool isUsable(String content, SubtitleTrack track) {
    if (track.cues.isEmpty) return false;
    final trimmed = content.trimLeft().toLowerCase();
    if (trimmed.startsWith('<!doctype html') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<?xml') ||
        trimmed.startsWith('<error')) {
      return false;
    }
    return true;
  }

  static Future<String> _fetchWithTimeout(String url) async {
    // Utilisation directe de HttpClient pour éviter d'ajouter dio comme dépendance dure ici.
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      // Certains panels refusent les requêtes sans User-Agent (403), et les
      // sous-titres sont justement un appel « annexe » que ces panels
      // contrôlent davantage que le flux vidéo.
      request.headers.set(HttpHeaders.userAgentHeader, 'OrbitIPTV/1.0');
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return _decodeSubtitleBytes(builder.takeBytes());
    } finally {
      client.close();
    }
  }

  /// Décode un fichier de sous-titres en tolérant les deux encodages
  /// réellement rencontrés sur les panels Xtream.
  ///
  /// `utf8.decoder` **strict** levait une `FormatException` sur un fichier
  /// Latin-1 (très fréquent en français) : le chargement échouait et plus
  /// aucun sous-titre n'était proposé. On décode donc en UTF-8 permissif et,
  /// si le contenu contenait des octets invalides, on repasse en Latin-1.
  static String _decodeSubtitleBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';
    var isValidUtf8 = true;
    final relaxed = utf8.decode(bytes, allowMalformed: true);
    // `allowMalformed` remplace les séquences invalides par U+FFFD : on peut
    // donc détecter un fichier Latin-1 et le rejouer en CP1252.
    for (final rune in relaxed.runes) {
      if (rune == 0xFFFD) {
        isValidUtf8 = false;
        break;
      }
    }
    if (isValidUtf8) return relaxed;
    return latin1.decode(bytes, allowInvalid: true);
  }

  static SubtitleTrack parse(
    String content, {
    String language = 'und',
    String? label,
  }) {
    final trimmed = content.trim();
    if (trimmed.startsWith('WEBVTT')) {
      return _parseVtt(content, language: language, label: label);
    }
    return _parseSrt(content, language: language, label: label);
  }

  static SubtitleTrack _parseSrt(
    String content, {
    required String language,
    String? label,
  }) {
    final cues = <SubtitleCue>[];
    // SRT : blocs séparés par ligne vide, chaque bloc = index + timecode + texte (multi-lignes)
    final blocks = content.split(RegExp(r'\r?\n\r?\n'));
    for (final block in blocks) {
      final lines = block.trim().split(RegExp(r'\r?\n'));
      if (lines.length < 2) continue;
      // lines[0] = index (ignoré), lines[1] = timecode, lines[2+] = texte
      final timecode = lines[1].trim();
      final textLines =
          lines.skip(2).where((l) => l.trim().isNotEmpty).join('\n');
      final times = _parseSrtTimecode(timecode);
      if (times != null && textLines.isNotEmpty) {
        cues.add(
          SubtitleCue(
            startMs: times[0],
            endMs: times[1],
            text: _cleanText(textLines),
          ),
        );
      }
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return SubtitleTrack(
      language: language,
      label: label ?? language,
      cues: cues,
    );
  }

  static SubtitleTrack _parseVtt(
    String content, {
    required String language,
    String? label,
  }) {
    final cues = <SubtitleCue>[];
    final lines = content.split(RegExp(r'\r?\n'));
    var i = 0;
    // Skip header until first cue
    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }
      if (line.contains('-->')) {
        final timecode = line;
        i++;
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }
        final text = _cleanText(textLines.join('\n'));
        final times = _parseVttTimecode(timecode);
        if (times != null && text.isNotEmpty) {
          cues.add(
            SubtitleCue(
              startMs: times[0],
              endMs: times[1],
              text: text,
            ),
          );
        }
      }
      i++;
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return SubtitleTrack(
      language: language,
      label: label ?? language,
      cues: cues,
    );
  }

  static List<int>? _parseSrtTimecode(String timecode) {
    // Format: HH:MM:SS,mmm --> HH:MM:SS,mmm
    final parts = timecode.split(RegExp(r'\s*-->\s*'));
    if (parts.length != 2) return null;
    final start = _parseSrtTime(parts[0].trim());
    final end = _parseSrtTime(parts[1].trim());
    if (start == null || end == null) return null;
    return [start, end];
  }

  static int? _parseSrtTime(String time) {
    // HH:MM:SS,mmm
    final parts = time.split(':');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final secParts = parts[2].split(',');
    if (secParts.length != 2) return null;
    final s = int.tryParse(secParts[0]);
    final ms = int.tryParse(secParts[1]);
    if (h == null || m == null || s == null || ms == null) return null;
    return ((h * 3600 + m * 60 + s) * 1000) + ms;
  }

  static List<int>? _parseVttTimecode(String timecode) {
    // Format: HH:MM:SS.mmm --> HH:MM:SS.mmm (ou sans heures)
    final parts = timecode.split(RegExp(r'\s*-->\s*'));
    if (parts.length != 2) return null;
    final start = _parseVttTime(parts[0].trim());
    final end = _parseVttTime(parts[1].trim());
    if (start == null || end == null) return null;
    return [start, end];
  }

  static int? _parseVttTime(String time) {
    // HH:MM:SS.mmm ou MM:SS.mmm
    final parts = time.split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    int h = 0, m = 0;
    int idx = 0;
    if (parts.length == 3) {
      h = int.tryParse(parts[0]) ?? 0;
      m = int.tryParse(parts[1]) ?? 0;
      idx = 2;
    } else {
      m = int.tryParse(parts[0]) ?? 0;
      idx = 1;
    }
    final secParts = parts[idx].split('.');
    if (secParts.length != 2) return null;
    final s = int.tryParse(secParts[0]);
    final ms = int.tryParse(secParts[1].padRight(3, '0').substring(0, 3));
    if (s == null || ms == null) return null;
    return ((h * 3600 + m * 60 + s) * 1000) + ms;
  }

  static String _cleanText(String text) {
    // Supprime balises VTT basiques (<c>, <i>, <b>, <u>, <ruby>, etc.)
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .trim();
  }
}
