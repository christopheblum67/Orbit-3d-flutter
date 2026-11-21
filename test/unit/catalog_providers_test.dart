import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart' as split;
import 'package:orbit_3d_flutter/providers/category_change_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Filter extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(
        subscriptionId: 'test',
        hiddenLiveCategoryIds: {'hidden'},
        hiddenVodCategoryIds: {'hidden'},
        hiddenSeriesCategoryIds: {'hidden'},
      );
}

class _Api extends ApiService {
  _Api(this.playlist);
  final M3uPlaylist playlist;
  int requests = 0;
  final movies = <Movie>[];
  final series = <Series>[];

  @override
  Future<M3uPlaylist> fetchM3uPlaylist(String url,
      {void Function()? onParsing}) async {
    requests++;
    return playlist;
  }

  @override
  Future<List<Movie>> fetchMovies() async => movies;

  @override
  Future<List<Series>> fetchSeries() async => series;
}

class _PendingPlaylistApi extends ApiService {
  final callbacks = <void Function()>[];
  final requests = <Completer<M3uPlaylist>>[];

  @override
  Future<M3uPlaylist> fetchM3uPlaylist(String url,
      {void Function()? onParsing}) {
    callbacks.add(onParsing!);
    final request = Completer<M3uPlaylist>();
    requests.add(request);
    return request.future;
  }
}

class _WaitingCategoryCountTracker extends CategoryCountTracker {
  _WaitingCategoryCountTracker(super.databasePath) : super.forTesting();

  int _pending = 0;
  Completer<void> _idle = Completer<void>()..complete();

  Future<void> waitForWrites() => _idle.future;

  @override
  Future<void> record(
    CategoryChangeKey key,
    Iterable<CatalogItemIdentity> items, {
    required bool refresh,
  }) async {
    if (_pending++ == 0) _idle = Completer<void>();
    try {
      await super.record(key, items, refresh: refresh);
    } finally {
      if (--_pending == 0) _idle.complete();
    }
  }
}

class _BlockingCategoryCountTracker extends CategoryCountTracker {
  _BlockingCategoryCountTracker(this.release);

  final Completer<void> release;
  final Completer<void> started = Completer<void>();
  final Completer<void> finished = Completer<void>();
  int calls = 0;
  int _completed = 0;

  @override
  Future<void> record(
    CategoryChangeKey key,
    Iterable<CatalogItemIdentity> items, {
    required bool refresh,
  }) async {
    calls++;
    if (!started.isCompleted) started.complete();
    await release.future;
    if (++_completed == 2) finished.complete();
  }
}

Channel _channel(String id, String category) => Channel(
      id: id,
      name: id,
      logoUrl: '',
      streamUrl: '',
      group: category,
      categoryId: category,
    );

Movie _movie(String id, String category) => Movie(
      id: id,
      title: id,
      description: '',
      posterUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      streamId: id,
      categoryId: category,
    );

