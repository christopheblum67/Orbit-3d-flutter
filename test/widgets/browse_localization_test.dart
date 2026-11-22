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
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';

class _Preferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

class _Filters extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(subscriptionId: 'sub');
}

void main() {
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
