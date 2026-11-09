import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/xtream_series_detail_service.dart';

void main() {
  test('requests bytes and maps seasons, episodes and UTF-8 metadata',
      () async {
    late Map<String, String> parameters;
    Options? requestOptions;
    final service = XtreamSeriesDetailService(
      buildApiUrl: (base, script, params) {
        parameters = params;
        return '$base/$script';
      },
      get: (url, {options}) async {
        requestOptions = options;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          data: utf8.encode(jsonEncode({
            'info': {'name': 'Série', 'plot': 'Résumé'},
            'episodes': {
              '2': [
                {
                  'id': '123',
                  'title': 'Épisode',
                  'episode_num': 1,
                  'container_extension': 'mkv'
                },
              ],
            },
          })),
        );
      },
    );
    final series = await service.fetch('42', 'https://example.test', 'u', 'p');
    expect(parameters['action'], 'get_series_info');
    expect(parameters['series_id'], '42');
    expect(requestOptions!.responseType, ResponseType.bytes);
    expect(series.id, '42');
    expect(series.title, 'Série');
    expect(series.description, 'Résumé');
    expect(series.episodes.single.season, 2);
    expect(series.episodes.single.title, 'Épisode');
    expect(series.episodes.single.streamUrl,
        'https://example.test/series/u/p/123.mkv');
  });

  test('decodes Latin-1 and accepts a list response', () async {
    final service = XtreamSeriesDetailService(
      buildApiUrl: (base, script, params) => base,
      get: (url, {options}) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: latin1.encode(jsonEncode([
          {
            'info': {'name': 'Été'}
          }
        ])),
      ),
    );
    final series = await service.fetch('1', 'https://example.test', 'u', 'p');
    expect(series.title, 'Été');
    expect(series.episodes, isEmpty);
  });

  test('preserves explicit failures for empty and invalid responses', () async {
    for (final data in [<dynamic>[], 'invalid']) {
      final service = XtreamSeriesDetailService(
        buildApiUrl: (base, script, params) => base,
        get: (url, {options}) async => Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          data: data,
        ),
      );
      await expectLater(
        service.fetch('1', 'https://example.test', 'u', 'p'),
        throwsA(isA<StreamNetworkException>()),
      );
    }
  });
}
