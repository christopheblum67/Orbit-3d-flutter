import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

void main() {
  group('validation du contenu d\'une piste de sous-titres', () {
    const srtValide = '1\n00:00:01,000 --> 00:00:03,000\nBonjour\n\n'
        '2\n00:00:04,000 --> 00:00:06,000\nAu revoir\n';

    test('un SRT avec des cues est exploitable', () {
      final track = SubtitleParser.parse(srtValide, language: 'fr');
      expect(track.cues.length, 2);
      expect(SubtitleParser.isUsable(srtValide, track), isTrue);
    });

    test('un WEBVTT avec des cues est exploitable', () {
      const vtt = 'WEBVTT\n\n00:00:01.000 --> 00:00:03.000\nBonjour\n';
      final track = SubtitleParser.parse(vtt, language: 'fr');
      expect(track.cues.length, 1);
      expect(SubtitleParser.isUsable(vtt, track), isTrue);
    });

    // Le cas réel rencontré : le panel répond 200 avec sa page d'erreur, la
    // piste s'affichait dans la liste et n'affichait jamais rien à l'écran.
    test('une page HTML est refusée même si elle contient un timecode', () {
      const html = '<!DOCTYPE html>\n<html><head><title>404</title></head>'
          '<body>00:00:01,000 --> 00:00:03,000</body></html>';
      final track = SubtitleParser.parse(html, language: 'fr');
      expect(SubtitleParser.isUsable(html, track), isFalse);
    });

    test('une balise html sans doctype est refusée', () {
      const html = '<html><body>introuvable</body></html>';
      final track = SubtitleParser.parse(html, language: 'fr');
      expect(SubtitleParser.isUsable(html, track), isFalse);
    });

    test('un corps vide est refusé', () {
      const vide = '';
      final track = SubtitleParser.parse(vide, language: 'fr');
      expect(track.cues, isEmpty);
      expect(SubtitleParser.isUsable(vide, track), isFalse);
    });

    test('un corps sans aucun cue est refusé', () {
      const sansCue = 'introuvable';
      final track = SubtitleParser.parse(sansCue, language: 'fr');
      expect(track.cues, isEmpty);
      expect(SubtitleParser.isUsable(sansCue, track), isFalse);
    });
  });
}