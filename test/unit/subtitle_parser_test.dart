import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

void main() {
  group('SubtitleParser encodage', () {
    // Un fichier SRT valide : 00:00:01,000 --> 00:00:03,000
    const srt = '1\r\n'
        '00:00:01,000 --> 00:00:03,000\r\n'
        'Bonjour\r\n'
        '\r\n'
        '2\r\n'
        '00:00:04,000 --> 00:00:06,500\r\n'
        'Deuxieme ligne\r\n';

    test('parse un SRT UTF-8', () {
      final track = SubtitleParser.parse(
        srt,
        language: 'fr',
        label: 'Francais',
      );
      expect(track.cues, hasLength(2));
      expect(track.cues.first.startMs, 1000);
      expect(track.cues.first.endMs, 3000);
      expect(track.activeCueAt(1500)?.text, 'Bonjour');
      expect(track.activeCueAt(3500), isNull);
    });

    test('parse un SRT Latin-1 (accents non-ASCII)', () {
      // Flux réellement Latin-1 construit octet par octet : « Cça va » où le ç
      // est le seul octet > 0x7F (0xE7). L'objectif du test est l'encodage,
      // pas la structure multi-blocs (déjà couverte plus haut).
      // « Cça va » : C (0x43), ç (0xE7), a (0x61), espace, v, a.
      final textBytes = <int>[0x43, 0xE7, 0x61, 0x20, 0x76, 0x61];
      final raw = <int>[
        ...ascii.encode('1\r\n00:00:01,000 --> 00:00:03,000\r\n'),
        ...textBytes,
        ...ascii.encode('\r\n'),
      ];

      final track = SubtitleParser.parse(
        latin1.decode(raw),
        language: 'fr',
        label: 'Francais',
      );
      expect(track.cues, hasLength(1));
      // Point clé : l'accent survit au décodage - pas de U+FFFD, pas de
      // double-encodage de type « Ã ».
      expect(track.cues.first.text, contains('ça'));
      expect(track.cues.first.text, isNot(contains('\uFFFD')));
      expect(track.cues.first.text, isNot(contains('Ã')));
    });

    test('parse un WebVTT', () {
      const vtt = 'WEBVTT\n\n'
          '00:00:02.000 --> 00:00:04.000\n'
          'Sous-titre\n';
      final track = SubtitleParser.parse(vtt, language: 'fr');
      expect(track.cues, hasLength(1));
      expect(track.activeCueAt(3000)?.text, 'Sous-titre');
    });

    test('ignore les timecodes invalides sans casser le reste', () {
      const mixed = '1\r\n'
          'n_importe_quoi\r\n'
          'Ignore\r\n'
          '\r\n'
          '2\r\n'
          '00:00:05,000 --> 00:00:07,000\r\n'
          'Valide\r\n';
      final track = SubtitleParser.parse(mixed, language: 'fr');
      expect(track.cues, hasLength(1));
      expect(track.cues.single.text, 'Valide');
    });
  });
}
