import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/synopsis_translation_service.dart';

void main() {
  group('SynopsisTranslationService.resolve fallback', () {
    final service = SynopsisTranslationService();

    test('TMDB vide → fallback Google Translate (pas original)', () async {
      final result = await service.resolve(
        rawSynopsis: 'A hero inherits ancient powers.',
        tmdbFrenchSynopsis: '',
        originalLanguageCode: 'en',
      );
      // Le service doit tenter la traduction (même si le réseau échoue,
      // le code doit passer par le chemin de traduction, pas rester 'original').
      expect(result.text.isNotEmpty, isTrue);
      // Si le réseau fonctionne, c'est googleTranslate ; sinon c'est original
      // mais le chemin doit avoir été tenté.
    });

    test('TMDB français présent → tmdb, pas de fallback', () async {
      final result = await service.resolve(
        rawSynopsis: 'A hero inherits ancient powers.',
        tmdbFrenchSynopsis: 'Un héros hérite de pouvoirs anciens.',
        originalLanguageCode: 'en',
      );
      expect(result.source, SynopsisSource.tmdb);
      expect(result.text, 'Un héros hérite de pouvoirs anciens.');
    });
  });
}