Series _series(String id, String category) => Series(
      id: id,
      title: id,
      description: '',
      coverUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: const [],
      categoryId: category,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory dir;
  late _WaitingCategoryCountTracker tracker;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('catalog_providers_test_');
    tracker = _WaitingCategoryCountTracker(
      '${dir.path}${Platform.pathSeparator}changes.db',
    );
  });
  tearDown(() async {
    await tracker.close();
    await dir.delete(recursive: true);
  });

  test('invalidated playlist cannot emit a stale parsing milestone', () async {
    final api = _PendingPlaylistApi();
    final container = ProviderContainer(overrides: [
      public.apiServiceProvider.overrideWithValue(api),
      public.activeSubscriptionProvider.overrideWithValue(Subscription(
        id: 'm3u',
        name: 'M3U',
        type: SubscriptionType.m3u,
        m3uUrl: 'https://example.test/playlist',
        createdAt: DateTime(2020),
      )),
    ]);
    addTearDown(container.dispose);
    var milestones = 0;
    final events = container
        .read(split.m3uParsingEventsProvider)
        .stream
        .listen((_) => milestones++);
    addTearDown(events.cancel);
    final listener = container.listen(split.m3uPlaylistProvider, (_, __) {});
    addTearDown(listener.close);
    expect(api.requests, hasLength(1));
    container.invalidate(split.m3uPlaylistProvider);
    await container.pump();
    expect(api.requests, hasLength(2));
    api.callbacks.first();
    expect(milestones, 0);
    api.callbacks.last();
    expect(milestones, 1);
    for (final request in api.requests) {
      request.complete(
        const M3uPlaylist(channels: [], radios: [], movies: [], series: []),
      );
    }
    await container.pump();
  });

  test('catalog facade exports the original provider identities', () {
    expect(public.m3uPlaylistProvider, same(split.m3uPlaylistProvider));
    expect(public.liveChannelsAllProvider, same(split.liveChannelsAllProvider));
    expect(public.liveChannelsProvider, same(split.liveChannelsProvider));
    expect(public.moviesProvider, same(split.moviesProvider));
    expect(public.seriesProvider, same(split.seriesProvider));
    expect(public.seriesInfoProvider, same(split.seriesInfoProvider));
    expect(public.radioChannelsProvider, same(split.radioChannelsProvider));
    expect(public.moviesCompactProvider, same(split.moviesCompactProvider));
    expect(public.seriesCompactProvider, same(split.seriesCompactProvider));
    expect(public.vodCategoriesProvider, same(split.vodCategoriesProvider));
    expect(
        public.seriesCategoriesProvider, same(split.seriesCategoriesProvider));
    expect(public.liveCategoriesFromM3UProvider,
        same(split.liveCategoriesFromM3UProvider));
  });

  test('M3U shares one playlist, preserves filters, categories and projections',
      () async {
    final visible = _series('visible-series', 'Visible');
    final playlist = M3uPlaylist(
      channels: [_channel('a', 'Visible'), _channel('b', 'hidden')],
      radios: [_channel('radio', 'Radio')],
      movies: [_movie('movie', 'Visible'), _movie('other', 'Visible')],
      series: [visible, _series('other-series', 'hidden')],
    );
    final api = _Api(playlist);
    final container = ProviderContainer(
      overrides: [
        categoryCountTrackerProvider.overrideWithValue(tracker),
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWithValue(
          Subscription(
            id: 'm3u',
            name: 'M3U',
            type: SubscriptionType.m3u,
            m3uUrl: 'https://example.test/playlist',
            createdAt: DateTime(2020),
          ),
        ),
        vodCategoryFilterProvider.overrideWith(_Filter.new),
      ],
    );
    addTearDown(container.dispose);
    expect((await container.read(public.liveChannelsAllProvider.future)).length,
        2);
    expect(
      (await container.read(public.liveChannelsProvider.future))
          .map((c) => c.id),
      ['a'],
    );
    expect(
        (await container.read(public.radioChannelsProvider.future)).single.id,
        'radio');
    expect(
      (await container.read(public.vodCategoriesProvider.future))
          .map((category) => (category.id, category.count)),
      [('Visible', 2)],
    );
    expect(
      (await container.read(public.seriesCategoriesProvider.future))
          .map((category) => category.id),
      ['Visible', 'hidden'],
    );
    await container.read(public.moviesProvider.future);
    await container.read(public.seriesProvider.future);
    await tracker.waitForWrites();
    expect(
      (await container.read(public.moviesCompactProvider.future))
          .map((m) => m.id),
      ['movie', 'other'],
    );
    expect(
      (await container.read(public.seriesCompactProvider.future))
          .map((s) => s.id),
      ['visible-series', 'other-series'],
    );
    final detail =
        container.listen(public.seriesInfoProvider(visible.id), (_, __) {});
    addTearDown(detail.close);
    expect(await container.read(public.seriesInfoProvider(visible.id).future),
        same(visible));
    expect(api.requests, 1);
  });

  test('Xtream filters hidden film and series categories before projection',
      () async {
    final api = _Api(const M3uPlaylist(
      channels: [],
      radios: [],
      movies: [],
      series: [],
    ))
      ..movies.addAll(
          [_movie('shown-movie', 'shown'), _movie('hidden-movie', 'hidden')])
      ..series.addAll([
        _series('shown-series', 'shown'),
        _series('hidden-series', 'hidden')
      ]);
    final container = ProviderContainer(
      overrides: [
        categoryCountTrackerProvider.overrideWithValue(tracker),
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWithValue(
          Subscription(
            id: 'xtream',
            name: 'Xtream',
            type: SubscriptionType.xtream,
            createdAt: DateTime(2020),
          ),
        ),
        vodCategoryFilterProvider.overrideWith(_Filter.new),
      ],
    );
    addTearDown(container.dispose);
    final movies = await container.read(public.moviesProvider.future);
    final series = await container.read(public.seriesProvider.future);
    await tracker.waitForWrites();
    expect(movies.map((movie) => movie.id), ['shown-movie']);
    expect(series.map((item) => item.id), ['shown-series']);
    expect(
      (await container.read(public.moviesCompactProvider.future))
          .map((m) => m.id),
      ['shown-movie'],
    );
    expect(
      (await container.read(public.seriesCompactProvider.future))
          .map((s) => s.id),
      ['shown-series'],
    );
    expect(api.requests, 0);

    api.movies.add(_movie('new-movie', 'shown'));
    api.series.add(_series('new-series', 'shown'));
    ApiService.bypassCatalogCache = true;
    addTearDown(() => ApiService.bypassCatalogCache = false);
    container.invalidate(public.moviesProvider);
    container.invalidate(public.seriesProvider);
    await container.read(public.moviesProvider.future);
    await container.read(public.seriesProvider.future);
    await tracker.waitForWrites();
    expect(
      (await container.read(categoryIncreasesProvider((
        subscriptionId: 'xtream',
        catalog: CategoryCatalog.movies,
      )).future))
          .categories,
      {'shown': (total: 2, added: 1)},
    );
    expect(
      (await container.read(categoryIncreasesProvider((
        subscriptionId: 'xtream',
        catalog: CategoryCatalog.series,
      )).future))
          .categories,
      {'shown': (total: 2, added: 1)},
    );
  });

  test('catalog providers do not wait for novelty database writes', () async {
    final release = Completer<void>();
    final slowTracker = _BlockingCategoryCountTracker(release);
    final api = _Api(const M3uPlaylist(
      channels: [],
      radios: [],
      movies: [],
      series: [],
    ))
      ..movies.add(_movie('movie', 'shown'))
      ..series.add(_series('series', 'shown'));
    final container = ProviderContainer(
      overrides: [
        categoryCountTrackerProvider.overrideWithValue(slowTracker),
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWithValue(
          Subscription(
            id: 'xtream',
            name: 'Xtream',
            type: SubscriptionType.xtream,
            createdAt: DateTime(2020),
          ),
        ),
        vodCategoryFilterProvider.overrideWith(_Filter.new),
      ],
    );
    addTearDown(container.dispose);

    final movies = await container.read(public.moviesProvider.future);
    final series = await container.read(public.seriesProvider.future);

    expect(movies.map((movie) => movie.id), ['movie']);
    expect(series.map((item) => item.id), ['series']);
    await slowTracker.started.future;
    expect(slowTracker.calls, 2);

    release.complete();
    await slowTracker.finished.future;
  });
}
