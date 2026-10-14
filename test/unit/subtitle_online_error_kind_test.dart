import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/stream_details_sheet.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Deux pannes distinctes, deux messages distincts.
///
/// Le code mappait tout HTTP 401 et l'absence de clé vers le même message
/// « clé API absente ». Un utilisateur qui venait de saisir sa clé recevait
/// donc « saisissez la clé » — un conseil qui ne pouvait pas être suivi,
/// puisqu'elle était déjà là. La clé était en réalité REFUSÉE par le service.
///
/// Ces tests verrouillent la classification : `http=401` ne doit JAMAIS être
/// classé comme une clé absente.
void main() {
  group('classifySubtitleOnlineError distingue absente de refusée', () {
    test('absence réelle (levée avant requête) → noApiKey', () {
      final kind = classifySubtitleOnlineError(
        'SubtitlePayloadException: Clé API OpenSubtitles absente — à saisir '
        'dans les réglages',
      );
      expect(kind, SubtitleOnlineErrorKind.noApiKey);
    });

    test('HTTP 401 (clé présente mais rejetée) → keyRejected', () {
      final kind = classifySubtitleOnlineError(
        'SubtitlePayloadException: OpenSubtitles /subtitles http=401 '
        '(Invalid API key)',
      );
      expect(
        kind,
        SubtitleOnlineErrorKind.keyRejected,
        reason: 'un 401 signifie que la clé existe mais est refusée : le '
            'message « clé absente » y mentait',
      );
    });

    test('HTTP 403 « You cannot consume this service » → keyRejected', () {
      // Mesuré en réel : /subtitles répond 403 à une clé invalide, pas 401.
      // Le classifier doit traiter ce code comme un refus, sinon la recherche
      // afficherait un effet inconnu alors que la conduite est la même.
      final kind = classifySubtitleOnlineError(
        'SubtitlePayloadException: OpenSubtitles /subtitles http=403 '
        '(You cannot consume this service)',
      );
      expect(kind, SubtitleOnlineErrorKind.keyRejected);
    });

    test('429 → quota', () {
      expect(
        classifySubtitleOnlineError('... http=429 (Too many requests)'),
        SubtitleOnlineErrorKind.quota,
      );
    });

    test('503 → needsLogin (compte requis, pas quota)', () {
      expect(
        classifySubtitleOnlineError('... http=503 (Service unavailable)'),
        SubtitleOnlineErrorKind.needsLogin,
      );
    });

    test('erreur inconnue → unknown, pas de message trompeur', () {
      expect(
        classifySubtitleOnlineError('SocketException: réseau injoignable'),
        SubtitleOnlineErrorKind.unknown,
      );
    });
  });

  group('checkApiKey interroge /subtitles et rend la cause exacte', () {
    late HttpServer server;
    late String base;
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
        request.response.statusCode = status;
        request.response.headers.contentType = ContentType.json;
        request.response.write(body == null ? '' : jsonEncode(body));
        await request.response.close();
      });
    }

    test('clé vide : missing, sans consommer de requête', () async {
      respond(200, const {'data': {}});
      final service = const OpenSubtitlesService(apiKey: '   ');

      final check = await service.checkApiKey();
      expect(check.isMissing, isTrue);
      expect(calls, 0,
          reason: 'inutile d\'interroger le service sans clé à vérifier',);
    });

    test('200 : la clé est acceptée', () async {
      respond(200, const {
        'data': <Object?>[],
      });
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      final check = await service.checkApiKey();
      expect(check.isValid, isTrue);
      expect(calls, 1);
    });

    test('401 : la clé est présente mais refusée', () async {
      respond(401, const {'message': 'Invalid API key'});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      final check = await service.checkApiKey();
      expect(check.isRejected, isTrue);
    });

    test('403 « You cannot consume this service » : refusée aussi', () async {
      respond(403, const {'message': 'You cannot consume this service'});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      final check = await service.checkApiKey();
      expect(check.isRejected, isTrue,
          reason: 'une clé invalide reçoit 403 de /subtitles en réel (et '
              'non 401) : ne pas la classer « valide »',
      );
    });

    test('500 : service injoignable (ni valide ni refusée)', () async {
      respond(500, const {'message': 'Server error'});
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      final check = await service.checkApiKey();
      expect(check.isUnreachable, isTrue);
      expect(check.detail, contains('http=500'));
    });

    test('serveur fermé : unreachable, pas de faux verdict', () async {
      await server.close(force: true);
      final service = const OpenSubtitlesService(apiKey: 'cle-de-test');

      final check = await service.checkApiKey();
      expect(check.isUnreachable, isTrue);
      expect(check.isValid, isFalse);
      expect(check.isRejected, isFalse);
    });
  });
}
