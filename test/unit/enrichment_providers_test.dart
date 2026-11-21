import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/enrichment_providers.dart' as split;
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class _Tmdb implements TmdbService {
  _Tmdb({this.hasApiKey = true});

  @override
  final bool hasApiKey;
  final calls = <({String title, int? year})>[];

  @override
  Future<TmdbRankEntry?> searchMovieLight(String title, {int? year}) async {
    calls.add((title: title, year: year));
    if (title == 'film-1') return null;
    return TmdbRankEntry(tmdbId: calls.length, title: title, posterPath: '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Enrichment implements MetadataEnrichmentService {
  int movies = 0;
  int series = 0;

  @override
  Future<MovieDetail> enrichMovie(Movie movie) async {
    movies++;
    return MovieDetail.fromMovie(movie);
  }

  @override
  Future<SeriesDetail> enrichSeries(Series value) async {
    series++;
    return SeriesDetail.fromSeries(value, dataSource: 'enriched');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PosterApi implements ApiService {
  final calls = <Movie>[];
  final pending = <Completer<String?>>[];

  @override
  Future<String?> fetchMoviePosterFromXtream(
    Movie movie,
    Subscription subscription,
  ) {
    calls.add(movie);
    final result = Completer<String?>();
    pending.add(result);
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PosterTmdb implements TmdbService {
  final years = <int?>[];
  @override
  bool get hasApiKey => true;

  @override
  Future<TmdbRankEntry?> searchMovieLight(String title, {int? year}) async {
    years.add(year);
    return year == null
        ? TmdbRankEntry(tmdbId: 1, title: title, posterPath: '/poster.jpg')
        : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Movie _movie(int id, {bool complete = false}) => Movie(
      id: '$id',
      title: 'film-$id',
      description: '',
      posterUrl: complete ? 'poster' : '',
      year: id == 0 ? 2020 : 0,
      genre: '',
      director: '',
      rating: complete ? 7 : 0,
      pegi: '',
      streamId: '$id',
    );

Series _series() => Series(
      id: 's',
      title: 'Series',
      description: '',
      coverUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: const [],
    );

void main() {
  test('facade exports the same enrichment providers', () {
    expect(
      public.vodGridEnrichmentsProvider,
      same(split.vodGridEnrichmentsProvider),
    );
    expect(
      public.enrichmentServiceProvider,
      same(split.enrichmentServiceProvider),
    );
    expect(public.movieDetailProvider, same(split.movieDetailProvider));
    expect(public.seriesDetailProvider, same(split.seriesDetailProvider));
  });

  test('grid selects incomplete films and limits attempts including misses',
      () async {
    final tmdb = _Tmdb();
    final movies = [
      _movie(99, complete: true),
      for (var i = 0; i < 32; i++) _movie(i),
    ];
    final container = ProviderContainer(
      overrides: [
        public.moviesProvider.overrideWith((ref) async => movies),
        public.tmdbServiceProvider.overrideWithValue(tmdb),
      ],
    );
    addTearDown(container.dispose);
    await container.read(public.moviesProvider.future);
    final listener =
        container.listen(public.vodGridEnrichmentsProvider, (_, __) {});
    addTearDown(listener.close);
    final result =
        await container.read(public.vodGridEnrichmentsProvider.future);
    expect(tmdb.calls, hasLength(30));
    expect(tmdb.calls.first, (title: 'film-0', year: 2020));
    expect(tmdb.calls[1], (title: 'film-1', year: null));
    expect(tmdb.calls.last.title, 'film-29');
    expect(result.length, 29);
    expect(result.containsKey('1'), isFalse);
    expect(result.containsKey('99'), isFalse);
  });

  test('grid makes no calls without an API key', () async {
    final tmdb = _Tmdb(hasApiKey: false);
    final container = ProviderContainer(
      overrides: [
        public.moviesProvider.overrideWith((ref) async => [_movie(0)]),
        public.tmdbServiceProvider.overrideWithValue(tmdb),
      ],
    );
    addTearDown(container.dispose);
    await container.read(public.moviesProvider.future);
    final listener =
        container.listen(public.vodGridEnrichmentsProvider, (_, __) {});
    addTearDown(listener.close);
    expect(
      await container.read(public.vodGridEnrichmentsProvider.future),
      isEmpty,
    );
    expect(tmdb.calls, isEmpty);
  });

  test('poster lookups limit Xtream concurrency and skip disposed tiles',
      () async {
    final api = _PosterApi();
    final movies = List.generate(4, _movie);
    final container = ProviderContainer(overrides: [
      public.apiServiceProvider.overrideWithValue(api),
      public.activeSubscriptionProvider.overrideWithValue(Subscription(
        id: 'xtream',
        name: 'Test',
        type: SubscriptionType.xtream,
        createdAt: DateTime(2020),
      )),
    ]);
    addTearDown(container.dispose);
    final listeners = [
      for (final movie in movies)
        container.listen(public.movieXtreamPosterProvider(movie), (_, __) {}),
    ];
    await container.pump();
    expect(api.calls, hasLength(3));
    listeners.last.close();
    await container.pump();
    api.pending.first.complete(null);
    await container.pump();
    expect(api.calls, hasLength(3));
    for (final pending in api.pending.skip(1)) {
      pending.complete(null);
    }
    await container.pump();
    for (final listener in listeners.take(3)) {
      listener.close();
    }
  });

  test('poster lookup retries TMDB without an unmatched year', () async {
    final tmdb = _PosterTmdb();
    final movie = _movie(0);
    final container = ProviderContainer(
      overrides: [public.tmdbServiceProvider.overrideWithValue(tmdb)],
    );
    addTearDown(container.dispose);
    final listener =
        container.listen(public.movieTmdbPosterProvider(movie), (_, __) {});
    addTearDown(listener.close);
    expect(await container.read(public.movieTmdbPosterProvider(movie).future),
        'https://image.tmdb.org/t/p/w342/poster.jpg');
    expect(tmdb.years, [2020, null]);
  });

  test('grid enrichment is disposed and recreated with its listener', () async {
    final tmdb = _Tmdb();
    final container = ProviderContainer(
      overrides: [
        public.moviesProvider.overrideWith((ref) async => [_movie(0)]),
        public.tmdbServiceProvider.overrideWithValue(tmdb),
      ],
    );
    addTearDown(container.dispose);
    await container.read(public.moviesProvider.future);
    final first =
        container.listen(public.vodGridEnrichmentsProvider, (_, __) {});
    await container.read(public.vodGridEnrichmentsProvider.future);
    first.close();
    await container.pump();
    expect(container.exists(public.vodGridEnrichmentsProvider), isFalse);
    final second =
        container.listen(public.vodGridEnrichmentsProvider, (_, __) {});
    addTearDown(second.close);
    await container.read(public.vodGridEnrichmentsProvider.future);
    expect(tmdb.calls, hasLength(2));
  });

  test('detail providers enrich and retain results for M3U', () async {
    final service = _Enrichment();
    final movie = _movie(0);
    final series = _series();
    final subscription = Subscription(
      id: 'm3u',
      name: 'M3U',
      type: SubscriptionType.m3u,
      createdAt: DateTime(2020),
    );
    final container = ProviderContainer(
      overrides: [
        public.enrichmentServiceProvider.overrideWithValue(service),
        public.activeSubscriptionProvider.overrideWithValue(subscription),
      ],
    );
    addTearDown(container.dispose);
    final detail =
        await container.read(public.movieDetailProvider(movie).future);
    expect(detail.dataSource, 'm3u');
    expect(
      await container.read(public.movieDetailProvider(movie).future),
      same(detail),
    );
    expect(service.movies, 1);
    final seriesDetail =
        await container.read(public.seriesDetailProvider(series).future);
    expect(seriesDetail.dataSource, 'enriched');
    expect(seriesDetail.id, series.id);
    expect(service.series, 1);
    expect(
      await container.read(public.seriesDetailProvider(series).future),
      same(seriesDetail),
    );
  });

  test('Xtream series uses and retains the enriched detail', () async {
    final service = _Enrichment();
    final series = _series();
    final container = ProviderContainer(
      overrides: [
        public.enrichmentServiceProvider.overrideWithValue(service),
        public.activeSubscriptionProvider.overrideWithValue(
          Subscription(
            id: 'xtream',
            name: 'Xtream',
            type: SubscriptionType.xtream,
            createdAt: DateTime(2020),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final first =
        await container.read(public.seriesDetailProvider(series).future);
    final second =
        await container.read(public.seriesDetailProvider(series).future);
    expect(first.dataSource, 'enriched');
    expect(second, same(first));
    expect(service.series, 1);
  });
}
