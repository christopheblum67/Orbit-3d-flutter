// Remplace des lignes par numéro, en UTF-8 sans BOM.
//
// Sert à réparer les lignes dont les accents ont été perdus (U+FFFD) : ces
// lignes sont impossibles à cibler avec une recherche textuelle, puisque le
// caractère de remplacement ne correspond à aucun texte known.
//
// Usage : dart run tool/set_lines.dart <fichier> <ligne> <texte> [<ligne> <texte> ...]
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('usage: dart run tool/set_lines.dart <file> <line> <text> ...'
        ' (reçu ${args.length} argument(s))');
    exitCode = 64;
    return;
  }

  final path = args.first;
  final file = File(path);
  final lines = utf8
      .decode(file.readAsBytesSync(), allowMalformed: true)
      .split('\n');

  for (var i = 1; i < args.length; i += 2) {
    final lineNumber = int.parse(args[i]);
    final text = args[i + 1];
    if (lineNumber < 1 || lineNumber > lines.length) {
      stderr.writeln('ligne $lineNumber hors bornes (1..${lines.length})');
      exitCode = 65;
      return;
    }
    final before = lines[lineNumber - 1];
    // Préserve l'indentation d'origine : le texte fourni commence au texte
    // utile, sans espaces de bord.
    final indent = RegExp(r'^\s*').firstMatch(before)?.group(0) ?? '';
    lines[lineNumber - 1] = '$indent$text';
    stdout.writeln('$path:$lineNumber  « $text »');
  }

  file.writeAsBytesSync(utf8.encode(lines.join('\n')));
}
