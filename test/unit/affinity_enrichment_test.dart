import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class _Storage extends StorageService {
  @override
  dynamic getSetting(String key) => null;
}

class _Filters extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(
        subscriptionId: 'sub',
        hiddenVodCategoryIds: {'hidden'},
      );
}

class _Tmdb implements TmdbService {
  final List<String> calls = [];

  @override
  bool get hasApiKey => true;
  @override
  TmdbRankEntry? peekMovieLight(String title, {int? year}) => null;
  @override
  TmdbRankEntry? peekTvLight(String title, {int? year}) => null;
  @override
  Future<TmdbRankEntry?> searchMovieLightVerified(
      String title, int year) async {
    calls.add('movie:$title');
    return TmdbRankEntry(
      tmdbId: calls.length,
      title: title,
      posterPath: '',
      year: year,
      rating: 8,
      voteCount: 100,
      genreIds: const [28],
    );
  }

  @override
  Future<TmdbRankEntry?> searchTvLightVerified(String title, int year) async {
    calls.add('series:$title');
    return TmdbRankEntry(
      tmdbId: calls.length + 100,
      title: title,
      posterPath: '',
      year: year,
      isTv: true,
      rating: 8,
      voteCount: 100,
      genreIds: const [28],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowTmdb extends _Tmdb {
  final result = Completer<TmdbRankEntry?>();
  @override
  Future<TmdbRankEntry?> searchMovieLightVerified(String title, int year) {
    calls.add('movie:$title');
    return result.future;
  }
}

class _NoKeyTmdb extends _Tmdb {
  @override
  bool get hasApiKey => false;
}

Movie _movie(String id,
        {String genre = 'Recently added',
        int year = 2024,
        String category = ''}) =>
    Movie(
      id: id,
      title: id,
      description: '',
      posterUrl: '',
      year: year,
      genre: genre,
      director: '',
      rating: 7,
      pegi: '',
      streamId: '',
      categoryId: category,
    );

Series _series(String id, {String genre = 'Recently added'}) => Series(
      id: id,
      title: id,
      description: '',
      coverUrl: '',
      year: 2024,
      genre: genre,
      director: '',
      rating: 7,
      pegi: '',
      episodes: const [],
    );

void main() {
  test('verified TMDB selection rejects wrong and ambiguous identities', () {
    Map<String, dynamic> raw(int id, String title, String year) => {
          'id': id,
          'title': title,
          'release_date': '$year-01-01',
        };
    final other = raw(1, 'Another', '2024');
    final exact = raw(2, 'The Film', '2024');
    expect(
      TmdbService.selectVerifiedLightResult(
        [other, exact],
        'The Film [1080p]',
        2024,
        isTv: false,
      )?['id'],
      2,
    );
    expect(
      TmdbService.selectVerifiedLightResult(
        [exact, raw(3, 'The Film', '2024')],
        'The Film',
        2024,
        isTv: false,
      ),
      isNull,
    );
    expect(
      TmdbService.selectVerifiedLightResult(
        [exact],
        'The Film',
        2023,
        isTv: false,
      ),
      isNull,
    );
    expect(
      TmdbService.selectVerifiedLightResult(
        [raw(4, '[HD]', '2024')],
        '[4K]',
        2024,
        isTv: false,
      ),
      isNull,
    );
  });

  test(
      'background enrichment is bounded, skips known genres and advances on return',
      () async {
    final tmdb = _Tmdb();
    final profile = UserProfile(
      id: 'one',
      firstName: 'One',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: ['Action'],
    );
    final movies = [
      _movie('hidden', category: 'hidden'),
      _movie('no-year', year: 0),
      _movie('known', genre: 'Action'),
      for (var i = 0; i < 12; i++) _movie('movie$i'),
    ];
    final series = [for (var i = 0; i < 11; i++) _series('series$i')];
    final container = ProviderContainer(overrides: [
      currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
      moviesProvider.overrideWith((ref) async => movies),
      seriesProvider.overrideWith((ref) async => series),
      vodCategoryFilterProvider.overrideWith(_Filters.new),
      tmdbAffinityServiceProvider.overrideWithValue(tmdb),
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(_Storage()),
      favoritesProvider.overrideWithBuild((ref, notifier) => {}),
      recommendationTitlesProvider.overrideWith((ref) => {}),
      flixPatrolMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTvProvider.overrideWith((ref) async => []),
      flixPatrolTrendingMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTrendingTvProvider.overrideWith((ref) async => []),
      flixPatrolTopRatedMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTopRatedTvProvider.overrideWith((ref) async => []),
    ]);
    addTearDown(container.dispose);
    await Future.wait([
      container.read(moviesProvider.future),
      container.read(seriesProvider.future),
    ]);
    final before = await container.read(matchmakingTabProvider('one').future);
    final oldScore = before.movies
        .singleWhere((entry) => entry.reco.id == 'movie0')
        .affinity;
    final sub =
        container.listen(affinityBackgroundEnrichmentProvider, (_, __) {});
    await container.read(affinityBackgroundEnrichmentProvider.future);
    expect(tmdb.calls, hasLength(20));
    expect(tmdb.calls, isNot(contains('movie:hidden')));
    expect(tmdb.calls, isNot(contains('movie:no-year')));
    expect(tmdb.calls, isNot(contains('movie:known')));
    expect(container.read(affinityMetadataProvider), hasLength(20));
    expect(
        container.read(
            rankingGenresProvider)[(title: 'movie0', year: 2024, isTv: false)],
        'Action');
    final after = await container.read(matchmakingTabProvider('one').future);
    expect(
      after.movies.singleWhere((entry) => entry.reco.id == 'movie0').affinity,
      greaterThan(oldScore),
    );
    sub.close();
    await container.pump();
    final next =
        container.listen(affinityBackgroundEnrichmentProvider, (_, __) {});
    await container.read(affinityBackgroundEnrichmentProvider.future);
    expect(tmdb.calls, hasLength(23));
    expect(tmdb.calls.toSet(), hasLength(23));
    next.close();
  });

  test('leaving matchmaking stops the background queue', () async {
    final tmdb = _SlowTmdb();
    final profile = UserProfile(
      id: 'one',
      firstName: 'One',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: ['Action'],
    );
    final container = ProviderContainer(overrides: [
      currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
      moviesProvider
          .overrideWith((ref) async => [_movie('one'), _movie('two')]),
      seriesProvider.overrideWith((ref) async => []),
      vodCategoryFilterProvider.overrideWith(_Filters.new),
      tmdbAffinityServiceProvider.overrideWithValue(tmdb),
      rankingMetadataProvider.overrideWith((ref) => {}),
    ]);
    addTearDown(container.dispose);
    await container.read(moviesProvider.future);
    await container.read(seriesProvider.future);
    final sub =
        container.listen(affinityBackgroundEnrichmentProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(tmdb.calls, ['movie:one']);
    sub.close();
    await container.pump();
    tmdb.result.complete(const TmdbRankEntry(
      tmdbId: 1,
      title: 'one',
      posterPath: '',
      year: 2024,
      genreIds: [28],
    ));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(tmdb.calls, ['movie:one']);
    expect(container.read(affinityMetadataProvider), isEmpty);
  });

  test('background enrichment does not request metadata without a key',
      () async {
    final tmdb = _NoKeyTmdb();
    final profile = UserProfile(
      id: 'one',
      firstName: 'One',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: ['Action'],
    );
    final container = ProviderContainer(overrides: [
      currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
      moviesProvider.overrideWith((ref) async => [_movie('one')]),
      seriesProvider.overrideWith((ref) async => []),
      vodCategoryFilterProvider.overrideWith(_Filters.new),
      tmdbAffinityServiceProvider.overrideWithValue(tmdb),
    ]);
    addTearDown(container.dispose);
    await container.read(moviesProvider.future);
    final sub =
        container.listen(affinityBackgroundEnrichmentProvider, (_, __) {});
    await container.read(affinityBackgroundEnrichmentProvider.future);
    expect(tmdb.calls, isEmpty);
    sub.close();
  });

  test('solo and group top 200 retain better voted equal-affinity titles',
      () async {
    final tmdb = _Tmdb();
    UserProfile profile(String id) => UserProfile(
          id: id,
          firstName: id,
          dateOfBirth: DateTime(1990),
          gender: '',
          favoriteGenres: ['Action'],
        );
    final one = profile('one');
    final two = profile('two');
    final movies = [
      for (var i = 0; i < 200; i++) _movie('A$i', genre: 'Action'),
      _movie('ZBest', genre: 'Action'),
    ];
    final series = [
      for (var i = 0; i < 200; i++) _series('A$i', genre: 'Action'),
      _series('ZBest', genre: 'Action'),
    ];
    final metadata = <RankingGenreKey, TmdbRankEntry>{
      for (final isTv in [false, true])
        (title: 'zbest', year: 2024, isTv: isTv): TmdbRankEntry(
          tmdbId: isTv ? 2 : 1,
          title: 'ZBest',
          posterPath: '',
          year: 2024,
          isTv: isTv,
          rating: 8,
          voteCount: 1000,
        ),
    };
    final container = ProviderContainer(overrides: [
      currentProfileProvider.overrideWithBuild((ref, notifier) => one),
      profilesProvider.overrideWith((ref) async => [one, two]),
      moviesProvider.overrideWith((ref) async => movies),
      seriesProvider.overrideWith((ref) async => series),
      vodCategoryFilterProvider.overrideWith(_Filters.new),
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(_Storage()),
      favoritesProvider.overrideWithBuild((ref, notifier) => {}),
      recommendationTitlesProvider.overrideWith((ref) => {}),
      rankingGenresProvider.overrideWith((ref) => {}),
      rankingMetadataProvider.overrideWith((ref) => metadata),
      tmdbAffinityServiceProvider.overrideWithValue(tmdb),
    ]);
    addTearDown(container.dispose);
    await Future.wait([
      container.read(moviesProvider.future),
      container.read(seriesProvider.future),
      container.read(profilesProvider.future),
    ]);
    final solo = await container.read(matchmakingTabProvider('one').future);
    final group =
        await container.read(matchmakingGroupTabProvider('one|two').future);
    expect(solo.movies, hasLength(200));
    expect(solo.series, hasLength(200));
    expect(group.movies, hasLength(200));
    expect(group.series, hasLength(200));
    expect(solo.movies.first.reco.id, 'ZBest');
    expect(solo.series.first.reco.id, 'ZBest');
    expect(group.movies.first.reco.id, 'ZBest');
    expect(group.series.first.reco.id, 'ZBest');
  });

  test('quality breaks ties between equal displayed percentages', () async {
    UserProfile profile(String id) => UserProfile(
          id: id,
          firstName: id,
          dateOfBirth: DateTime(1990),
          gender: '',
          favoriteGenres: ['Action', 'Comedy', 'Drama'],
        );
    final one = profile('one');
    final two = profile('two');
    final movies = [
      _movie('A', genre: 'Action, Comedy, Drama, Horror, War, Romance, Crime'),
      _movie('B', genre: 'Action, Comedy, Horror, War'),
    ];
    const metadata = <RankingGenreKey, TmdbRankEntry>{
      (title: 'b', year: 2024, isTv: false): TmdbRankEntry(
        tmdbId: 1,
        title: 'B',
        posterPath: '',
        year: 2024,
        rating: 8,
        voteCount: 1000,
      ),
    };
    final container = ProviderContainer(overrides: [
      currentProfileProvider.overrideWithBuild((ref, notifier) => one),
      profilesProvider.overrideWith((ref) async => [one, two]),
      moviesProvider.overrideWith((ref) async => movies),
      seriesProvider.overrideWith((ref) async => []),
      vodCategoryFilterProvider.overrideWith(_Filters.new),
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(_Storage()),
      favoritesProvider.overrideWithBuild((ref, notifier) => {}),
      recommendationTitlesProvider.overrideWith((ref) => {}),
      rankingGenresProvider.overrideWith((ref) => {}),
      rankingMetadataProvider.overrideWith((ref) => metadata),
      tmdbAffinityServiceProvider.overrideWithValue(_Tmdb()),
    ]);
    addTearDown(container.dispose);
    await Future.wait([
      container.read(moviesProvider.future),
      container.read(seriesProvider.future),
      container.read(profilesProvider.future),
    ]);
    final solo = await container.read(matchmakingTabProvider('one').future);
    final group =
        await container.read(matchmakingGroupTabProvider('one|two').future);
    expect(solo.movies.map((e) => e.reco.id), ['B', 'A']);
    expect(solo.movies.first.score, solo.movies.last.score);
    expect(group.movies.map((e) => e.reco.id), ['B', 'A']);
    expect((group.movies.first.combined * 100).round(),
        (group.movies.last.combined * 100).round());
  });
}
