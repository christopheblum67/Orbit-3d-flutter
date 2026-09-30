// Corrige le mojibake double-encodé (« Ã© » = é, « Ã¨ » = è, « Â« » = « ...)
// dans les fichiers Dart de lib/ et test/.
//
// Usage :
//   dart run tool/fix_mojibake_round.dart          -> rapport seul
//   dart run tool/fix_mojibake_round.dart --fix    -> applique la correction
//
// La correction par paires est sûre : une séquence mojibake ne peut pas
// exister dans du français correct, donc son remplacement par le caractère
// attendu ne peut pas casser un texte propre.
import 'dart:convert';
import 'dart:io';

const table = <String, String>{
  'â€™': '’',
  'â€œ': '“',
  'â€¦': '…',
  'â€˜': '‘',
  'â€“': '–',
  'â€”': '—',
  'â†“': '↓',
  'â†‘': '←',
  'â†”': '↑',
  'Å“': 'œ',
  'Â©': '©',
  'Â®': '®',
  'Â«': '«',
  'Â»': '»',
  'Ã ': 'à',
  'Ã¡': 'á',
  'Ã©': 'é',
  'Ã¨': 'è',
  'Ã§': 'ç',
  'Ã¢': 'â',
  'Ãª': 'ê',
  'Ã®': 'î',
  'Ã´': 'ô',
  'Ã¹': 'ù',
  'Ã»': 'û',
  'Ã«': 'ë',
  'Ã¯': 'ï',
  'Ã¼': 'ü',
  'Ã¤': 'ä',
  'Ã¶': 'ö',
  'Ã±': 'ñ',
  'Ãº': 'ú',
  'Ã³': 'ó',
  'Ã‰': 'É',
  'Ãˆ': 'È',
  'ÃŠ': 'Ê',
  'Ã‹': 'Ë',
  'ÃŽ': 'Î',
  'Ã†': 'Æ',
  'Ã‡': 'Ç',
  'Ã“': 'Ó',
  'Ã”': 'Ô',
  'Ã–': 'Ö',
  'Ã˜': 'Ø',
  'Ã™': 'Ù',
  'Ã›': 'Û',
  'Ãœ': 'Ü',
};

final _keys = table.keys.toList()..sort((a, b) => b.length - a.length);

final _marker = RegExp(r'[\u00C2\u00C3][\u0080-\u00BF]|\u00E2\u0080[\u0090-\u009F]|\u00C5[\u0090-\u009F]|\u00E2\u0086[\u0090-\u0094]|\u00E2\u0092\u0080');

String _read(String p) =>
    utf8.decode(File(p).readAsBytesSync(), allowMalformed: true);

Iterable<String> _targets() sync* {
  for (final root in ['lib', 'test']) {
    final d = Directory(root);
    if (!d.existsSync()) continue;
    for (final e in d.listSync(recursive: true)) {
      if (e is! File) continue;
      final p = e.path.replaceAll('/', r'\');
      if (!p.endsWith('.dart')) continue;
      if (p.contains(r'\generated\') || p.contains('.dart_tool')) continue;
      if (_marker.hasMatch(_read(e.path))) yield e.path;
    }
  }
}

int _markers(String s) => _marker.allMatches(s).length;

void main(List<String> args) {
  final fix = args.contains('--fix');
  final counts = <String, int>{};
  var total = 0;
  final residual = <String>{};

  for (final path in _targets()) {
    final text = _read(path);
    final n = _markers(text);
    if (n == 0) continue;
    counts[path] = n;
    total += n;

    if (fix) {
      var fixed = text;
      for (final k in _keys) {
        fixed = fixed.replaceAll(k, table[k]!);
      }
      final rest = _markers(fixed);
      // Arrondi UTF-8 complet si le fichier est devenu 100 % Latin-1.
      var pure = true;
      for (final c in fixed.codeUnits) {
        if (c > 0xFF) {
          pure = false;
          break;
        }
      }
      if (pure && rest == 0) {
        fixed = utf8.decode(latin1.encode(fixed), allowMalformed: true);
      }
      File(path).writeAsBytesSync(utf8.encode(fixed));
      if (rest > 0) residual.add('$path (rest=$rest)');
    }
  }

  final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted) {
    stdout.writeln('${e.value.toString().padLeft(4)}  ${e.key}');
  }
  stdout.writeln('-- fichiers: ${counts.length} · marqueurs: $total');
  if (residual.isNotEmpty) {
    stdout.writeln('-- résidus à inspecter --');
    residual.forEach(stdout.writeln);
  }
  if (fix) stdout.writeln('--fix appliqué');
}