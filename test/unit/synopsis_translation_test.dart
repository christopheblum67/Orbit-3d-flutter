import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/synopsis_translation_service.dart';

/// Adaptateur Dio qui échoue toujours : simule l'absence de réseau pour
/// tester le repli silencieux de la traduction automatique.
class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw Exception('no network in tests');
  }

  @override
  void close({bool force = false}) {}
}

class _GoogleTranslationAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode([
        [
          ['Bonjour, monde.', 'Hello, world.', null, null, 1],
        ],
        null,
        'en',
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('SynopsisTranslationService.isFrench', () {
    final service = SynopsisTranslationService();

    test('texte français → true', () {
      expect(
        service.isFrench(
          'Un jeune avatar hérite de pouvoirs anciens et doit protéger le '
          'monde autour de lui.',
        ),
        isTrue,
      );
    });

    test('texte anglais → false', () {
      expect(
        service.isFrench(
          'A young avatar inherits ancient powers and must protect the world '
          'around her.',
        ),
        isFalse,
      );
    });

    test('distinguishes Spanish from French', () {
      expect(
        service.isInLanguage(
          'Une famille qui voyage dans le sud de la France.',
          'es',
        ),
        isFalse,
      );
      expect(
        service.isInLanguage(
          'Una familia viaja por el mundo y descubre nuevas culturas.',
          'es',
        ),
        isTrue,
      );
    });
  });

  group('resolve', () {
    test('TMDB localisé est prioritaire sur la traduction automatique',
        () async {
      final result = await SynopsisTranslationService().resolve(
        rawSynopsis: 'An English summary that must never be used.',
        tmdbLocalizedSynopsis:
            'Un héros qui aime le cinéma et raconte la vie dans un village.',
      );
      expect(
        result.text,
        'Un héros qui aime le cinéma et raconte la vie dans un village.',
      );
      expect(result.source, SynopsisSource.tmdb);
      expect(result.isTranslated, isTrue);
    });

    test('synopsis déjà en français → inchangé, pas de traduction', () async {
      final result = await SynopsisTranslationService().resolve(
        rawSynopsis: 'Un héros qui aime et admire tout ce qui l\'entoure.',
        tmdbLocalizedSynopsis: '',
      );
      expect(
        result.text,
        'Un héros qui aime et admire tout ce qui l\'entoure.',
      );
      expect(result.source, SynopsisSource.original);
      expect(result.isTranslated, isFalse);
    });

    test(
        'traduction auto indisponible → texte d\'origine conservé '
        '(jamais d\'écran vide)', () async {
      final service = SynopsisTranslationService(
        dio: Dio()..httpClientAdapter = _ThrowingAdapter(),
      );
      final result = await service.resolve(
        rawSynopsis:
            'The quick brown fox jumps over the lazy dog and keeps running.',
        tmdbLocalizedSynopsis: '',
      );
      expect(
        result.text,
        'The quick brown fox jumps over the lazy dog and keeps running.',
      );
      expect(result.source, SynopsisSource.original);
    });

    test('Google array response is decoded and target language is applied',
        () async {
      final adapter = _GoogleTranslationAdapter();
      final service = SynopsisTranslationService(
        dio: Dio()..httpClientAdapter = adapter,
      );
      final result = await service.resolve(
        rawSynopsis: 'A story about a family and their journey.',
        originalLanguageCode: 'en',
        targetLanguage: 'fr',
      );

      expect(result.text, 'Bonjour, monde.');
      expect(result.source, SynopsisSource.googleTranslate);
      expect(result.attribution, 'Traduit par Google');
      expect(adapter.request?.queryParameters['tl'], 'fr');
    });

    test('summary already in selected target language is not translated',
        () async {
      final result = await SynopsisTranslationService().resolve(
        rawSynopsis: 'The hero is in the city and fights for justice.',
        targetLanguage: 'en',
      );

      expect(result.source, SynopsisSource.original);
    });
  });
}
