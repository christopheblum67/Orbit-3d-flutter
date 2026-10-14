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
  });

  group('resolve', () {
    final service = SynopsisTranslationService();

    test(
        'ordre : un synopsis TMDB français est prioritaire (qualité éditoriale)',
        () async {
      final result = await service.resolve(
        rawSynopsis: 'An English summary that must never be used.',
        tmdbFrenchSynopsis: 'Un synopsis de bien meilleure qualité.',
      );
      expect(result.text, 'Un synopsis de bien meilleure qualité.');
      expect(result.source, SynopsisSource.tmdb);
      expect(result.isTranslated, isTrue);
    });

    test('synopsis déjà en français → inchangé, pas de traduction', () async {
      final result = await service.resolve(
        rawSynopsis: 'Un héros qui aime et admire tout ce qui l\'entoure.',
        tmdbFrenchSynopsis: '',
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
        tmdbFrenchSynopsis: '',
      );
      expect(
        result.text,
        'The quick brown fox jumps over the lazy dog and keeps running.',
      );
      expect(result.source, SynopsisSource.original);
    });
  });
}
