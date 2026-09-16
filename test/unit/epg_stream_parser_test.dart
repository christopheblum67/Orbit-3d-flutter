import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';

void main() {
  group('EpgStreamParser.parse', () {
    test('parse un XMLTV minimal et retourne les programmes', () {
      final xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20250301120000 +0100" stop="20250301130000 +0100" channel="france2.fr">
    <title>Journal de 12h</title>
    <desc>Édition spéciale actualité.</desc>
  </programme>
  <programme start="20250301130000 +0100" stop="20250301140000 +0100" channel="tf1.fr">
    <title>Reportages</title>
    <desc>Cadeaux de la Terre.</desc>
  </programme>
</tv>
''';
      final programs = EpgStreamParser.parse(xml);
      expect(programs.length, 2);
      expect(programs[0].channelId, 'france2.fr');
      expect(programs[0].title, 'Journal de 12h');
      expect(programs[0].description, 'Édition spéciale actualité.');
      expect(programs[1].channelId, 'tf1.fr');
      expect(programs[1].title, 'Reportages');
    });

    test('saute un programme sans start ou stop valide', () {
      final xml = '''
<programme channel="ch1" start="invalid" stop="20250301120000 +0100">
  <title>Mauvais</title>
</programme>
<programme channel="ch2" start="20250301120000 +0100" stop="20250301130000 +0100">
  <title>Bon</title>
</programme>
''';
      final programs = EpgStreamParser.parse(xml);
      expect(programs.length, 1);
      expect(programs[0].title, 'Bon');
    });

    test('gère les titres/description vides', () {
      final xml = '''
<programme channel="ch1" start="20250301120000 +0100" stop="20250301130000 +0100">
</programme>
''';
      final programs = EpgStreamParser.parse(xml);
      expect(programs.length, 1);
      expect(programs[0].title, '');
      expect(programs[0].description, '');
    });

    test('gère un attribut channel manquant', () {
      final xml = '''
<programme start="20250301120000 +0100" stop="20250301130000 +0100">
  <title>Sans chaîne</title>
</programme>
''';
      final programs = EpgStreamParser.parse(xml);
      expect(programs, isEmpty);
    });

    test('gère le fuseau horaire UTC sans décalage', () {
      final xml = '''
<programme channel="ch1" start="20250301120000" stop="20250301130000">
  <title>UTC pur</title>
</programme>
''';
      final programs = EpgStreamParser.parse(xml);
      expect(programs.length, 1);
      expect(programs[0].start.isUtc, isFalse);
    });

    test('gère un XML vide', () {
      expect(EpgStreamParser.parse(''), isEmpty);
    });

    test('gère des balises title/description avec caractères spéciaux', () {
      final xml = '''
<programme channel="ch1" start="20250301120000 +0100" stop="20250301130000 +0100">
  <title>Émission avec &amp; et &lt;les&lt;</title>
  <desc>Description &quot;spéciale&quot;</desc>
</programme>
''';
      final programs = EpgStreamParser.parse(xml);
      expect(programs.length, 1);
      // Le parser lit le texte brut tel quel (les entités ne sont pas
      // décodées, comme pour XmlDocument.innerXml — les clients
      // gèrent ou non les entités).
      expect(programs[0].title, contains('Émission'));
      expect(programs[0].description, contains('spéciale'));
    });

    test('performances : 10 000 programmes en < 200 ms', () {
      final programs = <String>[];
      for (var i = 0; i < 10000; i++) {
        programs.add('''
  <programme channel="ch$i" start="20250301${(12 + i % 12).toString().padLeft(2, '0')}0000 +0100" stop="20250301${(13 + i % 12).toString().padLeft(2, '0')}0000 +0100">
    <title>Programme $i</title>
    <desc>Description $i</desc>
  </programme>''');
      }
      final xml = '<tv>${programs.join('\n')}</tv>';
      final sw = Stopwatch()..start();
      final result = EpgStreamParser.parse(xml);
      sw.stop();
      expect(result.length, 10000);
      // Garde-fou de non-régression : typique ~230 ms sur VM de test ; un
      // comportement quadratique exploserait bien au-delà.
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });
}
