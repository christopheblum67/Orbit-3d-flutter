import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/xtream_media_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads movie and series lists, enriching movies and syncing both',
      () async {
    final movieSync = Completer<void>();
    final seriesSync = Completer<void>();
    final calls = <String>[];
    final service = XtreamMediaCatalogService(
      buildApiUrl: (base, script, params) => Uri.parse('$base/$script')
          .replace(queryParameters: params)
          .toString(),
      loadBytes: (name, key, url, {useFreshCache = true}) async {
        expect(key, 'https://example.test|user');
        expect(useFreshCache, isTrue);
        calls.add(Uri.parse(url).queryParameters['action']!);
        final body = name == 'vod'
            ? '[{"stream_id":5,"name":"Film","category_id":"1"}]'
            : '[{"series_id":7,"name":"Série"}]';
        return Uint8List.fromList(utf8.encode(body));
      },
      loadVodCategoryNames: () async => {'1': 'Action'},
      syncMovies: (key, bytes, items) async {
        expect(items.single.title, 'Film');
        expect(items.single.genre, 'Action');
        movieSync.complete();
      },
      syncSeries: (key, bytes, items) async {
        expect(items.single.title, 'Série');
        seriesSync.complete();
      },
    );
    final movies = await service.movies('https://example.test', 'user', 'pass');
    final series = await service.series('https://example.test', 'user', 'pass');
    await Future.wait([movieSync.future, seriesSync.future]);
    expect(movies.single.streamId, '5');
    expect(series.single.id, '7');
    expect(calls, ['get_vod_streams', 'get_series']);
  });

  test('invalid catalogues fail without syncing', () async {
    var syncs = 0;
    final service = XtreamMediaCatalogService(
      buildApiUrl: (base, script, params) => base,
      loadBytes: (name, key, url, {useFreshCache = true}) async =>
          Uint8List.fromList(utf8.encode('{"error":"unavailable"}')),
      loadVodCategoryNames: () async => {},
      syncMovies: (key, bytes, items) async => syncs++,
      syncSeries: (key, bytes, items) async => syncs++,
    );
    await expectLater(
      service.movies('https://example.test', 'user', 'pass'),
      throwsFormatException,
    );
    await expectLater(
      service.series('https://example.test', 'user', 'pass'),
      throwsFormatException,
    );
    expect(syncs, 0);
  });
}
