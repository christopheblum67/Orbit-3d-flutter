import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/xtream_subtitle_service.dart';

void main() {
  test('uses the episode id for series and preserves declared subtitles',
      () async {
    late Map<String, String> params;
    final service = XtreamSubtitleService(
      activeSub: () async => {
        'type': 'xtream',
        'baseUrl': 'https://example.test',
        'username': 'u',
        'password': 'p',
      },
      buildApiUrl: (base, script, values) {
        params = values;
        return base;
      },
      get: (url) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: {
          'info': {
            'tmdb_id': '42',
            'subtitles': ['123_fr.srt'],
          },
        },
      ),
    );
    final result = await service.discoverSubtitles(
      'series-1',
      isSeries: true,
      streamId: '123',
    );
    expect(params['action'], 'get_series_info');
    expect(params['series_id'], 'series-1');
    expect(result.guessed, isFalse);
    expect(result.tracks.single.url, 'https://example.test/123_fr.srt');
  });

  test('does not request subtitles without a content id or Xtream account',
      () async {
    var calls = 0;
    final service = XtreamSubtitleService(
      activeSub: () async => {'type': 'm3u'},
      buildApiUrl: (base, script, params) => base,
      get: (url) async {
        calls++;
        return Response<dynamic>(requestOptions: RequestOptions(path: url));
      },
    );
    expect(
        (await service.discoverSubtitles('', isSeries: false)).tracks, isEmpty);
    expect((await service.discoverSubtitles('1', isSeries: false)).tracks,
        isEmpty);
    expect(calls, 0);
  });
}
