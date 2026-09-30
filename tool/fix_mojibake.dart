// R�pare les fichiers Dart doublement encod�s en UTF-8 (mojibake).
//
// Sympt�me : le texte � cha�ne � a �t� stock� comme � chaîne �, c'est-�-dire
// que des octets UTF-8 ont �t� r�interpr�t�s en Latin-1 puis r�-encod�s en
// UTF-8. Chaque caract�re accentu� occupe alors deux octets (C3 83 pour � � �).
//
// La r�paration est l'op�ration inverse : on lit le texte, on le r�-encod� en
// Latin-1 (un octet par caract�re), puis on relit ces octets comme de l'UTF-8.
//
// Usage : dart run tool/fix_mojibake.dart [--dry-run] <fichiers...>
import 'dart:convert';
import 'dart:io';

bool _looksCorrupted(String text) =>
    text.contains('�') || text.contains('�') || text.contains('�€');

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final files = args.where((a) => a != '--dry-run').toList();
  if (files.isEmpty) {
    stderr.writeln('usage: dart run tool/fix_mojibake.dart [--dry-run] <files...>');
    exitCode = 64;
    return;
  }

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('ignor� (absent): $path');
      continue;
    }

    final original = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    if (!_looksCorrupted(original)) {
      stdout.writeln('ok (propre)   $path');
      continue;
    }

    // Reconstruction manuelle des octets : un caract�re <= 0xFF (donc
    // � � �, � � �) redevient l'octet Latin-1 d'origine, tandis qu'un caract�re
    // > 0xFF est d�j� un caract�re UTF-8 correct et est r�-encod� tel quel.
    //
    // `Latin1Codec.encode` est inutilisable ici : il l�ve sur ces caract�res
    // > 0xFF pr�sents dans les fichiers mixtes (accents d�j� corrects).
    final bytes = BytesBuilder(copy: false);
    for (final rune in original.runes) {
      if (rune <= 0xFF) {
        bytes.addByte(rune);
      } else {
        bytes.add(utf8.encode(String.fromCharCode(rune)));
      }
    }
    final repaired =
        utf8.decode(bytes.takeBytes(), allowMalformed: true);

    if (repaired == original) {
      stdout.writeln('ok (inchang�) $path');
      continue;
    }

    if (dryRun) {
      stdout.writeln('SERA r�par�  $path');
      continue;
    }

    // Sans BOM : Flutter lit de l'UTF-8, un BOM perturbe l'analyseur.
    file.writeAsBytesSync(utf8.encode(repaired));
    stdout.writeln('r�par�       $path');
  }
}
