import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';

void main() {
  group('EpgStreamParser — échappement XML des titres', () {
    test("l'apostrophe échappée est rendue", () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>C dans l&apos;achat</title></programme>',
      );
      expect(programs.length, 1);
      expect(programs.single.title, "C dans l'achat");
    });

    test('les guillemets et chevrons sont rendus', () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>Le &quot;Grand&quot; &lt;Journal&gt;</title>'
        '</programme>',
      );
      expect(programs.single.title, 'Le "Grand" <Journal>');
    });

    test('les références numériques sont rendues', () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>It&#39;s caf&#xE9;</title></programme>',
      );
      expect(programs.single.title, "It's café");
    });

    test('une esperluette réelle reste une esperluette', () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>Tom &amp; Jerry</title></programme>',
      );
      expect(programs.single.title, 'Tom & Jerry');
    });

    // Un seul passage de dé-échappement : `&amp;apos;` est le texte littéral
    // « &apos; », pas une apostrophe.
    test('un échappement double reste double', () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>&amp;apos;</title></programme>',
      );
      expect(programs.single.title, '&apos;');
    });

    test('la description est traitée comme le titre', () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>JT</title>'
        '<desc>L&apos;edition de 13 h</desc></programme>',
      );
      expect(programs.single.description, "L'edition de 13 h");
    });

    test('un titre sans échappement est inchangé', () {
      final programs = EpgStreamParser.parse(
        '<programme start="20261001060000 +0000" stop="20261001070000 +0000" '
        'channel="tf1.fr"><title>Le Grand Journal</title></programme>',
      );
      expect(programs.single.title, 'Le Grand Journal');
    });
  });
}