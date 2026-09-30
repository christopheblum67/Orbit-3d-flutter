// Rend les accents perdus par la passe « mojibake ».
//
// ## Ce qui s'est passé
//
// Un fichier sain (accents en UTF-8, `é` = C3 A9) a été ré-encodé en
// Latin-1 : chaque caractère est devenu un seul octet (`é` = E9), puis relu
// comme de l'UTF-8. E9 seul est une séquence UTF-8 invalide → U+FFFD.
//
// ## La récupération
//
// L'octet E9 est toujours là. Il suffit de le ré-encoder en UTF-8 (C3 A9) pour
// retrouver le caractère d'origine. On procède donc octet par octet :
//
//   - octet ASCII                     → recopié tel quel
//   - séquence UTF-8 valide (>= 2 octets) → recopiée telle quelle (caractère
//     legitimately > U+00FF, intact)
//   - octet >= 0x80 isolé             → ré-encodé en UTF-8 depuis sa valeur
//     Latin-1 : c'est un accent abîmé
//
// Le résultat est vérifié : le fichier réécrit ne doit plus contenir U+FFFD.
import 'dart:convert';
import 'dart:io';

bool _isContinuation(int b) => b >= 0x80 && b <= 0xBF;

/// Longueur de la séquence UTF-8 valide démarrant à [i], ou 0 si invalide.
int _sequenceLength(List<int> bytes, int i) {
  final b0 = bytes[i];
  if (b0 < 0x80) return 1;
  if (b0 >= 0xC2 && b0 <= 0xDF) {
    if (i + 1 < bytes.length && _isContinuation(bytes[i + 1])) return 2;
    return 0;
  }
  if (b0 >= 0xE0 && b0 <= 0xEF) {
    if (i + 2 < bytes.length &&
        _isContinuation(bytes[i + 1]) &&
        _isContinuation(bytes[i + 2])) {
      return 3;
    }
    return 0;
  }
  if (b0 >= 0xF0 && b0 <= 0xF4) {
    if (i + 3 < bytes.length &&
        _isContinuation(bytes[i + 1]) &&
        _isContinuation(bytes[i + 2]) &&
        _isContinuation(bytes[i + 3])) {
      return 4;
    }
    return 0;
  }
  return 0;
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  for (final path in args.where((a) => a != '--dry-run')) {
    final file = File(path);
    final bytes = file.readAsBytesSync();

    final before = utf8.decode(bytes, allowMalformed: true);
    if (!before.contains('\uFFFD')) {
      stdout.writeln('ok (intact)  $path');
      continue;
    }

    final out = BytesBuilder(copy: false);
    var repaired = 0;
    var i = 0;
    while (i < bytes.length) {
      final len = _sequenceLength(bytes, i);
      if (len >= 2 || (len == 1 && bytes[i] < 0x80)) {
        // ASCII ou séquence UTF-8 multi-octets déjà valide : on recopie.
        out.add(bytes.sublist(i, i + len));
        i += len;
        continue;
      }
      // Octet >= 0x80 isolé : accent Latin-1 à ré-encoder.
      out.add(utf8.encode(String.fromCharCode(bytes[i])));
      repaired++;
      i++;
    }

    final newBytes = out.takeBytes();
    final after = utf8.decode(newBytes, allowMalformed: true);
    if (after.contains('\uFFFD')) {
      stderr.writeln('échec        $path : accents encore illisibles');
      continue;
    }

    if (!dryRun) file.writeAsBytesSync(newBytes);
    stdout.writeln('${dryRun ? "[secours] " : ""}$path : $repaired accent(s) '
        'restauré(s)');
  }
}
