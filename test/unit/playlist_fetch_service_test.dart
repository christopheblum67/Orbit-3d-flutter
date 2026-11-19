import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/catalog_retry_policy.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';
import 'package:orbit_3d_flutter/services/playlist_fetch_service.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches a playlist and revalidates its cached content', () async {
    final dir = await Directory.systemTemp.createTemp('playlist-service-');
    addTearDown(() => dir.delete(recursive: true));
    final requests = <Options>[];
    final logs = <String>[];
    final service = PlaylistFetchService(
      cache: ConditionalPlaylistCache(directory: () async => dir),
      log: logs.add,
      get: (url, {options}) async {
        requests.add(options!);
        final first = requests.length == 1;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          statusCode: first ? 200 : 304,
          data: first
              ? '#EXTM3U\n#EXTINF:-1 group-title="France",Test\n'
                  'https://example.test/live\n'
              : null,
          headers: Headers.fromMap(first
              ? {
                  'etag': ['"v1"']
                }
              : {}),
        );
      },
    );
    expect(
      (await service.fetch('https://example.test/playlist'))
          .channels
          .single
          .name,
      'Test',
    );
    expect(
      (await service.fetch('https://example.test/playlist'))
          .channels
          .single
          .name,
      'Test',
    );
    expect(requests.first.responseType, ResponseType.plain);
    expect(requests.first.validateStatus!(304), isTrue);
    expect(requests.last.headers, {'If-None-Match': '"v1"'});
    expect(logs, contains('M3U response status=200'));
    expect(logs, contains('M3U response status=304'));
    expect(logs.where((line) => line.startsWith('M3U body ')), hasLength(2));
    expect(
      logs.where((line) => line.startsWith('M3U body ')),
      everyElement(contains('header=true extinf=1 html=false')),
    );
    expect(logs.join('\n'), isNot(contains('example.test')));
    expect(logs.join('\n'), isNot(contains('Test')));
  });

  for (final example in [
    (
      name: 'repeated cache-control',
      responseHeaders: {
        'etag': ['"v1"'],
        'cache-control': ['max-age=60', 'no-store'],
      },
    ),
    (
      name: 'repeated vary',
      responseHeaders: {
        'etag': ['"v1"'],
        'vary': ['Accept', 'Accept-Encoding'],
      },
    ),
    (
      name: 'ambiguous etag',
      responseHeaders: {
        'etag': ['"v1"', '"v2"'],
      },
    ),
    (
      name: 'ambiguous last-modified',
      responseHeaders: {
        'last-modified': [
          'Wed, 21 Oct 2015 07:28:00 GMT',
          'Thu, 22 Oct 2015 07:28:00 GMT',
        ],
      },
    ),
  ]) {
    test('handles ${example.name} without caching an unsafe response',
        () async {
      final dir = await Directory.systemTemp.createTemp('playlist-service-');
      addTearDown(() => dir.delete(recursive: true));
      final requests = <Options>[];
      final service = PlaylistFetchService(
        cache: ConditionalPlaylistCache(directory: () async => dir),
        log: (_) {},
        get: (url, {options}) async {
          requests.add(options!);
          return Response<dynamic>(
            requestOptions: RequestOptions(path: url),
            statusCode: 200,
            data: '#EXTM3U\n#EXTINF:-1,Chaîne\nhttps://example.test/live\n',
            headers: Headers.fromMap(example.responseHeaders),
          );
        },
      );
      expect((await service.fetch('https://example.test/playlist')).channels,
          hasLength(1));
      expect((await service.fetch('https://example.test/playlist')).channels,
          hasLength(1));
      expect(requests, hasLength(2));
      expect(requests.last.headers, isEmpty);
    });
  }

  test('diagnoses an HTML response without logging its contents', () async {
    final dir = await Directory.systemTemp.createTemp('playlist-service-');
    addTearDown(() => dir.delete(recursive: true));
    final logs = <String>[];
    const body = '<!DOCTYPE html><html>private response</html>';
    final service = PlaylistFetchService(
      cache: ConditionalPlaylistCache(directory: () async => dir),
      log: logs.add,
      get: (url, {options}) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        statusCode: 200,
        data: body,
      ),
    );

    final playlist = await service.fetch('https://example.test/playlist');
    expect(playlist.channels, isEmpty);
    expect(
        logs,
        contains(
            'M3U body chars=${body.length} header=false extinf=0 html=true'));
    expect(logs.join('\n'), isNot(contains('private response')));
  });

  test('empty HTTP response is an actionable failure and is not cached',
      () async {
    final dir = await Directory.systemTemp.createTemp('playlist-service-');
    addTearDown(() => dir.delete(recursive: true));
    final headers = <Map<String, dynamic>?>[];
    final service = PlaylistFetchService(
      cache: ConditionalPlaylistCache(directory: () async => dir),
      log: (_) {},
      get: (url, {options}) async {
        headers.add(options?.headers);
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          statusCode: 200,
          data: headers.length == 1
              ? ' '
              : '#EXTM3U\n#EXTINF:-1,Chaîne\nhttps://example.test/live\n',
          headers: Headers.fromMap({
            'etag': ['"v1"'],
          }),
        );
      },
    );
    const error = EmptyPlaylistException();
    await expectLater(
      service.fetch('https://example.test/playlist'),
      throwsA(isA<EmptyPlaylistException>()),
    );
    expect(userFriendlyError(error), contains('playlist M3U reçue est vide'));
    expect(catalogRetryUnlessRateLimited(0, error), isNull);
    final playlist = await service.fetch('https://example.test/playlist');
    expect(playlist.channels, hasLength(1));
    expect(headers.last, isEmpty);
  });

  test('retries unconditionally when a cached empty playlist gets HTTP 304',
      () async {
    final dir = await Directory.systemTemp.createTemp('playlist-service-');
    addTearDown(() => dir.delete(recursive: true));
    final cache = ConditionalPlaylistCache(directory: () async => dir);
    const url = 'https://example.test/playlist';
    await cache.fetch(
      resource: url,
      request: (_) async => const PlaylistResponse(
        statusCode: 200,
        body: '',
        etag: '"old"',
      ),
      parse: (body) => body,
    );
    final headers = <Map<String, dynamic>?>[];
    final service = PlaylistFetchService(
      cache: cache,
      log: (_) {},
      get: (url, {options}) async {
        headers.add(options?.headers);
        final first = headers.length == 1;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          statusCode: first ? 304 : 200,
          data: first
              ? null
              : '#EXTM3U\n#EXTINF:-1,Chaîne\nhttps://example.test/live\n',
        );
      },
    );
    final playlist = await service.fetch(url);
    expect(playlist.channels, hasLength(1));
    expect(headers.first, {'If-None-Match': '"old"'});
    expect(headers.last, isEmpty);
  });
}
