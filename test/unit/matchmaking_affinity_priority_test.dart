import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class _MemoryStorage extends StorageService {
  @override
  dynamic getSetting(String key) => null;
}

Recommendation recoOf(String id) {
  return Recommendation(
    kind: RecommendationKind.movie,
    movie: Movie(
      id: id,
      title: 'Titre $id',
      description: '',
      posterUrl: '',
      year: 2024,
      genre: 'Action',
      director: '',
      rating: 5,
      pegi: '',
      streamId: '',
    ),
  );
}

ScoredReco scored(String id, double affinity) {
  return ScoredReco(
    recoOf(id),
    0,
    0,
    5,
    affinity: affinity,
  );
}

GroupReco groupReco(String id, List<double> affinities) {
  return GroupReco(reco: recoOf(id), affinities: affinities);
}

void main() {
  group('prioritizeStrongAffinity', () {
    // Le cœur du correctif : un contenu très affin doit remonter devant un
    // contenu mieux classé par le score historique, sans être perdu.
    test('a >80% item is promoted above a lower-ranked one', () {
      final items = [
        scored('a', 0.95),
        scored('b', 0.60),
        scored('c', 0.20),
      ];

      final result = prioritizeStrongAffinity(items);

      expect(result.first.reco.id, 'a');
      expect(result.map((e) => e.reco.id).toList(), containsAll(['b', 'c']));
      expect(result, hasLength(3));
    });

    // La priorisation ne doit rien retirer : la taille est invariante.
    test('never drops an item', () {
      final items = [scored('a', 0.81), scored('b', 0.79), scored('c', 0.1)];

      final result = prioritizeStrongAffinity(items);

      expect(result, hasLength(items.length));
      expect(result.map((e) => e.reco.id).toSet(), {'a', 'b', 'c'});
    });

    // Stabilité : l'ordre relatif dans chaque groupe est préservé, donc deux
    // appels successifs ne réordonnent pas la liste de façon imprévisible.
    test('is stable across repeated calls', () {
      final items = [
        scored('a', 0.30),
        scored('b', 0.90),
        scored('c', 0.10),
        scored('d', 0.85),
      ];

      final first =
          prioritizeStrongAffinity(items).map((e) => e.reco.id).toList();
      final second =
          prioritizeStrongAffinity(items).map((e) => e.reco.id).toList();

      expect(first, second);
      // Les deux à coups de cœur à devant, dans leur ordre d'origine.
      expect(first, ['b', 'd', 'a', 'c']);
    });

    test('empty input is handled', () {
      expect(prioritizeStrongAffinity([]), isEmpty);
    });

    test('only values strictly above 75% are promoted', () {
      final items = [
        scored('low', 0.74),
        scored('edge', 0.75),
        scored('strong', 0.76),
      ];

      final result = prioritizeStrongAffinity(items);

      expect(result.map((e) => e.reco.id), ['strong', 'low', 'edge']);
    });
  });

  group('prioritizeStrongGroupAffinity', () {
    // Un contenu plébiscité par un seul membre ne doit pas dominer le groupe :
    // le critère porte sur le maillon faible.
    test('a one-sided hit does not outrank a group-wide hit', () {
      final items = [
        groupReco('polarisant', [0.95, 0.10]),
        groupReco('unanime', [0.85, 0.90]),
      ];

      final result = prioritizeStrongGroupAffinity(items);

      expect(result.first.reco.id, 'unanime');
    });

    test('group-wide hit is promoted', () {
      final items = [
        groupReco('a', [0.20, 0.25]),
        groupReco('b', [0.90, 0.88])
      ];

      final result = prioritizeStrongGroupAffinity(items);

      expect(result.first.reco.id, 'b');
    });

    test('never drops an item', () {
      final items = [
        groupReco('a', [0.9, 0.9]),
        groupReco('b', [0.1, 0.1])
      ];

      expect(prioritizeStrongGroupAffinity(items), hasLength(2));
    });

    test('every profile must be strictly above 75%', () {
      final items = [
        groupReco('edge', [0.75, 0.95]),
        groupReco('strong', [0.76, 0.76]),
      ];
      expect(prioritizeStrongGroupAffinity(items).first.reco.id, 'strong');
    });
  });

  test('group top 200 retains strong matches for movies and series', () async {
    final directory = await Directory.systemTemp.createTemp('orbit_match_');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('metadata_cache');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final profiles = [
      UserProfile(
        id: 'one',
        firstName: 'One',
        dateOfBirth: DateTime(1990),
        gender: '',
        favoriteGenres: [
          'Action',
          'Comedy',
          'Drama',
          'Fantasy',
          'Crime',
          'War'
        ],
      ),
      UserProfile(
        id: 'two',
        firstName: 'Two',
        dateOfBirth: DateTime(1990),
        gender: '',
        favoriteGenres: [
          'Action',
          'Comedy',
          'Horror',
          'Music',
          'Mystery',
          'Romance'
        ],
      ),
    ];
    final movies = [
      for (var i = 0; i < 200; i++)
        Movie(
          id: 'm$i',
          title: 'Movie $i',
          description: '',
          posterUrl: '',
          year: 2024,
          genre: 'Action, Comedy, Drama',
          director: '',
          rating: 7,
          pegi: '',
          streamId: '',
        ),
      Movie(
        id: 'movie-strong',
        title: 'Strong movie',
        description: '',
        posterUrl: '',
        year: 2024,
        genre: 'Action, Comedy, Drama, Horror',
        director: '',
        rating: 7,
        pegi: '',
        streamId: '',
      ),
    ];
    final series = [
      for (var i = 0; i < 200; i++)
        Series(
          id: 's$i',
          title: 'Series $i',
          description: '',
          coverUrl: '',
          year: 2024,
          genre: 'Action, Comedy, Drama',
          director: '',
          rating: 7,
          pegi: '',
          episodes: const [],
        ),
      Series(
        id: 'series-strong',
        title: 'Strong series',
        description: '',
        coverUrl: '',
        year: 2024,
        genre: 'Action, Comedy, Drama, Horror',
        director: '',
        rating: 7,
        pegi: '',
        episodes: const [],
      ),
    ];
    final tmdb = TmdbService(keyResolver: () => '');
    final container = ProviderContainer(overrides: [
      profilesProvider.overrideWith((ref) async => profiles),
      moviesProvider.overrideWith((ref) async => movies),
      seriesProvider.overrideWith((ref) async => series),
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(_MemoryStorage()),
      recommendationTitlesProvider.overrideWith((ref) => <String>{}),
      rankingGenresProvider.overrideWith((ref) => {}),
      rankingMetadataProvider.overrideWith((ref) => {}),
      tmdbAffinityServiceProvider.overrideWithValue(tmdb),
    ]);
    addTearDown(container.dispose);
    addTearDown(tmdb.dispose);
    await container.read(profilesProvider.future);
    final result =
        await container.read(matchmakingGroupTabProvider('one|two').future);
    expect(result.movies, hasLength(200));
    expect(result.series, hasLength(200));
    expect(result.movies.first.reco.id, 'movie-strong');
    expect(result.series.first.reco.id, 'series-strong');
    expect(result.movies.first.minAffinity, greaterThan(0.75));
    expect(result.series.first.minAffinity, greaterThan(0.75));
  });

  test('ranking metadata identifies 20 matching movies and series', () async {
    final directory = await Directory.systemTemp.createTemp('orbit_match_');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('metadata_cache');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final profile = UserProfile(
      id: 'one',
      firstName: 'One',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: ['Action', 'Comédie', 'Drame'],
    );
    final secondProfile = UserProfile(
      id: 'two',
      firstName: 'Two',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: ['Action', 'Comédie', 'Drame'],
    );
    final movies = [
      for (var i = 0; i < 20; i++)
        Movie(
          id: 'm$i',
          title: 'Movie $i',
          description: '',
          posterUrl: '',
          year: 2024,
          genre: 'Récents',
          director: '',
          rating: 7,
          pegi: '',
          streamId: '',
        ),
    ];
    final series = [
      for (var i = 0; i < 20; i++)
        Series(
          id: 's$i',
          title: 'Series $i',
          description: '',
          coverUrl: '',
          year: 2024,
          genre: 'Récents',
          director: '',
          rating: 7,
          pegi: '',
          episodes: const [],
        ),
    ];
    final movieRanks = [
      for (var i = 0; i < 20; i++)
        TmdbRankEntry(
          tmdbId: i + 1,
          title: 'Movie $i',
          posterPath: '',
          year: 2024,
          genreIds: const [28, 35, 18],
        ),
    ];
    final seriesRanks = [
      for (var i = 0; i < 20; i++)
        TmdbRankEntry(
          tmdbId: i + 101,
          title: 'Series $i',
          posterPath: '',
          year: 2024,
          isTv: true,
          genreIds: const [28, 35, 18],
        ),
    ];
    final tmdb = TmdbService(keyResolver: () => '');
    final container = ProviderContainer(overrides: [
      currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
      profilesProvider.overrideWith((ref) async => [profile, secondProfile]),
      moviesProvider.overrideWith((ref) async => movies),
      seriesProvider.overrideWith((ref) async => series),
      activeSubscriptionProvider.overrideWith((ref) => null),
      storageServiceProvider.overrideWithValue(_MemoryStorage()),
      favoritesProvider.overrideWithBuild((ref, notifier) => {}),
      recommendationTitlesProvider.overrideWith((ref) => <String>{}),
      tmdbAffinityServiceProvider.overrideWithValue(tmdb),
      flixPatrolMoviesProvider.overrideWith((ref) async => movieRanks),
      flixPatrolTvProvider.overrideWith((ref) async => seriesRanks),
      flixPatrolTrendingMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTrendingTvProvider.overrideWith((ref) async => []),
      flixPatrolTopRatedMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTopRatedTvProvider.overrideWith((ref) async => []),
    ]);
    addTearDown(container.dispose);
    addTearDown(tmdb.dispose);
    await Future.wait([
      container.read(moviesProvider.future),
      container.read(seriesProvider.future),
      container.read(profilesProvider.future),
      container.read(flixPatrolMoviesProvider.future),
      container.read(flixPatrolTvProvider.future),
    ]);
    final result = await container.read(matchmakingTabProvider('one').future);
    expect(result.movies.where((item) => item.affinity > 0.8), hasLength(20));
    expect(result.series.where((item) => item.affinity > 0.8), hasLength(20));
    final scorer = container.read(profileAffinityScorerProvider)!;
    expect(scorer.percentForMovie(movies.first), greaterThan(80));
    expect(scorer.percentForSeries(series.first), greaterThan(80));
    final group =
        await container.read(matchmakingGroupTabProvider('one|two').future);
    expect(group.movies.where((item) => item.minAffinity > 0.8), hasLength(20));
    expect(group.series.where((item) => item.minAffinity > 0.8), hasLength(20));
  });

  test('ranking genres require an unambiguous title, year and type', () async {
    final container = ProviderContainer(overrides: [
      flixPatrolMoviesProvider.overrideWith((ref) async => [
            const TmdbRankEntry(
              tmdbId: 1,
              title: 'Same',
              posterPath: '',
              year: 2020,
              genreIds: [28],
            ),
            const TmdbRankEntry(
              tmdbId: 2,
              title: 'Same',
              posterPath: '',
              year: 2020,
              genreIds: [35],
            ),
            const TmdbRankEntry(
              tmdbId: 3,
              title: 'Same',
              posterPath: '',
              year: 2021,
              genreIds: [18],
            ),
            const TmdbRankEntry(
              tmdbId: 4,
              title: 'No year',
              posterPath: '',
              genreIds: [28],
            ),
          ]),
      flixPatrolTvProvider.overrideWith((ref) async => [
            const TmdbRankEntry(
              tmdbId: 5,
              title: 'Same',
              posterPath: '',
              year: 2020,
              isTv: true,
              genreIds: [35],
            ),
          ]),
      flixPatrolTrendingMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTrendingTvProvider.overrideWith((ref) async => []),
      flixPatrolTopRatedMoviesProvider.overrideWith((ref) async => []),
      flixPatrolTopRatedTvProvider.overrideWith((ref) async => []),
    ]);
    addTearDown(container.dispose);
    await Future.wait([
      container.read(flixPatrolMoviesProvider.future),
      container.read(flixPatrolTvProvider.future),
    ]);
    final genres = container.read(rankingGenresProvider);
    expect(genres[(title: 'same', year: 2020, isTv: false)], isNull);
    expect(genres[(title: 'same', year: 2021, isTv: false)], 'Drame');
    expect(genres[(title: 'same', year: 2020, isTv: true)], 'Comédie');
    expect(genres[(title: 'no year', year: 0, isTv: false)], isNull);
  });
}
