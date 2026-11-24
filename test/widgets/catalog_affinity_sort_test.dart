import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/features/series/series_screen.dart';
import 'package:orbit_3d_flutter/features/vod/vod_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/catalog_db_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final isMovie in [true, false]) {
    testWidgets('${isMovie ? 'films' : 'series'} break affinity ties by votes',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scorer = ProfileAffinityScorer(
        favoriteGenres: const [],
        favoriteIds: const {},
        seenIds: const {},
        tmdbTitles: const {},
        rankingMetadata: {
          (title: 'b', year: 2024, isTv: !isMovie): TmdbRankEntry(
            tmdbId: 1,
            title: 'B',
            posterPath: '',
            year: 2024,
            isTv: !isMovie,
            rating: 8,
            voteCount: 1000,
          ),
        },
      );
      Movie movie(String id) => Movie(
            id: id,
            title: id,
            description: '',
            posterUrl: '',
            year: 2024,
            genre: '',
            director: '',
            rating: 7,
            pegi: '',
            streamId: id,
          );
      Series series(String id) => Series(
            id: id,
            title: id,
            description: '',
            coverUrl: '',
            year: 2024,
            genre: '',
            director: '',
            rating: 7,
            pegi: '',
            episodes: const [],
          );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          preferencesProvider.overrideWith(_Preferences.new),
          activeSubscriptionProvider.overrideWithValue(null),
          vodCategoryFilterProvider.overrideWith(_Filters.new),
          favoritesProvider.overrideWithBuild((ref, notifier) => {}),
          recentlyWatchedProvider.overrideWithBuild((ref, notifier) => {}),
          profileAffinityScorerProvider.overrideWith((ref) => scorer),
          tmdbAffinityServiceProvider.overrideWithValue(_Tmdb()),
          catalogDbKeyProvider(isMovie ? CatalogKind.vod : CatalogKind.series)
              .overrideWith((ref) async => null),
          moviesProvider.overrideWith((ref) async => [movie('A'), movie('B')]),
          seriesProvider
              .overrideWith((ref) async => [series('A'), series('B')]),
          vodCategoriesProvider.overrideWith((ref) async => []),
          seriesCategoriesProvider.overrideWith((ref) async => []),
          vodGridEnrichmentsProvider.overrideWith((ref) async => {}),
          movieXtreamPosterProvider.overrideWith((ref, movie) async => null),
          movieTmdbPosterProvider.overrideWith((ref, movie) async => null),
          movieRealGenreProvider
              .overrideWith((ref, query) async => query.catalogGenre),
          seriesRealGenreProvider
              .overrideWith((ref, query) async => query.catalogGenre),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: isMovie ? const VodScreen() : const SeriesScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By affinity'));
      await tester.pumpAndSettle();
      List<MediaCard> cards() =>
          tester.widgetList<MediaCard>(find.byType(MediaCard)).toList();
      expect(cards().map((c) => c.title), ['B', 'A']);
      expect(cards().first.matchPercent, cards().last.matchPercent);
      await tester.tap(find.byTooltip('Descending order'));
      await tester.pumpAndSettle();
      expect(cards().map((c) => c.title), ['B', 'A']);
    });

    for (final hasFavorites in [true, false]) {
      for (final reverseBeforeResolution
          in hasFavorites ? [false, true] : [false]) {
        testWidgets(
            '${isMovie ? 'films' : 'series'} sort displayed affinity in both directions'
            '${hasFavorites ? ' after genre resolution (ascending: $reverseBeforeResolution)' : ' without favorite genres'}',
            (tester) async {
          tester.view.physicalSize = const Size(1400, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final genreA = Completer<String>();
          final genreB = Completer<String>();
          const scorer = ProfileAffinityScorer(
            favoriteGenres: ['Action'],
            favoriteIds: {},
            seenIds: {},
            tmdbTitles: {},
          );
          const noGenres = ProfileAffinityScorer(
            favoriteGenres: [],
            favoriteIds: {},
            seenIds: {},
            tmdbTitles: {},
          );
          Movie movie(String id, double rating) => Movie(
                id: id,
                title: id,
                description: '',
                posterUrl: '',
                year: 2024,
                genre: 'Other',
                director: '',
                rating: rating,
                pegi: '',
                streamId: id,
              );
          Series series(String id, double rating) => Series(
                id: id,
                title: id,
                description: '',
                coverUrl: '',
                year: 2024,
                genre: 'Other',
                director: '',
                rating: rating,
                pegi: '',
                episodes: const [],
              );
          await tester.pumpWidget(ProviderScope(
            overrides: [
              preferencesProvider.overrideWith(_Preferences.new),
              activeSubscriptionProvider.overrideWithValue(null),
              vodCategoryFilterProvider.overrideWith(_Filters.new),
              favoritesProvider.overrideWithBuild((ref, notifier) => {}),
              recentlyWatchedProvider.overrideWithBuild((ref, notifier) => {}),
              profileAffinityScorerProvider
                  .overrideWith((ref) => hasFavorites ? scorer : noGenres),
              tmdbAffinityServiceProvider.overrideWithValue(_Tmdb()),
              catalogDbKeyProvider(
                      isMovie ? CatalogKind.vod : CatalogKind.series)
                  .overrideWith((ref) async => null),
              moviesProvider.overrideWith((ref) async => [
                    movie('A', 9),
                    movie('B', 5),
                  ]),
              seriesProvider.overrideWith((ref) async => [
                    series('A', 9),
                    series('B', 5),
                  ]),
              vodCategoriesProvider
                  .overrideWith((ref) async => <MediaCategory>[]),
              seriesCategoriesProvider
                  .overrideWith((ref) async => <MediaCategory>[]),
              vodGridEnrichmentsProvider.overrideWith((ref) async => {}),
              movieXtreamPosterProvider
                  .overrideWith((ref, movie) async => null),
              movieTmdbPosterProvider.overrideWith((ref, movie) async => null),
              movieRealGenreProvider.overrideWith((ref, query) => hasFavorites
                  ? (query.id == 'A' ? genreA.future : genreB.future)
                  : Future.value(query.catalogGenre)),
              seriesRealGenreProvider.overrideWith((ref, query) => hasFavorites
                  ? (query.id == 'A' ? genreA.future : genreB.future)
                  : Future.value(query.catalogGenre)),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: isMovie ? const VodScreen() : const SeriesScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Sort'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('By affinity'));
          await tester.pumpAndSettle();

          List<MediaCard> cards() =>
              tester.widgetList<MediaCard>(find.byType(MediaCard)).toList();
          expect(cards().map((c) => c.title), ['A', 'B']);
          expect(cards().first.matchPercent,
              greaterThan(cards().last.matchPercent!));

          if (hasFavorites) {
            if (reverseBeforeResolution) {
              await tester.tap(find.byTooltip('Descending order'));
              await tester.pumpAndSettle();
              expect(cards().map((c) => c.title), ['B', 'A']);
            }
            final cardB = find.byWidgetPredicate(
              (widget) => widget is MediaCard && widget.title == 'B',
            );
            Focus.of(tester.element(cardB)).requestFocus();
            await tester.pump();
            final focused = FocusManager.instance.primaryFocus;
            genreA.complete('Other');
            genreB.complete('Action');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pumpAndSettle();
            expect(cards().map((c) => c.title),
                reverseBeforeResolution ? ['A', 'B'] : ['B', 'A']);
            if (reverseBeforeResolution) {
              expect(cards().first.matchPercent,
                  lessThan(cards().last.matchPercent!));
            } else {
              expect(cards().first.matchPercent,
                  greaterThan(cards().last.matchPercent!));
            }
            expect(FocusManager.instance.primaryFocus, same(focused));
          }

          await tester.tap(find.byTooltip(reverseBeforeResolution
              ? 'Ascending order'
              : 'Descending order'));
          await tester.pumpAndSettle();
          expect(
              cards().map((c) => c.title),
              reverseBeforeResolution
                  ? ['B', 'A']
                  : (hasFavorites ? ['A', 'B'] : ['B', 'A']));
          if (reverseBeforeResolution) {
            expect(cards().first.matchPercent,
                greaterThan(cards().last.matchPercent!));
          } else {
            expect(cards().first.matchPercent,
                lessThan(cards().last.matchPercent!));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
