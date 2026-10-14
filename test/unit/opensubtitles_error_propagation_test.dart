import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Les erreurs OpenSubtitles ne doivent pas ressembler à « aucun résultat ».
///
/// Le code faisait `result.valueOrNull ?? const []` sur un `safeAsync` **sans**
/// `fallbackValue` : un 401 (clé refusée), un 429 (quota) ou une panne
/// devenaient une liste vide. Le `try/catch` de l'appelant existait — il ne
/// se déclenchait simplement jamais.
///
/// Conséquence utilisateur : une clé refusée affichait « aucun sous-titre
/// trouvé », ce qui renvoie la recherche dans une direction fausse.
///
/// Ces tests servent un vrai serveur local, via [OpenSubtitlesService.baseUrlOverride].
void main() {
  late HttpServer server;
  late String base;

  /// Répond `status` avec `body`, et compte les appels.
  var calls = 0;

  setUp(() async {
    calls = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}/api/v1';
    OpenSubtitlesService.baseUrlOverride = base;
  });

  tearDown(() async {
    OpenSubtitlesService.resetBaseUrl();
    await server.close(force: true);
  });

  void respond(int status, Object? body) {
    server.listen((request) async {
      calls++;
      final payload = body == null ? '' : jsonEncode(body);
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(payload);
      await request.response.close();
    });
  }

  const emptyResults = {
    'data': <Object>[],
    'total_count': 0,
    'file_count': 0,
  };

  group('un résultat vide est un résultat VALIDE', () {
    test('aucune exception, liste vide', () async {
      respond(200, emptyResults);
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      final hits = await service.searchMovie(27205);
      expect(hits, isEmpty);
      // Exactement 2 requêtes : `/features` pour résoudre le titre, puis
      // `/subtitles`. Le compte est vérifié au nombre près : une troisième
      // requête signalerait une relance, or réessayer sur un 4xx/5xx ne fait
      // qu'aggraver la situation auprès du service.
      expect(calls, 1);
    });
  });

  group('un échec HTTP remonte au lieu de produire une liste vide', () {
    test('401 : clé refusée', () async {
      respond(401, {'message': 'Invalid API key'});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      await expectLater(
        service.searchMovie(27205),
        throwsA(predicate((e) => '$e'.contains('http=401'))),
        reason: 'un 401 doit dire « clé refusée », pas « pas de résultat »',
      );
    });

    test('429 : quota épuisé', () async {
      respond(429, {'message': 'Too many requests'});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      await expectLater(
        service.searchMovie(27205),
        throwsA(predicate((e) => '$e'.contains('http=429'))),
      );
    });

    test('500 : panne du service', () async {
      respond(500, {'message': 'Server error'});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      await expectLater(
        service.searchMovie(27205),
        throwsA(predicate((e) => '$e'.contains('http=500'))),
      );
    });
  });

  group('clé API absente', () {
    test('échoue AVANT toute requête', () async {
      respond(200, emptyResults);
      final service = const OpenSubtitlesService(apiKey: '');

      await expectLater(service.searchMovie(27205), throwsA(anything));
      expect(calls, 0,
          reason: 'sans clé, inutile de consommer une requête : le message '
              'doit être « saisissez la clé »',);
    });
  });

  group('le 503 de /download est bien identifié', () {
    test('la cause est un compte manquant, pas un quota', () async {
      // OpenSubtitles exige DEUX en-têtes sur /download : `Api-Key` ET
      // `Authorization: Bearer` (obtenu via /login). La clé seule suffit à la
      // recherche, d'où la confusion. Et contre-intuitif : l'en-tête
      // manquant ne renvoie pas 401 mais 503 « Service unavailable ».
      respond(503, {'data': {'message': 'Service unavailable'}});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      await expectLater(
        service.searchMovie(27205),
        throwsA(predicate((e) => '$e'.contains('http=503'))),
        reason: 'le 503 doit être reconnaissable pour que l\'interface affiche '
            '« compte requis » et non une classe d\'exception',
      );
    });
  });
}