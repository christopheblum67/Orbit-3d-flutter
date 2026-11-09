import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class _FakeTmdb extends TmdbService {
  final calls = <String>[];

  @override
  Future<List<TmdbRankEntry>> getRankings(
    String path, {
    int page = 1,
    required bool isTv,
  }) async {
    calls.add('$path:$isTv:$page');
    return [];
  }

  @override
  Future<List<TmdbRankEntry>> getMovieRecommendations(
    int tmdbId, {
    int page = 1,
  }) async {
    calls.add('recommendations:$tmdbId:$page');
    return [];
  }
}

void main() {
  test('public provider exports preserve TMDB paths and family parameters',
      () async {
    final directory = await Directory.systemTemp.createTemp('orbit-metadata-');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('metadata_cache');
    final service = _FakeTmdb();
    final container = ProviderContainer(
      overrides: [tmdbServiceProvider.overrideWithValue(service)],
    );
    addTearDown(() async {
      container.dispose();
      await service.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final movies = container.listen(flixPatrolMoviesProvider, (_, __) {});
    final shows = container.listen(flixPatrolTrendingTvProvider, (_, __) {});
    final recommendations = container.listen(
      tmdbMovieRecommendationsProvider(42),
      (_, __) {},
    );
    await container.read(flixPatrolMoviesProvider.future);
    await container.read(flixPatrolTrendingTvProvider.future);
    await container.read(tmdbMovieRecommendationsProvider(42).future);
    expect(service.calls, [
      '/movie/popular:false:1',
      '/trending/tv/week:true:1',
      'recommendations:42:1',
    ]);
    movies.close();
    shows.close();
    recommendations.close();
  });
}
