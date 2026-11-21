import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/xtream_movie_detail_service.dart';

class _PosterApi extends ApiService {
  final requests = <Uri>[];

  @override
  Future<Response<dynamic>> get(String url) async {
    requests.add(Uri.parse(url));
    return Response(
      requestOptions: RequestOptions(path: url),
      data: {
        'info': {'movie_image': 'https://images.example/poster.jpg'}
      },
    );
  }
}

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

  test(
      'matches only a compatible M3U playlist and stream from the same account',
      () {
    final sub = Subscription(
      id: 'm3u',
      name: 'Test',
      type: SubscriptionType.m3u,
      m3uUrl: 'https://panel.example/iptv/get.php?username=user&password=pass',
      createdAt: DateTime(2020),
    );
    final movie = original.copyWith(
      id: 'm3u-1',
      streamId: 'https://panel.example/iptv/movie/user/pass/42.mkv',
    );
    final lookup = xtreamMovieLookup(sub, movie);
    expect(lookup?.movieId, '42');
    expect(Uri.parse(lookup!.baseUrl).path, '/iptv');
    expect(lookup.username, 'user');
    expect(lookup.password, 'pass');
    expect(
      xtreamMovieLookup(
        sub,
        movie.copyWith(
            streamId: 'https://other.example/iptv/movie/user/pass/42.mkv'),
      ),
      isNull,
    );
    expect(
      xtreamMovieLookup(
        sub,
        movie.copyWith(
            streamId: 'https://panel.example/iptv/movie/user/other/42.mkv'),
      ),
      isNull,
    );
    expect(
      xtreamMovieLookup(
        sub.copyWith(m3uUrl: '${sub.m3uUrl}&username=other'),
        movie,
      ),
      isNull,
    );
    expect(
      xtreamMovieLookup(
          sub.copyWith(m3uUrl: 'https://panel.example/list.m3u'), movie),
      isNull,
    );
  });

  test('uses the active Xtream movie ID without changing the stream', () {
    final sub = Subscription(
      id: 'xtream',
      name: 'Test',
      type: SubscriptionType.xtream,
      baseUrl: 'https://panel.example',
      username: 'user',
      password: 'pass',
      createdAt: DateTime(2020),
    );
    expect(xtreamMovieLookup(sub, original)?.movieId, original.id);
    expect(xtreamMovieLookup(sub.copyWith(username: ''), original), isNull);
  });

  test('fetches a matching M3U film by its Xtream ID without changing its URL',
      () async {
    final api = _PosterApi();
    final sub = Subscription(
      id: 'm3u',
      name: 'Test',
      type: SubscriptionType.m3u,
      m3uUrl: 'https://panel.example/get.php?username=user&password=pass',
      createdAt: DateTime(2020),
    );
    final movie = original.copyWith(
      id: 'm3u-1',
      streamId: 'https://panel.example/movie/user/pass/42.mkv',
    );
    expect(await api.fetchMoviePosterFromXtream(movie, sub),
        'https://images.example/poster.jpg');
    expect(api.requests.single.path, '/player_api.php');
    expect(api.requests.single.queryParameters['action'], 'get_vod_info');
    expect(api.requests.single.queryParameters['vod_id'], '42');
    expect(movie.streamId, 'https://panel.example/movie/user/pass/42.mkv');

    expect(
      await api.fetchMoviePosterFromXtream(
        movie.copyWith(streamId: 'https://other.example/movie/user/pass/42'),
        sub,
      ),
      isNull,
    );
    expect(api.requests, hasLength(1));
  });
}
