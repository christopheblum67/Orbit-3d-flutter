import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';
import 'package:orbit_3d_flutter/services/playlist_fetch_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches a playlist and revalidates its cached content', () async {
    final dir = await Directory.systemTemp.createTemp('playlist-service-');
    addTearDown(() => dir.delete(recursive: true));
    final requests = <Options>[];
    final service = PlaylistFetchService(
      cache: ConditionalPlaylistCache(directory: () async => dir),
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
  });
}
