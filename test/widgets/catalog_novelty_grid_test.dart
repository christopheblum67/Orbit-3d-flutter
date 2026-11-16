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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final isMovie in [true, false]) {
    testWidgets(
        '${isMovie ? 'movie' : 'series'} grid highlights only additions',
        (tester) async {
      final catalog = isMovie ? CategoryCatalog.movies : CategoryCatalog.series;
      final kind = isMovie ? CatalogKind.vod : CatalogKind.series;
      final movie = Movie(
        id: 'new',
        title: 'Nouveau film',
        description: '',
        posterUrl: '',
        year: 0,
        genre: '',
        director: '',
        rating: 0,
        pegi: '',
        streamId: 'new',
        categoryId: 'cat',
      );
      final series = Series(
        id: 'new',
        title: 'Nouvelle série',
        description: '',
        coverUrl: '',
        year: 0,
        genre: '',
        director: '',
        rating: 0,
        pegi: '',
        episodes: const [],
        categoryId: 'cat',
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
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
          catalogDbKeyProvider(kind).overrideWith((ref) async => null),
          categoryIncreasesProvider((subscriptionId: 'sub', catalog: catalog))
              .overrideWith((ref) async => const CategoryChanges(
                    categories: {'cat': (total: 2, added: 1)},
                    newIds: {'new'},
                  )),
          moviesProvider.overrideWith((ref) async => [
                movie,
                Movie.fromMap({
                  'stream_id': 'old',
                  'name': 'Ancien film',
                  'category_id': 'cat',
                }),
              ]),
          seriesProvider.overrideWith((ref) async => [
                series,
                Series.fromMap({
                  'series_id': 'old',
                  'name': 'Ancienne série',
                  'category_id': 'cat',
                }),
              ]),
          vodCategoriesProvider.overrideWith((ref) async =>
              const [MediaCategory(id: 'cat', name: 'Catégorie')]),
          seriesCategoriesProvider.overrideWith((ref) async =>
              const [MediaCategory(id: 'cat', name: 'Catégorie')]),
          vodGridEnrichmentsProvider.overrideWith((ref) async => {}),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: isMovie ? const VodScreen() : const SeriesScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      final cards =
          tester.widgetList<MediaCard>(find.byType(MediaCard)).toList();
      expect(cards, hasLength(2));
      expect(
          cards
              .singleWhere((card) => card.title.startsWith('Nouve'))
              .highlightTitle,
          isTrue);
      expect(
          cards
              .singleWhere((card) => card.title.startsWith('Ancien'))
              .highlightTitle,
          isFalse);
      final title = tester
          .widget<Text>(find.text(isMovie ? 'Nouveau film' : 'Nouvelle série'));
      expect(title.style!.color, Colors.red.shade800);
      expect(title.style!.fontWeight, FontWeight.w900);
      expect(find.textContaining('(+1)', findRichText: true), findsOneWidget);
    });
  }
}
