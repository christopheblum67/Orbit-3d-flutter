import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ConditionalPlaylistCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('orbit-playlist-test-');
    cache = ConditionalPlaylistCache(directory: () async => directory);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<String> fetch(
    String url,
    Future<PlaylistResponse> Function(Map<String, String>) request,
  ) =>
      cache.fetch(
          resource: url,
          request: request,
          parse: (body) {
            if (!body.startsWith('#EXTM3U')) throw const FormatException();
            return body;
          });

  test('sends ETag and reuses the validated body on 304', () async {
    await fetch('https://example.test/a', (headers) async {
      expect(headers, isEmpty);
      return const PlaylistResponse(
        statusCode: 200,
        body: '#EXTM3U\none',
        etag: '"v1"',
        lastModified: 'yesterday',
      );
    });
    final result = await fetch('https://example.test/a', (headers) async {
      expect(headers, {'If-None-Match': '"v1"'});
      return const PlaylistResponse(statusCode: 304);
    });
    expect(result, '#EXTM3U\none');
  });

  test('uses Last-Modified and isolates resources', () async {
    await fetch(
        'https://example.test/a',
        (_) async => const PlaylistResponse(
              statusCode: 200,
              body: '#EXTM3U\na',
              lastModified: 'yesterday',
            ));
    await fetch('https://example.test/b', (headers) async {
      expect(headers, isEmpty);
      return const PlaylistResponse(statusCode: 200, body: '#EXTM3U\nb');
    });
    final result = await fetch('https://example.test/a', (headers) async {
      expect(headers, {'If-Modified-Since': 'yesterday'});
      return const PlaylistResponse(statusCode: 304);
    });
    expect(result, '#EXTM3U\na');
  });

  test('does not send validators after corruption or missing body', () async {
    await fetch(
        'https://example.test/a',
        (_) async => const PlaylistResponse(
              statusCode: 200,
              body: '#EXTM3U\na',
              etag: '"a"',
            ));
    final body = directory.listSync().whereType<File>().singleWhere(
          (file) => file.path.endsWith('.body'),
        );
    await body.writeAsString('corrupted');
    final result = await fetch('https://example.test/a', (headers) async {
      expect(headers, isEmpty);
      return const PlaylistResponse(
        statusCode: 200,
        body: '#EXTM3U\nnew',
        etag: '"new"',
      );
    });
    expect(result, '#EXTM3U\nnew');
    await body.delete();
    await fetch('https://example.test/a', (headers) async {
      expect(headers, isEmpty);
      return const PlaylistResponse(statusCode: 200, body: '#EXTM3U\nagain');
    });
  });

  test('retries an unexpected 304 without validators and rejects another',
      () async {
    var calls = 0;
    await expectLater(
      fetch('https://example.test/a', (headers) async {
        expect(headers, isEmpty);
        calls++;
        return const PlaylistResponse(statusCode: 304);
      }),
      throwsStateError,
    );
    expect(calls, 2);
  });

  test('does not replace a good cache with an invalid response', () async {
    await fetch(
        'https://example.test/a',
        (_) async => const PlaylistResponse(
              statusCode: 200,
              body: '#EXTM3U\ngood',
              etag: '"v1"',
            ));
    await expectLater(
      fetch(
          'https://example.test/a',
          (_) async => const PlaylistResponse(
                statusCode: 200,
                body: 'invalid',
                etag: '"v2"',
              )),
      throwsFormatException,
    );
    final result = await fetch('https://example.test/a', (headers) async {
      expect(headers, {'If-None-Match': '"v1"'});
      return const PlaylistResponse(statusCode: 304);
    });
    expect(result, '#EXTM3U\ngood');
  });

  test('does not retain responses without validators or marked no-store',
      () async {
    for (final response in [
      const PlaylistResponse(statusCode: 200, body: '#EXTM3U\none'),
      const PlaylistResponse(
        statusCode: 200,
        body: '#EXTM3U\ntwo',
        etag: '"v2"',
        cacheControl: 'no-store',
      ),
      const PlaylistResponse(
        statusCode: 200,
        body: '#EXTM3U\nthree',
        etag: '"v3"',
        vary: 'Authorization',
      ),
    ]) {
      await fetch('https://example.test/a', (_) async => response);
      expect(directory.listSync(), isEmpty);
    }
  });

  test('invalid cached content on 304 triggers an unconditional request',
      () async {
    await cache.fetch(
      resource: 'https://example.test/a',
      request: (_) async => const PlaylistResponse(
        statusCode: 200,
        body: 'invalid',
        etag: '"v1"',
      ),
      parse: (body) => body,
    );
    final requests = <Map<String, String>>[];
    final result = await fetch('https://example.test/a', (headers) async {
      requests.add(headers);
      if (requests.length == 1) {
        return const PlaylistResponse(statusCode: 304);
      }
      return const PlaylistResponse(statusCode: 200, body: '#EXTM3U\nnew');
    });

    expect(result, '#EXTM3U\nnew');
    expect(requests, [
      {'If-None-Match': '"v1"'},
      <String, String>{},
    ]);
  });

  test('an asynchronous parse failure on 304 retries without validators',
      () async {
    await cache.fetch(
      resource: 'https://example.test/async',
      request: (_) async => const PlaylistResponse(
        statusCode: 200,
        body: 'invalid',
        etag: '"v1"',
      ),
      parse: (body) => body,
    );
    final requests = <Map<String, String>>[];
    final result = await cache.fetch<String>(
      resource: 'https://example.test/async',
      request: (headers) async {
        requests.add(headers);
        return requests.length == 1
            ? const PlaylistResponse(statusCode: 304)
            : const PlaylistResponse(statusCode: 200, body: '#EXTM3U\nnew');
      },
      parse: (body) async {
        if (!body.startsWith('#EXTM3U')) throw const FormatException();
        return body;
      },
    );
    expect(result, '#EXTM3U\nnew');
    expect(requests, [
      {'If-None-Match': '"v1"'},
      <String, String>{},
    ]);
  });

  test('a 304 with no-store clears the previously saved body', () async {
    await fetch(
        'https://example.test/a',
        (_) async => const PlaylistResponse(
              statusCode: 200,
              body: '#EXTM3U\none',
              etag: '"v1"',
            ));
    await fetch(
        'https://example.test/a',
        (_) async => const PlaylistResponse(
              statusCode: 304,
              cacheControl: 'no-store',
            ));
    expect(directory.listSync(), isEmpty);
  });

  test('a new 200 replaces both body and validator; clear removes them',
      () async {
    await fetch(
        'https://example.test/a',
        (_) async => const PlaylistResponse(
              statusCode: 200,
              body: '#EXTM3U\none',
              etag: '"v1"',
            ));
    await fetch('https://example.test/a', (headers) async {
      expect(headers, {'If-None-Match': '"v1"'});
      return const PlaylistResponse(
        statusCode: 200,
        body: '#EXTM3U\ntwo',
        etag: '"v2"',
      );
    });
    final result = await fetch('https://example.test/a', (headers) async {
      expect(headers, {'If-None-Match': '"v2"'});
      return const PlaylistResponse(statusCode: 304);
    });
    expect(result, '#EXTM3U\ntwo');
    await cache.clear();
    expect(directory.listSync(), isEmpty);
  });

  test('ApiService sends a real conditional HTTP request', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String?>[];
    server.listen((request) async {
      seen.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      if (seen.length == 1) {
        request.response.headers.set(HttpHeaders.etagHeader, '"v1"');
        request.response.write(
          '#EXTM3U\n#EXTINF:-1 group-title="France",Test\n'
          'https://example.test/live\n',
        );
      } else {
        request.response.statusCode = HttpStatus.notModified;
      }
      await request.response.close();
    });
    final api = ApiService(playlistCache: cache);
    final url = 'http://${server.address.address}:${server.port}/playlist';
    await HttpOverrides.runWithHttpOverrides(() async {
      expect((await api.fetchM3uPlaylist(url)).channels.single.name, 'Test');
      expect((await api.fetchM3uPlaylist(url)).channels.single.name, 'Test');
    }, _RealHttpOverrides());
    expect(seen, [null, '"v1"']);
  });

  test('ApiService accepts repeated cache-control headers over HTTP', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String?>[];
    server.listen((request) async {
      seen.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      request.response.headers
          .add(HttpHeaders.cacheControlHeader, 'max-age=60');
      request.response.headers.add(HttpHeaders.cacheControlHeader, 'no-store');
      request.response.headers.set(HttpHeaders.etagHeader, '"v1"');
      request.response.write(
        '#EXTM3U\n#EXTINF:-1 group-title="France",Test\n'
        'https://example.test/live\n',
      );
      await request.response.close();
    });
    final api = ApiService(playlistCache: cache);
    final url = 'http://${server.address.address}:${server.port}/playlist';
    await HttpOverrides.runWithHttpOverrides(() async {
      expect((await api.fetchM3uPlaylist(url)).channels.single.name, 'Test');
      expect((await api.fetchM3uPlaylist(url)).channels.single.name, 'Test');
    }, _RealHttpOverrides());
    expect(seen, [null, null]);
  });
}
