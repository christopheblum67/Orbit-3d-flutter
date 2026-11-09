import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/local_video_proxy.dart';
import 'package:orbit_3d_flutter/services/video_disk_cache.dart';

class _ObservableCache extends VideoDiskCache {
  _ObservableCache(super.directory) : super(maxBytes: 64);

  void Function()? onRead;

  @override
  Future<T?> withEntry<T>(String key, Future<T> Function(File file) read) {
    onRead?.call();
    return super.withEntry(key, read);
  }
}

void main() {
  late HttpServer upstream;
  late LocalVideoProxy proxy;
  late HttpClient client;
  late Directory cacheDir;
  late _ObservableCache cache;
  final requests = <String>[];
  final requestCacheControls = <String?>[];

  setUpAll(() {
    HttpOverrides.global = null;
  });

  setUp(() async {
    requests.clear();
    requestCacheControls.clear();
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((request) async {
      requests.add('${request.uri.path}|${request.headers.value('range')}');
      requestCacheControls.add(request.headers.value('cache-control'));
      if (request.uri.path == '/redirect.m3u8') {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set('location', '/hls/index.m3u8');
      } else if (request.uri.path == '/hls/index.m3u8') {
        request.response.headers.contentType =
            ContentType('application', 'vnd.apple.mpegurl');
        request.response.write(
            '#EXTM3U\n#EXT-X-KEY:METHOD=AES-128,URI="key"\nsegment.ts\n');
      } else if (request.uri.path == '/bad.m3u8') {
        request.response.headers.contentType =
            ContentType('application', 'vnd.apple.mpegurl');
        request.response.write('#EXTM3U\nfile:///secret\n');
      } else if (request.uri.path == '/extensionless') {
        request.response.headers.contentType =
            ContentType('application', 'x-mpegurl');
        request.response.write('#EXTM3U\n/hls/index.m3u8\n');
      } else if (request.uri.path == '/dash') {
        request.response.headers.contentType =
            ContentType('application', 'dash+xml');
        request.response.write('<MPD/>');
      } else if (request.uri.path.endsWith('.ts')) {
        const body = '0123456789';
        request.response.headers.date = DateTime.now().toUtc();
        final range = request.headers.value('range');
        request.response.headers.set(
            'cache-control',
            request.uri.path == '/private.ts'
                ? 'private, max-age=60'
                : 'public, max-age=60');
        if (request.uri.path == '/vary.ts')
          request.response.headers.set('vary', 'Accept');
        if (request.uri.path == '/old.ts')
          request.response.headers.set('age', '60');
        request.response.headers.contentType = ContentType('video', 'mp2t');
        if (range == 'bytes=3-5') {
          request.response.statusCode = 206;
          request.response.headers.set('content-range', 'bytes 3-5/10');
          request.response.contentLength = 3;
          request.response.write('345');
        } else {
          request.response.contentLength = body.length;
          request.response.write(body);
        }
      } else {
        const body = '0123456789';
        final range = request.headers.value('range');
        if (range == 'bytes=3-5') {
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set('content-range', 'bytes 3-5/10');
          request.response.write(body.substring(3, 6));
        } else if (range == 'bytes=99-') {
          request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          request.response.headers.set('content-range', 'bytes */10');
        } else {
          request.response.write(body);
        }
      }
      await request.response.close();
    });
    cacheDir = await Directory.systemTemp.createTemp('orbit_proxy_test');
    cache = _ObservableCache(cacheDir);
    await cache.initialize();
    proxy = LocalVideoProxy(cache: cache);
    await proxy.start();
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await proxy.close();
    await upstream.close(force: true);
    await cacheDir.delete(recursive: true);
  });

  Uri target(String path) =>
      Uri.parse('http://127.0.0.1:${upstream.port}$path');
  Future<(int, HttpHeaders, String)> get(Uri url,
      {String? range, String? cacheControl}) async {
    final request = await client.getUrl(url);
    if (range != null) request.headers.set('range', range);
    if (cacheControl != null)
      request.headers.set('cache-control', cacheControl);
    final response = await request.close();
    return (
      response.statusCode,
      response.headers,
      await utf8.decoder.bind(response).join()
    );
  }

  Future<void> waitForCache() async {
    for (var i = 0; i < 100; i++) {
      if ((await cacheDir.list().toList())
          .any((f) => f.path.endsWith('.cache'))) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('La réponse complète n’a pas été mise en cache');
  }

  test('sert les plages depuis une réponse complète et fraîche', () async {
    final session = proxy.openSession(target('/public.ts'));
    expect((await get(session.url)).$3, '0123456789');
    await waitForCache();
    final partial = await get(session.url, range: 'bytes=3-5');
    expect(partial.$1, 206);
    expect(partial.$2.value('content-range'), 'bytes 3-5/10');
    expect(partial.$2.contentType?.mimeType, 'video/mp2t');
    expect(partial.$3, '345');
    expect((await get(session.url, range: 'bytes=-2')).$3, '89');
    final invalid = await get(session.url, range: 'bytes=99-');
    expect(invalid.$1, 416);
    expect(invalid.$2.value('content-range'), 'bytes */10');
    expect(requests, ['/public.ts|null']);
    await get(session.url, cacheControl: 'no-cache');
    expect(requests, hasLength(2));
    expect(requestCacheControls.last, 'no-cache');
    await get(session.url);
    expect(requests, hasLength(3));
    await cache.clear();
    expect((await get(session.url)).$3, '0123456789');
    expect(requests, hasLength(4));
  });

  test('ne conserve pas un téléchargement interrompu', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {
      socket.listen((_) {
        socket.add(ascii.encode(
          'HTTP/1.1 200 OK\r\n'
          'Date: ${HttpDate.format(DateTime.now().toUtc())}\r\n'
          'Cache-Control: public, max-age=60\r\n'
          'Content-Type: video/mp2t\r\n'
          'Content-Length: 10\r\n'
          'Connection: close\r\n\r\n123',
        ));
        socket.close();
      });
    });
    try {
      final session = proxy.openSession(
        Uri.parse('http://127.0.0.1:${server.port}/truncated.ts'),
      );
      await expectLater(get(session.url), throwsA(isA<HttpException>()));
      expect((await cacheDir.list().toList()).whereType<File>(), isEmpty);
    } finally {
      await server.close();
    }
  });

  test('une purge empêche une lecture en attente de servir un ancien fichier',
      () async {
    final session = proxy.openSession(target('/public.ts'));
    await get(session.url);
    await waitForCache();
    await cache.store('lock', Stream.value([1]), contentLength: 1);
    final locked = Completer<void>();
    final release = Completer<void>();
    final hold = cache.withEntry('lock', (_) async {
      locked.complete();
      await release.future;
    });
    await locked.future;
    final queued = Completer<void>();
    cache.onRead = () {
      if (!queued.isCompleted) queued.complete();
    };
    final read = get(session.url);
    await queued.future;
    final clear = cache.clear();
    release.complete();
    await hold;
    await clear;
    expect((await read).$3, '0123456789');
    expect(requests, hasLength(2));
  });

  test('une session fermée ne démarre pas de requête amont en attente',
      () async {
    final session = proxy.openSession(target('/public.ts'));
    await get(session.url);
    await waitForCache();
    await cache.store('lock', Stream.value([1]), contentLength: 1);
    final locked = Completer<void>();
    final release = Completer<void>();
    final hold = cache.withEntry('lock', (_) async {
      locked.complete();
      await release.future;
    });

    await locked.future;
    final queued = Completer<void>();
    cache.onRead = () {
      if (!queued.isCompleted) queued.complete();
    };
    final read = get(session.url);
    await queued.future;
    session.close();
    release.complete();
    await hold;
    expect((await read).$1, 404);
    expect(requests, hasLength(1));
  });

  test('la fermeture de session supprime ses fichiers sans toucher aux autres',
      () async {
    final session = proxy.openSession(target('/public.ts'));
    await get(session.url);
    await waitForCache();
    await cache.store('autre', Stream.value([1]), contentLength: 1);
    session.close();
    await proxy.close();
    final remaining =
        (await cacheDir.list().toList()).whereType<File>().toList();
    expect(remaining, hasLength(1));
    expect(await cache.withEntry('autre', (file) => file.length()), 1);
  });

  test('la fermeture du relais nettoie les sessions ouvertes', () async {
    final session = proxy.openSession(target('/public.ts'));
    await get(session.url);
    await waitForCache();
    await proxy.close();
    expect((await cacheDir.list().toList()).whereType<File>(), isEmpty);
    await proxy.close();
  });

  test('un no-cache concurrent invalide une lecture en attente', () async {
    final session = proxy.openSession(target('/public.ts'));
    await get(session.url);
    await waitForCache();
    await cache.store('lock', Stream.value([1]), contentLength: 1);
    final locked = Completer<void>();
    final release = Completer<void>();
    final hold = cache.withEntry('lock', (_) async {
      locked.complete();
      await release.future;
    });
    await locked.future;
    final queued = Completer<void>();
    cache.onRead = () {
      if (!queued.isCompleted) queued.complete();
    };
    final read = get(session.url);
    await queued.future;
    await get(session.url, cacheControl: 'no-cache');
    release.complete();
    await hold;
    expect((await read).$3, '0123456789');
    expect(requests, hasLength(3));
  });

  test('ferme le relais pendant une réponse amont en attente', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<void>();
    final release = Completer<void>();
    server.listen((request) async {
      received.complete();
      await release.future;
      try {
        await request.response.close();
      } on HttpException {
        // La connexion a été fermée avec le relais.
      } on SocketException {
        // La connexion a été fermée avec le relais.
      }
    });
    final session = proxy.openSession(
      Uri.parse('http://127.0.0.1:${server.port}/slow.mp4'),
    );
    final pending = get(session.url);
    final result = expectLater(pending, throwsA(isA<Exception>()));
    try {
      await received.future;
      await proxy.close().timeout(const Duration(seconds: 5));
      await result;
    } finally {
      release.complete();
      await server.close(force: true);
    }
  });
  test('ne conserve ni réponse partielle ni ressources privées ou variables',
      () async {
    for (final path in ['/private.ts', '/vary.ts', '/old.ts']) {
      final session = proxy.openSession(target(path));
      await get(session.url);
      await get(session.url);
      expect(requests.where((request) => request.startsWith('$path|')),
          hasLength(2));
    }
    final partial = proxy.openSession(target('/partial.ts'));
    expect((await get(partial.url, range: 'bytes=3-5')).$1, 206);
    expect((await get(partial.url)).$3, '0123456789');
    expect(requests.where((request) => request.startsWith('/partial.ts|')),
        hasLength(2));
    final auth = proxy
        .openSession(target('/auth.ts'), headers: {'Authorization': 'private'});
    await get(auth.url);
    await get(auth.url);
    expect(requests.where((request) => request.startsWith('/auth.ts|')),
        hasLength(2));
  });

  test('transmet les plages 206 et 416 et révoque la session', () async {
    final session = proxy.openSession(target('/video.mp4?password=secret'));
    expect(session.url.toString(), isNot(contains('secret')));
    final partial = await get(session.url, range: 'bytes=3-5');
    expect(partial.$1, 206);
    expect(partial.$2.value('content-range'), 'bytes 3-5/10');
    expect(partial.$3, '345');
    final invalid = await get(session.url, range: 'bytes=99-');
    expect(invalid.$1, 416);
    expect(invalid.$2.value('content-range'), 'bytes */10');
    session.close();
    expect((await get(session.url)).$1, 404);
  });

  test('réécrit le HLS après redirection et relaie les segments', () async {
    final session = proxy.openSession(target('/redirect.m3u8'));
    final manifest = await get(session.url);
    expect(manifest.$1, 200);
    final lines = manifest.$3.split('\n');
    final key = RegExp(r'URI="([^"]+)"').firstMatch(lines[1])!.group(1)!;
    expect((await get(Uri.parse(key))).$3, '0123456789');
    expect((await get(Uri.parse(lines[2]), range: 'bytes=3-5')).$3, '345');
    expect(requests, contains('/hls/key|null'));
    expect(requests, contains('/hls/segment.ts|bytes=3-5'));
  });

  test('refuse un manifeste dangereux et une URL non enregistrée', () async {
    final session = proxy.openSession(target('/bad.m3u8'));
    expect((await get(session.url)).$1, 502);
    expect((await get(session.url.replace(path: '/not-a-token'))).$1, 404);
    expect(() => proxy.openSession(Uri.parse('file:///secret')),
        throwsArgumentError);
    final dash = proxy.openSession(target('/dash'));
    expect((await get(dash.url)).$1, 502);
    expect(
      () => proxy.openSession(
        Uri.parse('http://localhost:${session.url.port}/loop'),
      ),
      throwsArgumentError,
    );
  });

  test('reconnaît un manifeste sans extension et les sous-manifestes',
      () async {
    final session = proxy.openSession(target('/extensionless'));
    final master = await get(session.url);
    final child = Uri.parse(master.$3.split('\n')[1]);
    final manifest = await get(child);
    expect(manifest.$1, 200);
    expect(manifest.$3, contains('URI="http://127.0.0.1:'));
  });

  test('accepte HEAD et refuse les autres méthodes', () async {
    final session = proxy.openSession(target('/video.mp4'));
    final head = await client.openUrl('HEAD', session.url);
    final response = await head.close();
    expect(response.statusCode, 200);
    expect(await response.toList(), isEmpty);
    final post = await client.postUrl(session.url);
    final rejected = await post.close();
    expect(rejected.statusCode, 405);
    await rejected.drain<void>();
  });

  test('ne transmet pas les identifiants à une autre origine après redirection',
      () async {
    final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? authorization;
    other.listen((request) async {
      authorization = request.headers.value('authorization');
      request.response.write('ok');
      await request.response.close();
    });
    final redirect = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    redirect.listen((request) async {
      request.response.statusCode = 302;
      request.response.headers
          .set('location', 'http://127.0.0.1:${other.port}/video');
      await request.response.close();
    });
    try {
      final session = proxy.openSession(
        Uri.parse('http://127.0.0.1:${redirect.port}/video'),
        headers: {'Authorization': 'secret'},
      );
      expect((await get(session.url)).$3, 'ok');
      expect(authorization, isNull);
    } finally {
      await redirect.close(force: true);
      await other.close(force: true);
    }
  });
}
