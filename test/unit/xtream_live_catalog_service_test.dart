import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live loads streams and enriches them with category names', () async {
    final calls = <String>[];
    final service = XtreamLiveCatalogService(
      buildApiUrl: (base, script, params) => Uri.parse('$base/$script')
          .replace(queryParameters: params)
          .toString(),
      loadBytes: (name, key, url, {useFreshCache = true}) async {
        expect(key, 'https://example.test|user');
        expect(useFreshCache, isTrue);
        calls.add(Uri.parse(url).queryParameters['action']!);
        final body = name == 'live_cats'
            ? '[{"category_id":"1","category_name":"France"}]'
            : '[{"stream_id":42,"name":"Test","category_id":"1"}]';
        return Uint8List.fromList(utf8.encode(body));
      },
    );
    final channels = await service.live('https://example.test', 'user', 'pass');
    expect(calls, containsAll(['get_live_categories', 'get_live_streams']));
    expect(channels.single.name, 'Test');
    expect(channels.single.groupLabel, 'France');
    expect(channels.single.streamUrl, 'https://example.test/user/pass/42');
  });

  for (final series in [false, true]) {
    test('categories revalidate for ${series ? 'series' : 'vod'}', () async {
      final service = XtreamLiveCatalogService(
        buildApiUrl: (base, script, params) => Uri.parse('$base/$script')
            .replace(queryParameters: params)
            .toString(),
        loadBytes: (name, key, url, {useFreshCache = true}) async {
          expect(name, series ? 'series_cats' : 'vod_cats');
          expect(useFreshCache, isFalse);
          expect(
            Uri.parse(url).queryParameters['action'],
            series ? 'get_series_categories' : 'get_vod_categories',
          );
          return Uint8List.fromList(latin1.encode(
            '[{"category_id":"1","category_name":"Cinéma"},'
            '{"category_name":"ignored"},0]',
          ));
        },
      );
      final categories = await service.categories(
        'https://example.test',
        'user',
        'pass',
        series: series,
      );
      expect(categories.single.id, '1');
      expect(categories.single.name, 'Cinéma');
    });
  }
}
