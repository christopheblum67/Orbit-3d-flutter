import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/features/matchmaking/matchmaking_screen.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/matchmaking_tab.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/prolong_decision_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';

class _MemoryStorage extends StorageService {
  final settings = <String, dynamic>{};

  @override
  dynamic getSetting(String key) => settings[key];

  @override
  Future<void> setSetting(String key, dynamic value) async {
    settings[key] = value;
  }
}

class _TestPreferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

class _SortRevision extends Notifier<int> {
  @override
  int build() => 0;
  void update() => state++;
}

final _sortRevisionProvider = NotifierProvider<_SortRevision, int>(_SortRevision.new);

class _MemoryFavorites extends FavoritesService {
  final entries = <String, FavoriteEntry>{};

  @override
  Future<List<FavoriteEntry>> loadForSubscription(
    String profileId,
    String subscriptionId, {
    bool Function()? canMigrateLegacy,
  }) async =>
      entries.values
          .where((entry) =>
              entry.profileId == profileId &&
              entry.subscriptionId == subscriptionId)
          .toList();

  @override
  Future<void> save(FavoriteEntry entry) async => entries[entry.key] = entry;

  @override
  Future<void> remove(String key) async => entries.remove(key);
}

void main() {
  final profile = UserProfile(
    id: 'one',
    firstName: 'Alex',
    dateOfBirth: DateTime(2000),
    gender: '',
    favoriteGenres: const [],
  );
  final other = profile.copyWith(id: 'two', firstName: 'Camille');

  testWidgets('keeps focus on the same recommendation after reranking',
      (tester) async {
    final first = ScoredReco(
      Recommendation.fromMetadata(
        kind: RecommendationKind.movie, id: 'a', title: 'A',
      ),
      70, 0, 0, affinity: .7,
    );
    final second = ScoredReco(
      Recommendation.fromMetadata(
        kind: RecommendationKind.movie, id: 'b', title: 'B',
      ),
      70, 0, 0, affinity: .7,
    );
    final container = ProviderContainer(overrides: [
      preferencesProvider.overrideWith(_TestPreferences.new),
      currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
      matchmakingTabProvider.overrideWith((ref, id) async {
        final revision = ref.watch(_sortRevisionProvider);
        return (
          movies: revision == 0 ? [first, second] : [second, first],
          series: <ScoredReco>[],
        );
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MatchmakingTab(kind: RecommendationKind.movie)),
      ),
    ));
    await tester.pumpAndSettle();
    final card = find.byWidgetPredicate(
      (widget) => widget is MediaCard && widget.title == 'B',
    );
    Focus.of(tester.element(card)).requestFocus();
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus;
    container.read(_sortRevisionProvider.notifier).update();
    await tester.pumpAndSettle();
    expect(tester.widgetList<MediaCard>(find.byType(MediaCard)).map((c) => c.title),
        ['B', 'A']);
    expect(FocusManager.instance.primaryFocus, same(focused));
  });

  testWidgets('les onglets de recommandations suivent la langue',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
          affinityBackgroundEnrichmentProvider.overrideWith((ref) async {}),
          matchmakingTabProvider.overrideWith((ref, id) async =>
              (movies: <ScoredReco>[], series: <ScoredReco>[])),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MatchmakingScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.widgetWithText(Tab, 'Movies'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Series'), findsOneWidget);
    expect(find.text('Affinity ↓'), findsOneWidget);
    expect(find.byTooltip('Sort'), findsOneWidget);
  });

  testWidgets('mode buttons highlight D-pad focus independently of selection',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        profilesProvider.overrideWith((ref) async => [profile, other]),
        matchmakingTabProvider.overrideWith((ref, id) async =>
            (movies: <ScoredReco>[], series: <ScoredReco>[])),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MatchmakingTab(kind: RecommendationKind.movie)),
      ),
    ));
    await tester.pumpAndSettle();
    final forYou = find.text('For You');
    final group = find.text('Group');
    TextButton button(Finder label) => tester.widget<TextButton>(
          find.ancestor(of: label, matching: find.byType(TextButton)).first,
        );
    Color? background(Finder label) => button(label)
        .style!
        .backgroundColor!
        .resolve(button(label).statesController!.value);
    Color? foreground(Finder label) => button(label)
        .style!
        .foregroundColor!
        .resolve(button(label).statesController!.value);

    Focus.of(tester.element(forYou)).requestFocus();
    await tester.pumpAndSettle();
    expect(background(forYou), const Color(0xFF1565C0));
    expect(foreground(forYou), Colors.white);
    expect(background(group), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(background(group), const Color(0xFF1565C0));
    expect(foreground(group), Colors.white);
    expect(background(forYou), isNull);
    final modeSwitcher = find.byWidgetPredicate((w) => w is SegmentedButton);
    final selectedBefore =
        tester.widget<SegmentedButton>(modeSwitcher).selected;
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<SegmentedButton>(modeSwitcher).selected,
        isNot(selectedBefore));
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh rebuilds solo and group recommendations from the D-pad',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var soloBuilds = 0;
    var groupBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        matchmakingTabProvider.overrideWith((ref, id) async {
          soloBuilds++;
          return (movies: <ScoredReco>[], series: <ScoredReco>[]);
        }),
        matchmakingGroupTabProvider.overrideWith((ref, key) async {
          groupBuilds++;
          return (movies: <GroupReco>[], series: <GroupReco>[]);
        }),
      ],
    );
    addTearDown(container.dispose);
    final groupKey = profileGroupCacheKey(['one', 'two']);
    final groupSubscription = container.listen(
      matchmakingGroupTabProvider(groupKey),
      (_, __) {},
    );
    addTearDown(groupSubscription.close);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MatchmakingTab(kind: RecommendationKind.movie)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(soloBuilds, 1);
    expect(groupBuilds, 1);
    final refresh = find.byTooltip('Actualiser les recommandations');
    expect(refresh, findsOneWidget);
    Focus.of(tester.element(find.byIcon(Icons.refresh))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(soloBuilds, 2);
    expect(groupBuilds, 2);
    expect(tester.takeException(), isNull);
  });

  for (final kind in RecommendationKind.values) {
    for (final group in [false, true]) {
      testWidgets('${kind.name} ${group ? "group" : "solo"} opens the menu',
          (tester) async {
        final reco = Recommendation.fromMetadata(kind: kind, title: 'Test');
        final scored = ScoredReco(reco, 1, 0, 0);
        final grouped = GroupReco(reco: reco, affinities: [0.5, 0.6]);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWith(_TestPreferences.new),
              currentProfileProvider
                  .overrideWithBuild((ref, notifier) => profile),
              activeSubscriptionProvider.overrideWith((ref) => null),
              profilesProvider.overrideWith((ref) async => [profile, other]),
              matchmakingTabProvider.overrideWith(
                (ref, id) async => (movies: [scored], series: [scored]),
              ),
              matchmakingGroupTabProvider.overrideWith(
                (ref, key) async => (movies: [grouped], series: [grouped]),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: MatchmakingTab(
                  kind: kind,
                  initialGroup: group ? ['one', 'two'] : null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
        await tester.pumpAndSettle();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
        await tester.pumpAndSettle();

        expect(
          find.text(kind == RecommendationKind.movie
              ? 'Film déjà vu'
              : 'Série déjà vue'),
          findsOneWidget,
        );
        expect(find.text('Pas intéressé'), findsOneWidget);
        expect(find.text('Ajouter aux favoris'), findsOneWidget);
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'held OK opens the group decision without selecting or confirming',
      (tester) async {
    final storage = _MemoryStorage();
    final reco = Recommendation.fromMetadata(
      kind: RecommendationKind.movie,
      title: 'Test',
    );
    final grouped = GroupReco(reco: reco, affinities: [0.5, 0.6]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        preferencesProvider.overrideWith(_TestPreferences.new),
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        activeSubscriptionProvider.overrideWith((ref) => null),
        profilesProvider.overrideWith((ref) async => [profile, other]),
        matchmakingGroupTabProvider.overrideWith(
          (ref, key) async => (movies: [grouped], series: [grouped]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MatchmakingTab(
            kind: RecommendationKind.movie,
            initialGroup: ['one', 'two'],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Film déjà vu'), findsOneWidget);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Film déjà vu'), findsOneWidget);
    expect(storage.settings, isEmpty);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmer'))
            .onPressed,
        isNull);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.settings, isEmpty);
    expect(find.text('Confirmer'), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.settings, isEmpty);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmer'))
            .onPressed,
        isNotNull);
    expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.settings['seen_recos_one'], contains(reco.id));
    Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pas intéressé'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
        isTrue);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(storage.settings['dismissed_recos_one'], contains(reco.id));
  });

  for (final kind in RecommendationKind.values) {
    for (final group in [false, true]) {
      testWidgets(
          'favorite ${kind.name} belongs to current profile, group=$group',
          (tester) async {
        tester.view.physicalSize = const Size(800, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final favorites = _MemoryFavorites();
        final subscription = Subscription(
          id: 'subscription',
          name: 'Test',
          type: SubscriptionType.m3u,
          createdAt: DateTime(2020),
        );
        final reco = kind == RecommendationKind.movie
            ? Recommendation(
                kind: kind,
                movie: Movie(
                  id: 'film',
                  title: 'Film test',
                  description: '',
                  posterUrl: '',
                  year: 2020,
                  genre: '',
                  director: '',
                  rating: 0,
                  pegi: '',
                  streamId: 'film',
                ),
              )
            : Recommendation(
                kind: kind,
                series: Series(
                  id: 'serie',
                  title: 'Série test',
                  description: '',
                  coverUrl: '',
                  year: 2020,
                  genre: 'Drame',
                  director: '',
                  rating: 0,
                  pegi: '',
                  episodes: const [],
                ),
              );
        final scored = ScoredReco(reco, 1, 0, 0);
        final grouped = GroupReco(reco: reco, affinities: [0.5, 0.6]);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            preferencesProvider.overrideWith(_TestPreferences.new),
            currentProfileProvider
                .overrideWithBuild((ref, notifier) => profile),
            profilesProvider.overrideWith((ref) async => [profile, other]),
            activeSubscriptionProvider.overrideWith((ref) => subscription),
            subscriptionsProvider
                .overrideWithBuild((ref, notifier) => [subscription]),
            favoritesServiceProvider.overrideWithValue(favorites),
            matchmakingTabProvider.overrideWith(
              (ref, id) async => (movies: [scored], series: [scored]),
            ),
            matchmakingGroupTabProvider.overrideWith(
              (ref, key) async => (movies: [grouped], series: [grouped]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MatchmakingTab(
                kind: kind,
                initialGroup: group ? ['one', 'two'] : null,
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        Future<void> addFavorite() async {
          Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
          await tester.pump();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(
            Focus.of(tester.element(find.text('Ajouter aux favoris'))).hasFocus,
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(
              Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
              isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
        }

        await addFavorite();
        expect(favorites.entries, hasLength(1));
        final entry = favorites.entries.values.single;
        expect(entry.id, reco.id);
        expect(
            entry.type,
            kind == RecommendationKind.movie
                ? ContentType.vod
                : ContentType.series);
        expect(entry.profileId, profile.id);
        expect(entry.subscriptionId, subscription.id);
        await addFavorite();
        expect(favorites.entries, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('small screen scrolls options and rejects a missing favorite ID',
      (tester) async {
    tester.view.physicalSize = const Size(480, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final favorites = _MemoryFavorites();
    final subscription = Subscription(
      id: 'subscription',
      name: 'Test',
      type: SubscriptionType.m3u,
      createdAt: DateTime(2020),
    );
    final reco = Recommendation.fromMetadata(
      kind: RecommendationKind.movie,
      title: 'Test',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        activeSubscriptionProvider.overrideWith((ref) => subscription),
        subscriptionsProvider
            .overrideWithBuild((ref, notifier) => [subscription]),
        favoritesServiceProvider.overrideWithValue(favorites),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: Consumer(builder: (context, ref, _) {
          return TextButton(
            onPressed: () => showProlongDecision(context, ref, reco),
            child: const Text('Ouvrir'),
          );
        })),
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Ajouter aux favoris'))).hasFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Ce contenu ne peut pas être ajouté aux favoris.'),
        findsOneWidget);
    expect(favorites.entries, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decision options remain tappable and cancellation is harmless',
      (tester) async {
    bool? result;
    final reco = Recommendation.fromMetadata(
      kind: RecommendationKind.movie,
      title: 'Test',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        activeSubscriptionProvider.overrideWith((ref) => null),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Consumer(builder: (context, ref, _) {
          return TextButton(
            onPressed: () async {
              result = await showProlongDecision(context, ref, reco);
            },
            child: const Text('Ouvrir'),
          );
        })),
      ),
    ));

    for (final option in [
      'Film déjà vu',
      'Pas intéressé',
      'Ajouter aux favoris',
    ]) {
      result = null;
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Confirmer'))).hasPrimaryFocus,
          isTrue);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected group profile has a halo and contrasting color',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        profilesProvider.overrideWith((ref) async => [profile, other]),
        matchmakingGroupTabProvider.overrideWith(
          (ref, key) async => (movies: <GroupReco>[], series: <GroupReco>[]),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MatchmakingTab(
            kind: RecommendationKind.movie,
            initialGroup: ['one', 'two'],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(FilterChip, 'Camille');
    final container = find.byKey(const ValueKey('matchmaking-profile-two'));
    BoxDecoration decoration() =>
        tester.widget<AnimatedContainer>(container).decoration!
            as BoxDecoration;
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(decoration().boxShadow, isNotEmpty);
    expect(tester.widget<FilterChip>(chip).selectedColor,
        Theme.of(tester.element(chip)).colorScheme.primary);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    expect(decoration().boxShadow, isEmpty);
  });
}
