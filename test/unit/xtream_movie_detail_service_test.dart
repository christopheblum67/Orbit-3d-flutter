import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/services/xtream_movie_detail_service.dart';

void main() {
  final original = Movie(
    id: '42',
    title: 'Film',
    description: 'Original',
    posterUrl: 'old.jpg',
    year: 2000,
    genre: 'Drama',
    director: 'Old director',
    rating: 5,
    pegi: '',
    streamId: '42',
    containerExtension: 'mkv',
    categoryId: 'cat',
  );
  test('preserves stream fields and maps Xtream details and credits', () async {
    final actions = <Map<String, String>>[];
    final service = XtreamMovieDetailService(
      buildApiUrl: (base, script, params) {
        actions.add(params);
        return base;
      },
      get: (url) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: {
          'info': {
            'releaseDate': '2024-01-02',
            'plot': 'Synopsis',
            'genre': ' Action ',
            'rating': '7.5/10',
            'cast': ['Actor'],
          },
        },
      ),
    );
    final detail = await service.detail(original, 'host', 'user', 'pass');
    final credits = await service.credits('42', 'host', 'user', 'pass');
    expect(detail.year, 2024);
    expect(detail.description, 'Synopsis');
    expect(detail.genre, 'Action');
    expect(detail.rating, 7.51);
    expect(detail.posterUrl, 'old.jpg');
    expect(detail.streamId, '42');
    expect(detail.containerExtension, 'mkv');
    expect(detail.categoryId, 'cat');
    expect(credits!.cast.single.name, 'Actor');
    expect(actions.map((a) => a['action']), ['get_vod_info', 'get_vod_info']);
    expect(actions.map((a) => a['vod_id']), ['42', '42']);
  });

  test('retains the original film for a non-map response', () async {
    final service = XtreamMovieDetailService(
      buildApiUrl: (base, script, params) => base,
      get: (url) async => Response<dynamic>(
          requestOptions: RequestOptions(path: url), data: []),
    );
    expect(
        await service.detail(original, 'host', 'user', 'pass'), same(original));
    expect(await service.credits('42', 'host', 'user', 'pass'), isNull);
  });
}
