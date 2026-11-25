import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/vod/vod_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/catalog_db_provider.dart';
import 'package:orbit_3d_flutter/providers/category_change_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

class _Filters extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(subscriptionId: 'sub');
}

void main() {
  testWidgets('a failed catalog poster tries Xtream then TMDB', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final movie = Movie.fromMap({
      'stream_id': '42',
      'name': 'Film',
      'stream_icon': 'https://example.invalid/catalog.jpg',
    });
    final calls = <String>[];
    final container = ProviderContainer(overrides: [
      activeSubscriptionProvider.overrideWithValue(Subscription(
        id: 'sub',
        name: 'Test',
        type: SubscriptionType.xtream,
        createdAt: DateTime(2020),
      )),
      preferencesProvider.overrideWith(_Preferences.new),
      vodCategoryFilterProvider.overrideWith(_Filters.new),
      subscriptionsProvider.overrideWithBuild((ref, notifier) => []),
      profileAffinityScorerProvider.overrideWith((ref) => null),
      catalogDbKeyProvider(CatalogKind.vod).overrideWith((ref) async => null),
      categoryIncreasesProvider((
        subscriptionId: 'sub',
        catalog: CategoryCatalog.movies,
      )).overrideWith((ref) async => const CategoryChanges()),
      moviesProvider.overrideWith((ref) async => [movie]),
      vodCategoriesProvider
          .overrideWith((ref) async => const <MediaCategory>[]),
      vodGridEnrichmentsProvider.overrideWith((ref) async => {}),
      movieXtreamPosterProvider.overrideWith((ref, movie) async {
        calls.add('xtream');
        return 'https://example.invalid/xtream.jpg';
      }),
      movieTmdbPosterProvider.overrideWith((ref, movie) async {
        calls.add('tmdb');
        return 'https://example.invalid/tmdb.jpg';
      }),
    ]);
    addTearDown(container.dispose);

    Widget app(Widget child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: Center(child: child)),
          ),
        );

    await tester.pumpWidget(app(const VodScreen()));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TvFocus>(
        find.ancestor(
          of: find.byType(MediaCard).first,
          matching: find.byType(TvFocus),
        ).first,
      ).fillFocusBackground,
      isTrue,
    );
    final card = tester.widget<MediaCard>(find.byType(MediaCard).first);
    final context = tester.element(find.byType(MediaCard).first);
    final candidate =
        card.posterFallbackBuilder!(context, const Icon(Icons.error));
    await tester
        .pumpWidget(app(SizedBox(width: 160, height: 240, child: candidate)));
    await tester.pump();
    final xtream = tester.widget<OrbitCachedImage>(find.byWidgetPredicate(
      (widget) =>
          widget is OrbitCachedImage &&
          widget.imageUrl == 'https://example.invalid/xtream.jpg',
    ));
    expect(calls, contains('xtream'));
    final tmdb = xtream.errorWidget!(context, xtream.imageUrl, Exception());
    await tester
        .pumpWidget(app(SizedBox(width: 160, height: 240, child: tmdb)));
    await tester.pump();
    expect(
      find.byWidgetPredicate((widget) =>
          widget is OrbitCachedImage &&
          widget.imageUrl == 'https://example.invalid/tmdb.jpg'),
      findsOneWidget,
    );
    expect(calls, containsAllInOrder(['xtream', 'tmdb']));
  });
}
