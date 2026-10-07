import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_encoding.dart';

/// L'encodage des sous-titres, mesuré plutôt que supposé.
///
/// Le défaut qui compte ici est français : l'apostrophe typographique. Elle est
/// omniprésente (`l'`, `d'`, `qu'`, `n'`) et son octet CP1252 (`0x92`) tombe
/// dans la plage que ISO-8859-1 ne définit pas. Résultat avant correction : un
/// caractère de contrôle C1, invisible, à la place du texte.
void main() {
  group('le défaut mesuré', () {
    test('ISO-8859-1 perd l\'apostrophe typographique', () {
      // Le comportement du SDK, constaté avant de corriger.
      expect(latin1.decode([0x92]).codeUnits.first, 0x0092);
    });

    test('le repli Windows-1252 la restitue', () {
      expect(
        SubtitleEncoding.decode([0x6C, 0x92]).codeUnits,
        'l’'.codeUnits,
        reason: '`l’` doit se lire `l’`, pas `l` + un contrôle invisible',
      );
    });
  });

  group('plage CP1252', () {
    test('les apostrophes et guillemets français', () {
      expect(SubtitleEncoding.decodeCp1252([0x92]), '’'); // ’
      expect(SubtitleEncoding.decodeCp1252([0x91]), '‘'); // ‘
      expect(SubtitleEncoding.decodeCp1252([0x93]), '“'); // “
      expect(SubtitleEncoding.decodeCp1252([0x94]), '”'); // ”
    });

    test('les tirets et ponctuation', () {
      expect(SubtitleEncoding.decodeCp1252([0x96]), '–'); // –
      expect(SubtitleEncoding.decodeCp1252([0x97]), '—'); // —
      expect(SubtitleEncoding.decodeCp1252([0x85]), '…'); // …
      expect(SubtitleEncoding.decodeCp1252([0x95]), '•'); // •
    });

    test('l\'euro et les ligatures', () {
      expect(SubtitleEncoding.decodeCp1252([0x80]), '€');
      expect(SubtitleEncoding.decodeCp1252([0x8C]), 'Œ');
      expect(SubtitleEncoding.decodeCp1252([0x9C]), 'œ');
    });

    test('un octet non attribué devient un remplacement VISIBLE', () {
      // 0x81 n'existe pas en CP1252. Laisser passer le caractère de contrôle
      // C1 le rendrait invisible : on préfère un U+FFFD qui se remarque.
      expect(SubtitleEncoding.decodeCp1252([0x81]), '�');
    });

    test('les octets standards restent inchangés', () {
      // 0xA0-0xFF est identique en Latin-1 et CP1252 : rien ne doit bouger.
      expect(SubtitleEncoding.decodeCp1252([0xE9]), 'é');
      expect(SubtitleEncoding.decodeCp1252([0xE0]), 'à');
      expect(SubtitleEncoding.decodeCp1252([0xE7]), 'ç');
      expect(SubtitleEncoding.decodeCp1252([0xA0]), ' ');
    });
  });

  group('choix de l\'encodage', () {
    test('un fichier UTF-8 valide passe en UTF-8', () {
      final bytes = utf8.encode('1\n00:00:01,000 --> 00:00:04,000\nÇa va ?\n');
      expect(SubtitleEncoding.decode(bytes), '1\n00:00:01,000 --> 00:00:04,000\nÇa va ?\n');
    });

    test('un fichier CP1252 part en UTF-8 STRICT, puis bascule', () {
      // `é` en 0xE9 est invalide en UTF-8 : c'est ce qui déclenche le repli.
      final bytes = <int>[0x31, 0x0A, 0xE9, 0x63, 0x6C, 0x6F, 0x73];
      expect(() => utf8.decode(bytes), throwsFormatException);
      expect(SubtitleEncoding.decode(bytes), '1\néclos');
    });

    test('le BOM UTF-8 est consommé par le décodeur', () {
      // Mesuré : `utf8.decode` retire LUI-MÊME le BOM de tête, comme la plupart
      // des décodeurs UTF-8. Le `trim()` du parseur n'a donc rien à retirer de
      // plus — deux protections, pas une. Rien à corriger ici.
      final withBom = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode('1\n')];
      expect(withBom.take(3).toList(), [0xEF, 0xBB, 0xBF], reason: 'prérequis');
      expect(SubtitleEncoding.decode(withBom), '1\n');
    });

    test('un fichier vide ne plante pas', () {
      expect(SubtitleEncoding.decode(<int>[]), isEmpty);
    });

    test('une phrase française complète en CP1252 se relit', () {
      // Vrai payload CP1252 : chaque caractère non-ASCII tient sur UN octet.
      // Les octets sont assemblés à la main, car un caractère CP1252 n'a pas
      // d'échappement dans une chaîne Dart.
      final bytes = <int>[
        ...utf8.encode('Il va chez l'),
        0x92, // ’ apostrophe typographique
        0xE9, // é
        ...utf8.encode('picerie : 3 '),
        0x93, // “
        ...utf8.encode('caf'),
        0xE9, // é
        ...utf8.encode('s'),
        0x94, // ”
        ...utf8.encode(', 5'),
        0x80, // €
        ...utf8.encode('.\n'),
      ];
      expect(
        SubtitleEncoding.decode(bytes),
        'Il va chez l’épicerie : 3 “cafés”, 5€.\n',
      );
    });

    test('un fichier UTF-8 lu comme CP1252 reste du mojibake', () {
      // Ce n'est pas rattrapable, et c'est important de le savoir : un fichier
      // dont les octets de la plage haute sont TOUS valides en UTF-8 ET en
      // CP1252 est ambigu. Ici il est valide en UTF-8, donc il gagne — et c'est
      // la bonne décision. Le cas mojibake survient quand le mélange est
      // DÉJÀ dans le fichier, produit en amont : aucun décodeur ne peut le
      // deviner. On le documente plutôt que de prétendre le corriger.
      final bytes = <int>[
        ...utf8.encode('l'),
        ...utf8.encode('é'),
        ...utf8.encode('picerie'),
      ];
      expect(
        SubtitleEncoding.decode(bytes),
        'lépicerie',
        reason: 'fichier UTF-8 valide : il doit passer en UTF-8, pas être '
            'relu en CP1252',
      );
    });
  });
}