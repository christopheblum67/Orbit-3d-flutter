import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/xtream_radio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps only radio categories and excludes music TV', () async {
    final calls = <String>[];
    final service = XtreamRadioService(
      buildApiUrl: (base, script, params) => Uri.parse('$base/$script')
          .replace(queryParameters: params)
          .toString(),
      get: (url) async {
        final action = Uri.parse(url).queryParameters['action']!;
        calls.add(action);
        final data = action == 'get_live_categories'
            ? [
                {'category_id': '1', 'category_name': '|BE| RADIOS'},
                {'category_id': '2', 'category_name': '|FR| MUSIQUE TV'},
                {'category_id': '3', 'category_name': 'TV'},
              ]
            : [
                {'stream_id': 10, 'name': '|BE| Antipode', 'category_id': '1'},
                {'stream_id': 20, 'name': 'Music TV', 'category_id': '2'},
                {'stream_id': 30, 'name': 'TV', 'category_id': '3'},
              ];
        return Response<dynamic>(
            requestOptions: RequestOptions(path: url), data: data);
      },
    );
    final channels =
        await service.fetch('https://example.test', 'user', 'pass');
    expect(calls, ['get_live_categories', 'get_live_streams']);
    expect(channels.map((c) => c.name), ['|BE| Antipode']);
    expect(channels.first.streamUrl, 'https://example.test/user/pass/10');
  });

  test('does not silently accept an invalid streams response', () async {
    final service = XtreamRadioService(
      buildApiUrl: (base, script, params) => params['action']!,
      get: (url) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: url == 'get_live_categories'
            ? [
                {'category_id': '1', 'category_name': 'Radio'},
              ]
            : {'error': true},
      ),
    );
    await expectLater(
      service.fetch('https://example.test', 'user', 'pass'),
      throwsFormatException,
    );
  });

  test('keeps stations without category and excludes country TV', () async {
    final service = XtreamRadioService(
      buildApiUrl: (base, script, params) => params['action']!,
      get: (url) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: url == 'get_live_categories'
            ? [
                {'category_id': '1', 'category_name': 'TV'},
              ]
            : [
                {'stream_id': 3, 'name': 'Chaine', 'category_id': '1'},
                {'stream_id': 4, 'name': '|BE| ANTIPODE', 'category_id': null},
                {'stream_id': 5, 'name': '|FR| 100 HIT', 'category_id': ''},
              ],
      ),
    );
    final result = await service.fetch('https://example.test', 'user', 'pass');
    expect(result.map((c) => c.name), ['|BE| ANTIPODE', '|FR| 100 HIT']);
  });
}
