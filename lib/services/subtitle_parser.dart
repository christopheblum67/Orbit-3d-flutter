import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  bool isActiveAt(int positionMs) => positionMs >= startMs && positionMs < endMs;

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
  static Future<SubtitleTrack> parseFromUrl(
    String url, {
    String language = 'und',
    String? label,
  }) async {
    final response = await _fetchWithTimeout(url);
    return parse(response, language: language, label: label);
  }

  static Future<String> _fetchWithTimeout(String url) async {
    // Utilisation directe de HttpClient pour éviter d'ajouter dio comme dépendance dure ici.
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      final response = await request.close().timeout(const Duration(seconds: 10));
      final content = await response.transform(utf8.decoder).join();
      return content;
    } finally {
      client.close();
    }
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
      final textLines = lines.skip(2).where((l) => l.trim().isNotEmpty).join('\n');
      final times = _parseSrtTimecode(timecode);
      if (times != null && textLines.isNotEmpty) {
        cues.add(SubtitleCue(
          startMs: times[0],
          endMs: times[1],
          text: _cleanText(textLines),
        ));
      }
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return SubtitleTrack(language: language, label: label ?? language, cues: cues);
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
    while (i < lines.length && !lines[i].contains('-->')) i++;
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
          cues.add(SubtitleCue(
            startMs: times[0],
            endMs: times[1],
            text: text,
          ));
        }
      }
      i++;
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return SubtitleTrack(language: language, label: label ?? language, cues: cues);
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