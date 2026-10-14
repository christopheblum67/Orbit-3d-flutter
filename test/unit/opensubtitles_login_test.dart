import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Le `/download` d'OpenSubtitles exige DEUX en-têtes : `Api-Key` ET
/// `Authorization: Bearer <JWT>`. Le jeton s'obtient via `/login` et vaut
/// ~24 h. Sans compte, le service répond 503 « Service unavailable » — la
/// recherche fonctionne, le téléchargement non.
///
/// Ces tests servent un vrai serveur local, piloté par
/// [OpenSubtitlesService.baseUrlOverride], et vérifient l'en-tête réellement
/// envoyé ainsi que la relogin automatique sur jeton périmé.
void main() {
  late HttpServer server;
  late String base;

  /// Compteurs et en-têtes observés, réinitialisés à chaque test.
  var calls = 0;
  var loginCalls = 0;
  final downloadAuth = <String?>[];

  const srt = '1\n00:00:01,000 --> 00:00:03,000\nBonjour le monde\n';
  const hit = OpenSubtitlesHit(
    fileId: 42,
    language: 'fr',
    fileName: 'film.fr.srt',
  );

  setUp(() async {
    calls = 0;
    loginCalls = 0;
    downloadAuth.clear();
    OpenSubtitlesService.resetAuth();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}/api/v1';
    OpenSubtitlesService.baseUrlOverride = base;
  });

  tearDown(() async {
    OpenSubtitlesService.resetBaseUrl();
    OpenSubtitlesService.resetAuth();
    await server.close(force: true);
  });

  Future<void> jsonResponse(
    HttpRequest request,
    int status,
    Object? body,
  ) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body == null ? '' : jsonEncode(body));
    await request.response.close();
  }

  /// Sert `/login`, `/download` puis toute URL signée en SRT valide.
  ///
  /// [downloadUnauthorizedFirst] fait répondre 401 sur les N premiers
  /// `/download`, pour simuler un jeton périmé.
  void serve({
    int loginStatus = 200,
    Object? loginBody = const {'token': 'jwt-abc', 'status': 200},
    int downloadStatus = 200,
    Map<String, Object?> downloadBody = const {'remaining': 9},
    int downloadUnauthorizedFirst = 0,
  }) {
    var remaining401 = downloadUnauthorizedFirst;
    server.listen((request) async {
      calls++;
      final path = request.uri.path;
      if (path.endsWith('/login')) {
        loginCalls++;
        await jsonResponse(request, loginStatus, loginBody);
        return;
      }
      if (path.endsWith('/download')) {
        downloadAuth.add(request.headers.value(HttpHeaders.authorizationHeader));
        if (remaining401 > 0) {
          remaining401--;
          await jsonResponse(request, 401, const {'message': 'invalid token'});
          return;
        }
        final body = <String, Object?>{
          if (downloadStatus == 200)
            'url': 'http://127.0.0.1:${server.port}/subtitles/demo.srt',
          ...downloadBody,
        };
        await jsonResponse(request, downloadStatus, body);
        return;
      }
      // URL signée : le service y récupère le fichier.
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.text;
      request.response.write(srt);
      await request.response.close();
    });
  }

  group('login valorise /download en Bearer', () {
    test('le jeton est obtenu puis rejoué en Authorization', () async {
      serve();
      const service = OpenSubtitlesService(
        apiKey: 'k',
        username: 'u',
        password: 'p',
      );

      final track = await service.download(hit);

      expect(
        track.cues,
        isNotEmpty,
        reason:
            'le SRT de l\'URL signée doit être parsé en piste exploitable',
      );
      expect(
        downloadAuth,
        ['Bearer jwt-abc'],
        reason: '/download doit porter le jeton, sinon le service répond 503',
      );
      expect(loginCalls, 1);
      expect(calls, 3, reason: '/login + /download + URL signée');
    });
  });

  group('sans compte, la conduite reste le 503 existant', () {
    test('aucun /login n\'est tenté, le 503 remonte', () async {
      serve(
        downloadStatus: 503,
        downloadBody: const {'message': 'Service unavailable'},
      );
      const service = OpenSubtitlesService(apiKey: 'k');

      await expectLater(
        service.download(hit),
        throwsA(predicate((e) => '$e'.contains('http=503'))),
        reason: 'sans identifiants, le message « compte requis » de '
            'l\'interface doit continuer de fonctionner',
      );
      expect(
        loginCalls,
        0,
        reason: 'sans compte, inutile de consommer un /login',
      );
    });
  });

  group('jeton périmé', () {
    test('un 401 sur /download relogue une fois et réessaie', () async {
      serve(downloadUnauthorizedFirst: 1);
      const service = OpenSubtitlesService(
        apiKey: 'k',
        username: 'u',
        password: 'p',
      );

      final track = await service.download(hit);

      expect(track.cues, isNotEmpty);
      expect(
        loginCalls,
        2,
        reason: 'un jeton rejeté doit déclencher UNE relogin, pas zéro ni boucle',
      );
      expect(downloadAuth, ['Bearer jwt-abc', 'Bearer jwt-abc']);
      expect(
        calls,
        5,
        reason: '/login + /download(401) + /login + /download + URL signée',
      );
    });
  });

  group('checkLogin rend la cause exacte', () {
    test('missing : aucun compte, sans consommer de requête', () async {
      serve();
      const service = OpenSubtitlesService(apiKey: 'k');

      final check = await service.checkLogin();

      expect(check.isMissing, isTrue);
      expect(calls, 0);
    });

    test('valid : /login délivre un jeton', () async {
      serve();
      const service = OpenSubtitlesService(
        apiKey: 'k',
        username: 'u',
        password: 'p',
      );

      final check = await service.checkLogin();

      expect(check.isValid, isTrue);
      expect(loginCalls, 1);
    });

    test('rejected : /login répond 401', () async {
      serve(
        loginStatus: 401,
        loginBody: const {'message': 'Invalid credentials'},
      );
      const service = OpenSubtitlesService(
        apiKey: 'k',
        username: 'u',
        password: 'p',
      );

      final check = await service.checkLogin();

      expect(check.isRejected, isTrue);
      expect(check.isValid, isFalse);
    });

    test('unreachable : serveur fermé, aucun faux verdict', () async {
      await server.close(force: true);
      const service = OpenSubtitlesService(
        apiKey: 'k',
        username: 'u',
        password: 'p',
      );

      final check = await service.checkLogin();

      expect(check.isUnreachable, isTrue);
      expect(check.isValid, isFalse);
      expect(check.isRejected, isFalse);
    });
  });

  group('identifiants refusés', () {
    test('download lève SubtitlePayloadException (message « refusé »)',
        () async {
      serve(
        loginStatus: 401,
        loginBody: const {'message': 'Invalid credentials'},
      );
      const service = OpenSubtitlesService(
        apiKey: 'k',
        username: 'u',
        password: 'p',
      );

      await expectLater(
        service.download(hit),
        throwsA(
          predicate(
            (e) => e is SubtitlePayloadException && e.message.contains('refusé'),
          ),
        ),
        reason: 'le refus de /login doit remonter comme une erreur homogène, '
            'pas comme une classe d\'exception inconnue de l\'interface',
      );
      expect(loginCalls, 1);
    });
  });
}