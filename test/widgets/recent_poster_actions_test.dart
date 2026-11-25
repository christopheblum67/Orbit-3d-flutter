import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_watch_style_button.dart';
import 'package:orbit_3d_flutter/features/browse/browse_screen.dart';
import 'package:orbit_3d_flutter/features/series/series_screen.dart';
import 'package:orbit_3d_flutter/features/vod/vod_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/catalog_db_provider.dart';
import 'package:orbit_3d_flutter/providers/category_change_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecentService extends RecentlyWatchedService {
  final entries = <String, RecentEntry>{};

  @override
  Future<List<RecentEntry>> loadForProfile(String profileId) async =>
      entries.values.where((e) => e.profileId == profileId).toList();

  @override
  Future<void> save(RecentEntry entry) async => entries[entry.key] = entry;

  @override
  Future<void> remove(String key) async {
    entries.remove(key);
  }
}

class _FavoritesService extends FavoritesService {
  final entries = <String, FavoriteEntry>{};

  @override
  Future<List<FavoriteEntry>> loadForSubscription(
    String profileId,
    String subscriptionId, {
    bool Function()? canMigrateLegacy,
  }) async =>
      entries.values
          .where((e) =>
              e.profileId == profileId && e.subscriptionId == subscriptionId)
          .toList();

  @override
  Future<void> save(FavoriteEntry entry) async => entries[entry.key] = entry;
}

class _Preferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

class _Filters extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(subscriptionId: 'sub');
}

void main() {
  for (final screen in ['vod', 'series', 'browse', 'browse-series']) {
    for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
      for (final size in [
        if (screen == 'vod') const Size(640, 360),
        const Size(1280, 720),
      ]) {
        testWidgets(
            '$screen recent poster menu handles remote and touch in $language at $size',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final isSeries = screen == 'series' || screen == 'browse-series';
          final type = isSeries ? ContentType.series : ContentType.vod;
          final movie = Movie.fromMap({
            'stream_id': '42',
            'name': 'Sample movie',
            'category_id': 'cat',
          });
          final series = Series.fromMap({
            'series_id': '42',
            'name': 'Sample series',
            'category_id': 'cat',
          });
          final recent = _RecentService();
          final otherProfile = RecentEntry(
            type: type,
            id: '42',
            title: 'Other profile',
            profileId: 'other',
            watchedAt: DateTime(2026),
          );
          final watched = RecentEntry(
            type: type,
            id: '42',
            title: isSeries ? series.title : movie.title,
            profileId: 'profile',
            watchedAt: DateTime(2026),
          );
          recent.entries
              .addAll({watched.key: watched, otherProfile.key: otherProfile});
          final favorites = _FavoritesService();
          final subscription = Subscription(
            id: 'sub',
            name: 'Test',
            type: SubscriptionType.xtream,
            createdAt: DateTime(2020),
          );
          final unresolved = Completer<String?>();
          final container = ProviderContainer(overrides: [
            recentlyWatchedServiceProvider.overrideWithValue(recent),
            favoritesServiceProvider.overrideWithValue(favorites),
            activeSubscriptionProvider.overrideWithValue(subscription),
            subscriptionsProvider
                .overrideWithBuild((ref, notifier) => [subscription]),
            currentProfileProvider
                .overrideWithBuild((ref, notifier) => UserProfile(
                      id: 'profile',
                      firstName: 'Test',
                      dateOfBirth: DateTime(2000),
                      gender: 'male',
                      favoriteGenres: const [],
                    )),
            preferencesProvider.overrideWith(_Preferences.new),
            vodCategoryFilterProvider.overrideWith(_Filters.new),
            profileAffinityScorerProvider.overrideWith((ref) => null),
            categoryIncreasesProvider((
              subscriptionId: 'sub',
              catalog:
                  isSeries ? CategoryCatalog.series : CategoryCatalog.movies,
            )).overrideWith((ref) async => const CategoryChanges()),
            catalogDbKeyProvider(type == ContentType.vod
                    ? CatalogKind.vod
                    : CatalogKind.series)
                .overrideWith((ref) => unresolved.future),
            moviesProvider.overrideWith((ref) async => [movie]),
            seriesProvider.overrideWith((ref) async => [series]),
            vodCategoriesProvider.overrideWith((ref) async =>
                const [MediaCategory(id: 'cat', name: 'Category')]),
            seriesCategoriesProvider.overrideWith((ref) async =>
                const [MediaCategory(id: 'cat', name: 'Category')]),
            vodGridEnrichmentsProvider.overrideWith((ref) async => {}),
            movieXtreamPosterProvider.overrideWith((ref, movie) async => null),
            movieTmdbPosterProvider.overrideWith((ref, movie) async => null),
          ]);
          addTearDown(container.dispose);
          final router = GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => switch (screen) {
                'vod' => const VodScreen(),
                'series' => const SeriesScreen(),
                _ => const BrowseScreen(),
              },
            ),
          ]);
          addTearDown(router.dispose);
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
            ),
          ));
          await tester.pumpAndSettle();
          final l = lookupAppLocalizations(Locale(language));
          if (screen == 'browse-series') {
            await tester.tap(find.text(l.series).first);
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const ValueKey('recent')));
          await tester.pumpAndSettle();
          final card = find.byType(MediaCard);
          expect(card, findsOneWidget);
          final tile =
              find.ancestor(of: card, matching: find.byType(TvFocus)).first;
          final animated =
              find.descendant(of: tile, matching: find.byType(AnimatedBuilder));
          Focus.of(tester.element(animated.first)).requestFocus();
          await tester.pumpAndSettle();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(find.text(l.favoritesAdd), findsOneWidget);
          expect(find.text(l.recentRemove.toUpperCase()), findsOneWidget);
          final buttons = tester
              .widgetList<TvWatchStyleButton>(find.byType(TvWatchStyleButton))
              .toList();
          expect(buttons, hasLength(2));
          expect(buttons[0].label, l.favoritesAdd);
          expect(buttons[1].label, l.recentRemove);
          expect(buttons[1].focusNode.hasPrimaryFocus, isTrue);
          expect(find.byType(FilledButton), findsNWidgets(2));
          final dialogBounds = tester.getRect(find.byType(AlertDialog));
          for (final button in find.byType(FilledButton).evaluate()) {
            final rect = tester.getRect(find.byWidget(button.widget));
            expect(rect.left, greaterThanOrEqualTo(dialogBounds.left));
            expect(rect.right, lessThanOrEqualTo(dialogBounds.right));
            expect(rect.top, greaterThanOrEqualTo(dialogBounds.top));
            expect(rect.bottom, lessThanOrEqualTo(dialogBounds.bottom));
          }
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(find.text(l.recentRemove.toUpperCase()), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(buttons[0].focusNode.hasPrimaryFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(buttons[1].focusNode.hasPrimaryFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(
              container.read(favoritesProvider.notifier).isFavorite(type, '42'),
              isTrue);
          expect(recent.entries.containsKey(watched.key), isTrue);
          await tester.longPress(find.byType(MediaCard));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(favorites.entries, hasLength(1));
          await tester.longPress(find.byType(MediaCard));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(recent.entries.containsKey(watched.key), isTrue);
          await tester.longPress(find.byType(MediaCard));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(recent.entries.containsKey(watched.key), isFalse);
          expect(recent.entries.containsKey(otherProfile.key), isTrue);
          expect(container.read(recentlyWatchedProvider), isEmpty);
          expect(find.byType(MediaCard), findsNothing);
          expect(favorites.entries, hasLength(1));
          expect(tester.takeException(), isNull);
          unresolved.complete(null);
        });
      }
    }
  }
}
