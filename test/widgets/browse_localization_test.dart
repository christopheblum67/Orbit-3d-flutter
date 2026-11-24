import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/features/browse/browse_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/movie_compact.dart';
import 'package:orbit_3d_flutter/models/series_compact.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class _Preferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

class _Filters extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(subscriptionId: 'sub');
}

class _Tmdb implements TmdbService {
  @override
  TmdbRankEntry? peekMovieLight(String title, {int? year}) => null;
  @override
  TmdbRankEntry? peekTvLight(String title, {int? year}) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('compact grids sort the displayed affinity in both directions',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const scorer = ProfileAffinityScorer(
      favoriteGenres: [],
      favoriteIds: {},
      seenIds: {},
      tmdbTitles: {},
      rankingMetadata: {
        (title: 'c', year: 2024, isTv: false): TmdbRankEntry(
          tmdbId: 1, title: 'C', posterPath: '', year: 2024,
          rating: 8, voteCount: 1000,
        ),
        (title: 'c', year: 2024, isTv: true): TmdbRankEntry(
          tmdbId: 2, title: 'C', posterPath: '', year: 2024, isTv: true,
          rating: 8, voteCount: 1000,
        ),
      },
    );
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const BrowseScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(_Preferences.new),
        vodCategoryFilterProvider.overrideWith(_Filters.new),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        recentlyWatchedProvider.overrideWithBuild((ref, notifier) => {}),
        profileAffinityScorerProvider.overrideWith((ref) => scorer),
        tmdbAffinityServiceProvider.overrideWithValue(_Tmdb()),
        vodCategoriesProvider.overrideWith((ref) async => []),
        seriesCategoriesProvider.overrideWith((ref) async => []),
        moviesCompactProvider.overrideWith((ref) async => const [
              MovieCompact(id: 'a', title: 'A', posterUrl: '', year: 2024,
                  genre: '', rating: 2, categoryId: ''),
              MovieCompact(id: 'b', title: 'B', posterUrl: '', year: 2024,
                  genre: '', rating: 9, categoryId: ''),
              MovieCompact(id: 'c', title: 'C', posterUrl: '', year: 2024,
                  genre: '', rating: 9, categoryId: ''),
            ]),
        seriesCompactProvider.overrideWith((ref) async => const [
              SeriesCompact(id: 'a', title: 'A', coverUrl: '', year: 2024,
                  genre: '', rating: 2, categoryId: ''),
              SeriesCompact(id: 'b', title: 'B', coverUrl: '', year: 2024,
                  genre: '', rating: 9, categoryId: ''),
              SeriesCompact(id: 'c', title: 'C', coverUrl: '', year: 2024,
                  genre: '', rating: 9, categoryId: ''),
            ]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('By affinity'));
    await tester.pumpAndSettle();
    List<MediaCard> cards() =>
        tester.widgetList<MediaCard>(find.byType(MediaCard)).toList();
    for (final isSeries in [false, true]) {
      if (isSeries) {
        await tester.tap(find.text('Series').first);
        await tester.pumpAndSettle();
      }
      expect(cards().map((c) => c.title), ['C', 'B', 'A']);
      expect(cards().first.matchPercent, greaterThan(cards().last.matchPercent!));
      await tester.tap(find.byTooltip('Descending order'));
      await tester.pumpAndSettle();
      expect(cards().map((c) => c.title), ['A', 'C', 'B']);
      expect(cards().first.matchPercent, lessThan(cards().last.matchPercent!));
      await tester.tap(find.byTooltip('Ascending order'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('ranking details remain available without subscription notice',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(_Preferences.new),
        flixPatrolMoviesProvider.overrideWith((ref) async => const [
              TmdbRankEntry(
                tmdbId: 1,
                title: 'Unmatched title',
                posterPath: '',
                overview: 'A sample synopsis.',
              ),
            ]),
        flixPatrolTvProvider.overrideWith((ref) async => []),
        moviesProvider.overrideWith((ref) async => []),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RankingsView()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unmatched title'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(find.descendant(of: sheet, matching: find.text('Unmatched title')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('A sample synopsis.')),
        findsOneWidget);
    expect(find.textContaining('active subscription'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact movie and series retain age and new badges',
      (tester) async {
    final now = DateTime.now();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const BrowseScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(_Preferences.new),
        vodCategoryFilterProvider.overrideWith(_Filters.new),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        recentlyWatchedProvider.overrideWithBuild((ref, notifier) => {}),
        profileAffinityScorerProvider.overrideWith((ref) => null),
        vodCategoriesProvider.overrideWith((ref) async => []),
        seriesCategoriesProvider.overrideWith((ref) async => []),
        moviesCompactProvider.overrideWith((ref) async => [
              MovieCompact(
                id: 'm', title: 'Movie', posterUrl: '', year: 0, genre: '',
                rating: 0, categoryId: '', pegi: '12', addedDate: now,
              ),
            ]),
        seriesCompactProvider.overrideWith((ref) async => [
              SeriesCompact(
                id: 's', title: 'Show', coverUrl: '', year: 0, genre: '',
                rating: 0, categoryId: '', pegi: '16', addedDate: now,
              ),
            ]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    var card = tester.widget<MediaCard>(find.byType(MediaCard));
    expect(card.ageLabel, isNotEmpty);
    expect(card.isNew, isTrue);

    await tester.tap(find.text('Series').first);
    await tester.pumpAndSettle();
    card = tester.widget<MediaCard>(find.byType(MediaCard));
    expect(card.title, 'Show');
    expect(card.ageLabel, isNotEmpty);
    expect(card.isNew, isTrue);
    Focus.of(tester.element(find.text('Movies').first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<MediaCard>(find.byType(MediaCard)).title, 'Movie');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<MediaCard>(find.byType(MediaCard)).title, 'Show');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ranking labels and empty state follow the selected language',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flixPatrolMoviesProvider.overrideWith((ref) async => []),
          flixPatrolTvProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RankingsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Popular rankings'), findsOneWidget);
    expect(find.text('Now playing'), findsOneWidget);
    expect(find.text('Airing today'), findsOneWidget);
    expect(
      find.text(
        'TMDB trends are unavailable. Add a TMDB API key in Settings (or TMDB_API_KEY in assets/config/runtime.env).',
      ),
      findsNWidgets(2),
    );
  });
}
