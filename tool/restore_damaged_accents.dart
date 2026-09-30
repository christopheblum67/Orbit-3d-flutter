// Répare les caractères accentués perdus (U+FFFD) en réinjectant la ligne
// correspondante de la version HEAD du fichier.
//
// Contexte : une passe de réparation « mojibake » a été appliquée à des
// fichiers qui n'en avaient pas besoin (parce qu'ils contenaient un « Âge »
// français légitime). Sur ces fichiers, chaque caractère Latin-1 a été
// ré-interprété en UTF-8 et est devenu U+FFFD — définitivement illisible.
//
// La version HEAD du même fichier est intacte : on s'en sert comme référence.
// Une ligne de travailAbîmée est remplacée par la ligne HEAD qui se
// normalise pareil (ASCII insensible aux accents et à la ponctuation).
//
// Lignes nouvelles de la session ET accentuées ne sont pas récupérables
// automatiquement : elles sont signalées.
import 'dart:convert';
import 'dart:io';

const _replacement = '�';

/// Clé de comparaison : minuscules, lettres/chiffres ASCII uniquement.
/// « Créer un profil » et « Cr��er un profil » donnent la même clé.
String _key(String line) {
  final buf = StringBuffer();
  for (final c in line.toLowerCase().codeUnits) {
    final isAlnumAscii =
        (c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39);
    if (isAlnumAscii) buf.writeCharCode(c);
  }
  return buf.toString();
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final files = args.where((a) => a != '--dry-run').toList();

  for (final path in files) {
    final head = _gitShow(path);
    if (head == null) {
      stderr.writeln('pas de référence HEAD pour $path');
      continue;
    }

    final work = utf8.decode(File(path).readAsBytesSync(), allowMalformed: true);
    final workLines = work.split('\n');
    final headLines = head.split('\n');

    // Index des lignes HEAD saines par clé. En cas de collision, la première
    // occurrence gagne : on privilégie l'ordre du fichier d'origine.
    final byKey = <String, String>{};
    for (final line in headLines) {
      if (line.contains(_replacement)) continue;
      final k = _key(line);
      if (k.isEmpty) continue;
      byKey.putIfAbsent(k, () => line);
    }

    var fixed = 0;
    final unresolved = <String>[];
    for (var i = 0; i < workLines.length; i++) {
      final line = workLines[i];
      if (!line.contains(_replacement)) continue;
      final replacement = byKey[_key(line)];
      if (replacement == null) {
        unresolved.add(line.trim());
        continue;
      }
      workLines[i] = replacement;
      fixed++;
    }

    if (fixed > 0 && !dryRun) {
      File(path).writeAsBytesSync(utf8.encode(workLines.join('\n')));
    }
    stdout.writeln('${dryRun ? "[secours] " : ""}$path : $fixed ligne(s) '
        'restaurée(s), ${unresolved.length} non résolue(s)');
    for (final line in unresolved) {
      stdout.writeln('    ? $line');
    }
  }
}

String? _gitShow(String path) {
  final result = Process.runSync('git', ['show', 'HEAD:$path']);
  if (result.exitCode != 0) return null;
  return result.stdout as String;
}
