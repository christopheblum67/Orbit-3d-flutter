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

  test('detail providers retain results and bypass enrichment for M3U series',
      () async {
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
    expect(
      await container.read(public.movieDetailProvider(movie).future),
      same(detail),
    );
    expect(service.movies, 1);
    final seriesDetail =
        await container.read(public.seriesDetailProvider(series).future);
    expect(seriesDetail.dataSource, 'm3u');
    expect(seriesDetail.id, series.id);
    expect(service.series, 0);
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
