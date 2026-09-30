// Sonde : détermine le niveau de mojibake de chaque fichier (simple/double)
// et si une récupération par allers-retours CP1252<->UTF-8 aboutit.
// Usage : dart run tool/probe_mojibake.dart [chemin...]
import 'dart:convert';
import 'dart:io';

// Table CP1252 pour les octets 0x80-0x9F (les autres sont identiques à Latin-1).
const _cp1252High = <int, String>{
  0x80: '\u20AC', // €
  0x81: '\u0081',
  0x82: '\u201A', // ‚
  0x83: '\u0192', // ƒ
  0x84: '\u201E', // „
  0x85: '\u2026', // …
  0x86: '\u2020', // †
  0x87: '\u2021', // ‡
  0x88: '\u02C6', // ˆ
  0x89: '\u2030', // ‰
  0x8A: '\u0160', // Š
  0x8B: '\u2039', // ‹
  0x8C: '\u0152', // Œ
  0x8D: '\u008D',
  0x8E: '\u017D', // Ž
  0x8F: '\u008F',
  0x90: '\u0090',
  0x91: '\u2018', // ‘
  0x92: '\u2019', // ’
  0x93: '\u201C', // “
  0x94: '\u201D', // ”
  0x95: '\u2022', // •
  0x96: '\u2013', // –
  0x97: '\u2014', // —
  0x98: '\u02DC', // ˜
  0x99: '\u2122', // ™
  0x9A: '\u0161', // š
  0x9B: '\u203A', // ›
  0x9C: '\u0153', // œ
  0x9D: '\u009D',
  0x9E: '\u017E', // ž
  0x9F: '\u0178', // Ÿ
};

String decodeCp1252(List<int> bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    if (b < 0x80 || b > 0x9F) {
      sb.write(String.fromCharCode(b));
    } else {
      sb.write(_cp1252High[b]!);
    }
  }
  return sb.toString();
}

final _reverse = <String, int>{
  for (final e in _cp1252High.entries) e.value: e.key,
};

List<int> encodeCp1252(String s) {
  final out = <int>[];
  for (final c in s.codeUnits) {
    final ch = String.fromCharCode(c);
    if (c < 0x80 || (c >= 0xA0 && c <= 0xFF)) {
      out.add(c);
    } else if (_reverse.containsKey(ch)) {
      out.add(_reverse[ch]!);
    } else {
      return <int>[];
    }
  }
  return out;
}

void main(List<String> args) {
  final targets = args.isNotEmpty
      ? args
      : [
          'lib/services/api_service.dart',
          'lib/features/profile/profile_edit_screen.dart',
          'lib/providers/watched_episodes_provider.dart',
          'test/unit/api_service_test.dart',
        ];
  const marker = 'Ã|Â|â€|â†|â„|Å|â€œ|â€';
  for (final p in targets) {
    final text = utf8.decode(File(p).readAsBytesSync(), allowMalformed: true);
    var cur = text;
    var steps = 0;
    String? err;
    try {
      for (var i = 0; i < 4; i++) {
        final enc = encodeCp1252(cur);
        if (enc.isEmpty) {
          err = 'non-encodable cp1252';
          break;
        }
        final dec = utf8.decode(enc); // strict
        if (dec == cur) break;
        cur = dec;
        steps++;
      }
    } catch (e) {
      err = '${e.runtimeType}';
    }
    final markers = RegExp(marker).allMatches(cur).length;
    final fffd = cur.contains('\uFFFD') ? ' FFFD!' : '';
    stdout.writeln('$p : roundtrip=$steps err=$err marqueurs=$markers$fffd');
    if (steps > 0 && err == null) {
      // échantillon du résultat
      final idx = cur.indexOf('État');
      final sample = idx >= 0
          ? cur.substring(idx, (idx + 60).clamp(0, cur.length))
          : cur.substring(0, 80).replaceAll('\n', ' ');
      stdout.writeln('   échantillon: $sample');
    }
  }
}