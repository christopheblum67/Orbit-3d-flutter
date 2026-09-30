// Récupère le texte français original depuis le mojibake mono/double-couche
// présent dans les fichiers Dart (corruption UTF-8 <-> CP1252 appliquée 1 ou
// 2 fois). Traitement ligne par ligne, fail-safe : aucune écriture si une
// ligne demeure non résolue (--fix écrit seulement si tout est résolu).
//
// Usage : dart run tool/recover_mojibake.dart [--fix] [fichier...]
import 'dart:convert';
import 'dart:io';

const _cp1252High = <int, String>{
  0x80: '\u20AC', 0x81: '\u0081', 0x82: '\u201A', 0x83: '\u0192',
  0x84: '\u201E', 0x85: '\u2026', 0x86: '\u2020', 0x87: '\u2021',
  0x88: '\u02C6', 0x89: '\u2030', 0x8A: '\u0160', 0x8B: '\u2039',
  0x8C: '\u0152', 0x8D: '\u008D', 0x8E: '\u017D', 0x8F: '\u008F',
  0x90: '\u0090', 0x91: '\u2018', 0x92: '\u2019', 0x93: '\u201C',
  0x94: '\u201D', 0x95: '\u2022', 0x96: '\u2013', 0x97: '\u2014',
  0x98: '\u02DC', 0x99: '\u2122', 0x9A: '\u0161', 0x9B: '\u203A',
  0x9C: '\u0153', 0x9D: '\u009D', 0x9E: '\u017E', 0x9F: '\u0178',
};
final _reverse = <String, int>{
  for (final e in _cp1252High.entries) e.value: e.key,
};

List<int>? encodeCp1252(String s) {
  final out = <int>[];
  for (final c in s.codeUnits) {
    final ch = String.fromCharCode(c);
    if (c < 0x80 || (c >= 0xA0 && c <= 0xFF)) {
      out.add(c);
    } else if (_reverse.containsKey(ch)) {
      out.add(_reverse[ch]!);
    } else {
      return null;
    }
  }
  return out;
}

/// Paires mojibake mono-couche typiques (remplacement sûr, n'existent pas
/// dans du français correct).
const pairTable = <String, String>{
  'â€™': '’', 'â€œ': '“', 'â€¦': '…', 'â€˜': '‘', 'â€“': '–',
  'â€”': '—', 'Â©': '©', 'Â®': '®', 'Â«': '«', 'Â»': '»',
  'Ã ': 'à', 'Ã¡': 'á', 'Ã©': 'é', 'Ã¨': 'è', 'Ã§': 'ç',
  'Ã¢': 'â', 'Ãª': 'ê', 'Ã®': 'î', 'Ã´': 'ô', 'Ã¹': 'ù',
  'Ã»': 'û', 'Ã«': 'ë', 'Ã¯': 'ï', 'Ã¼': 'ü', 'Ã¤': 'ä',
  'Ã¶': 'ö', 'Ã±': 'ñ', 'Ãº': 'ú', 'Ã³': 'ó',
  'Ã‰': 'É', 'Ãˆ': 'È', 'ÃŠ': 'Ê', 'Ã‹': 'Ë', 'ÃŽ': 'Î',
  'Ã†': 'Æ', 'Ã‡': 'Ç', 'Ã“': 'Ó', 'Ã”': 'Ô', 'Ã–': 'Ö',
  'Ã˜': 'Ø', 'Ã™': 'Ù', 'Ã›': 'Û', 'Ãœ': 'Ü',
  'Å“': 'œ', 'Å’': 'Œ', 'Â ': '\u00A0', 'Â·': '·',
};
final _pairs = pairTable.keys.toList()..sort((a, b) => b.length - a.length);

final _marker =
    RegExp(r'[\u00C2\u00C3\u00C5][\u0080-\u00BF]|\u00E2[\u0080\u0086\u0092][\u0090-\u009F]');

int _markers(String s) => _marker.allMatches(s).length;

String _applyPairs(String s) {
  for (final k in _pairs) {
    s = s.replaceAll(k, pairTable[k]!);
  }
  return s;
}

/// Retourne la version récupérée d'une ligne (ou null si non résolue).
String? recover(String line) {
  var cur = line;
  // 1) allers-retours CP1252<->UTF-8 tant que c'est possible.
  for (var i = 0; i < 4; i++) {
    final enc = encodeCp1252(cur);
    if (enc == null) break;
    String dec;
    try {
      dec = utf8.decode(enc);
    } catch (_) {
      break;
    }
    if (dec == cur) break;
    cur = dec;
  }
  // 2) table de paires mono-couche sur le résidu (lignes mixtes).
  if (_markers(cur) > 0) {
    final pair = _applyPairs(cur);
    if (_markers(pair) == 0) cur = pair;
  }
  if (_markers(cur) > 0 || cur.contains('\uFFFD')) return null;
  return cur;
}

void main(List<String> args) {
  final fix = args.contains('--fix');
  final requested = args.where((a) => !a.startsWith('-')).toList();
  final roots = requested.isNotEmpty
      ? requested
      : [
          'lib/services/api_service.dart',
          'lib/features/profile/profile_edit_screen.dart',
          'lib/providers/watched_episodes_provider.dart',
          'test/unit/api_service_test.dart',
        ];

  var anyFail = false;
  for (final path in roots) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final text = utf8.decode(f.readAsBytesSync(), allowMalformed: true);
    final lines = text.split('\n');
    final out = <String>[];
    var changed = 0;
    final unresolved = <int, String>{};
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_markers(line) == 0 && !line.contains('\uFFFD')) {
        out.add(line);
        continue;
      }
      final rec = recover(line);
      if (rec == null) {
        unresolved[i + 1] = line;
        out.add(line);
        continue;
      }
      if (rec != line) changed++;
      out.add(rec);
    }
    final joined = out.join('\n');
    stdout.writeln('$path : lignes modifiées=$changed '
        'résidus=${unresolved.length}');
    unresolved.forEach((n, l) {
      stdout.writeln('   L$n : $l');
    });
    if (unresolved.isEmpty) {
      anyFail = false;
    }
    if (fix && unresolved.isEmpty && joined != text) {
      f.writeAsBytesSync(utf8.encode(joined));
      stdout.writeln('   -> écrit.');
    }
  }
  if (!fix) stdout.writeln('(rapport seul — relancer avec --fix)');
  if (anyFail) exitCode = 1;
}