import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Décodage du dump XMLTV : c'est lui qui décide si « journée » reste lu en
/// clair ou en mojibake — et, surtout, il tourne maintenant dans l'isolate,
/// avec les octets TRANSFÉRÉS (zero-copy) au lieu d'une String construite sur
/// le thread UI puis recopiée.
///
/// Les attentes utilisent des échappements explicites : `\u00c3\u00a9` est le
/// mojibake des octets UTF-8 de « é » relus en latin-1 (0xC3 0xA9 → "Ã©"),
/// `\u00e9` est le « é » propre. Aucun caractère non-ASCII n'est dépendant de
/// l'encodage de ce fichier.
///
/// Priorité verrouillée ici, dans cet ordre :
/// 1. la déclaration `encoding=` du prologue XML ;
/// 2. le `charset` de l'en-tête HTTP ;
/// 3. UTF-8 ;
/// 4. latin-1 (ne peut pas échouer).
void main() {
  /// Mojibake attendu quand des octets UTF-8 sont relus en latin-1.
  const mojibake = '\u00c3\u00a9';

  group('ApiService.decodeXmltvBytes', () {
    /// Octets UTF-8 sans déclaration d'encodage (le cas le plus courant).
    Uint8List utf8Dump(String body) =>
        Uint8List.fromList(utf8.encode('<?xml version="1.0"?>$body'));

    /// Octets UTF-8 annonçant pourtant un encodage donné.
    Uint8List dumpWithEncoding(String encoding, String body) =>
        Uint8List.fromList(
          utf8.encode('<?xml version="1.0" encoding="$encoding"?>$body'),
        );

    test('lit un dump UTF-8 sans déclaration (cas réel des panels)', () {
      final decoded = ApiService.decodeXmltvBytes(utf8Dump('<tv>Journ\u00e9e</tv>'));

      expect(decoded, contains('Journ\u00e9e'));
      expect(decoded, isNot(contains(mojibake)), reason: 'pas de mojibake');
    });

    test('la déclaration `encoding=` du prologue prime sur l\'en-tête HTTP', () {
      // Les octets sont valides UTF-8 et l'en-tête annonce UTF-8 : si le
      // prologue n'avait pas été lu, on obtiendrait « Journée » en clair.
      // On attend donc EXPLICITEMENT le mojibake : c'est la preuve que la
      // déclaration `iso-8859-1` a été lue et appliquée en priorité,
      // conformément au standard XML (le document est cru).
      final decoded = ApiService.decodeXmltvBytes(
        dumpWithEncoding('iso-8859-1', '<tv>Journ\u00e9e</tv>'),
        headerCharset: 'utf-8',
      );

      expect(decoded, contains(mojibake), reason: 'prologue cru, pas l\'en-tête');
      expect(decoded, isNot(contains('Journ\u00e9e')));
    });

    test('sans prologue, l\'en-tête HTTP guide le décodage', () {
      // Même logique : UTF-8 par défaut donnerait le texte en clair ; on
      // exige que `windows-1252` ait bien été appliqué.
      final decoded = ApiService.decodeXmltvBytes(
        utf8Dump('<tv>Journ\u00e9e</tv>'),
        headerCharset: 'windows-1252',
      );

      expect(decoded, contains(mojibake), reason: 'l\'en-tête doit être honnoré');
      expect(decoded, isNot(contains('Journ\u00e9e')));
    });

    test('une déclaration d\'encodage inconnue retombe sur UTF-8', () {
      final decoded = ApiService.decodeXmltvBytes(
        dumpWithEncoding('koi8-r', '<tv>Journ\u00e9e</tv>'),
      );

      expect(decoded, contains('Journ\u00e9e'));
      expect(decoded, isNot(contains(mojibake)));
    });

    test('des octets UTF-8 cassés retombent sur latin-1 sans lever', () {
      // 0xE9 suivi de « A » : `utf8.decode` lance (octet latin-1 isolé),
      // `latin1.decode(..., allowInvalid: true)` non.
      final decoded = ApiService.decodeXmltvBytes(
        Uint8List.fromList([0xE9, 0x41]),
      );

      expect(decoded, '\u00e9A');
    });

    test('un dump vide rend une chaîne vide', () {
      expect(ApiService.decodeXmltvBytes(Uint8List(0)), '');
    });
  });

  group('le dump est décodé et parsé dans l\'isolate', () {
    test('un message transféré (zero-copy) traverse Isolate.run', () async {
      final xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20250301120000 +0100" stop="20250301130000 +0100" channel="france2.fr">
    <title>Journ\u00e9e sp\u00e9ciale</title>
    <desc>\u00c9dition sp\u00e9ciale.</desc>
  </programme>
</tv>
''';

      final programs = await ApiService.debugParseXmltvInIsolate(
        Uint8List.fromList(utf8.encode(xml)),
      );

      expect(programs, hasLength(1));
      expect(programs.single.channelId, 'france2.fr');
      expect(programs.single.title, 'Journ\u00e9e sp\u00e9ciale');
      expect(programs.single.description, '\u00c9dition sp\u00e9ciale.');
    });

    test('l\'en-tête HTTP est bien transmis jusqu\'à l\'isolate', () async {
      final xml = '<tv><programme start="20250301120000 +0100" '
          'stop="20250301130000 +0100" channel="france2.fr">'
          '<title>Journ\u00e9e</title></programme></tv>';

      // Octets valides UTF-8 + en-tête windows-1252 : le mojibake attendu
      // n'apparaît que si `headerCharset` a réellement traversé le message
      // jusqu'à l'isolate (ce que `compute` n'est pas garanti de faire pour
      // un record contenant un TransferableTypedData).
      final programs = await ApiService.debugParseXmltvInIsolate(
        Uint8List.fromList(utf8.encode(xml)),
        headerCharset: 'windows-1252',
      );

      expect(programs, hasLength(1));
      expect(
        programs.single.title,
        contains(mojibake),
        reason: 'le charset de l\'en-tête doit arriver dans l\'isolate',
      );
      expect(programs.single.title, isNot(contains('Journ\u00e9e')));
    });
  });
}
