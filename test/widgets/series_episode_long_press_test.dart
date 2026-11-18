import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/series/series_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _WatchedService extends WatchedEpisodesService {
  final entries = <WatchedEpisodeEntry>[];
  bool failRemove = false;

  @override
  Future<List<WatchedEpisodeEntry>> loadForProfile(String profileId) async =>
      entries.where((e) => e.profileId == profileId).toList();

  @override
  Future<void> save(WatchedEpisodeEntry entry) async {
    entries.removeWhere((e) => e.key == entry.key);
    entries.add(entry);
  }

  @override
  Future<void> remove(String key) async {
    if (failRemove) throw StateError('suppression impossible');
    entries.removeWhere((e) => e.key == key);
  }
}

class _Progress extends PlaybackProgressService {
  PlaybackProgress? progress;
  @override
  PlaybackProgress? get(String id) => progress;
  @override
  Future<void> clear(String id) async {
    progress = null;
    notifyListeners();
  }
}

void main() {
  final episode = Episode(
    id: 'episode',
    title: 'Episode',
    season: 1,
    episodeNumber: 1,
    streamUrl: '',
  );
  final series = Series(
    id: 'series',
    title: 'Series',
    description: '',
    coverUrl: '',
    year: 0,
    genre: '',
    director: '',
    rating: 0,
    pegi: '',
    episodes: [episode],
  );
  final profile = UserProfile(
    id: 'profile',
    firstName: 'Test',
    dateOfBirth: DateTime(2000),
    gender: 'male',
    favoriteGenres: const [],
  );

  Future<void> open(
      WidgetTester tester, _WatchedService watched, _Progress progress,
      {List<Actor> cast = const [],
      Map<int, List<Actor>> guests = const {},
      Series? customSeries,
      Size size = const Size(1920, 1080),
      double textScale = 1}) async {
    SharedPreferences.setMockInitialValues({});
    final selectedSeries = customSeries ?? series;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const SeriesDetailScreen(seriesId: 'series')),
      GoRoute(
          path: '/actor/detail',
          builder: (_, state) => Text(
              'Biographie ${(state.extra as Actor).name}',
              textDirection: TextDirection.ltr)),
      GoRoute(
          path: '/episode/detail',
          builder: (_, state) {
            final (_, episode) = state.extra! as (Series, Episode);
            return Text('Détail ${episode.id}',
                textDirection: TextDirection.ltr);
          }),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        seriesInfoProvider('series')
            .overrideWith((ref) async => selectedSeries),
        seriesDetailProvider(selectedSeries).overrideWith((ref) async =>
            SeriesDetail.fromSeries(selectedSeries)
                .copyWith(cast: cast, guestStarsPerSeason: guests)),
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        watchedEpisodesServiceProvider.overrideWithValue(watched),
        playbackProgressServiceProvider.overrideWith((ref) => progress),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('season-episode-0'));
    if (tile.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'saisons proches des épisodes et navigation D-pad dans le carrousel',
      (tester) async {
    final episodes = [
      for (var season = 1; season <= 2; season++)
        for (var number = 1; number <= 32; number++)
          Episode(
            id: '$season-$number',
            title: number == 1
                ? 'Series - S0${season}E01 - Un titre suffisamment long pour occuper plusieurs lignes'
                : 'Épisode $number',
            season: season,
            episodeNumber: number,
            streamUrl: 'https://example.test/episode',
          ),
    ];
    final testSeries = Series(
      id: 'series',
      title: 'Series',
      description: '',
      coverUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: episodes,
    );
    await open(tester, _WatchedService(), _Progress(),
        customSeries: testSeries, size: const Size(960, 540));
    expect(find.text('S01E01'), findsOneWidget);
    expect(
        find.byTooltip(
            'S01E01 - Un titre suffisamment long pour occuper plusieurs lignes'),
        findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Saison 2'),
      -200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Saison 1'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Saison 2'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('S02E01'), findsOneWidget);
    expect(find.text('S01E01'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TvFocus>(),
        isNotNull);
    final first = find.text('S02E01');
    Focus.of(tester.element(first)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
        Focus.of(tester.element(find.text('S02E02'))).hasPrimaryFocus, isTrue);
    for (var i = 0; i < 25; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(
        Focus.of(tester.element(find.text('S02E27'))).hasPrimaryFocus, isTrue);
    expect(find.text('27 / 32'), findsOneWidget);
    for (var i = 0; i < 26; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    expect(
        Focus.of(tester.element(find.text('S02E01'))).hasPrimaryFocus, isTrue);
    expect(find.text('1 / 32'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Détail 2-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les cercles reprennent la progression sur petit écran',
      (tester) async {
    final progress = _Progress()
      ..progress = const PlaybackProgress(
          positionMs: 200, durationMs: 1000, updatedAt: 0);
    await open(tester, _WatchedService(), progress,
        size: const Size(320, 640), textScale: 2);
    final seasonTile = find.byKey(const ValueKey('season-episode-0'));
    expect(find.descendant(of: seasonTile, matching: find.text('S01E01')),
        findsOneWidget);
    expect(find.descendant(of: seasonTile, matching: find.text('Reprendre')),
        findsOneWidget);
    expect(
        find.descendant(
            of: seasonTile, matching: find.byType(LinearProgressIndicator)),
        findsOneWidget);
    final resumeTile = find.byKey(const ValueKey('resume-episode-0'));
    await tester.scrollUntilVisible(
      resumeTile,
      -200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.descendant(of: resumeTile, matching: find.text('S01E01')),
        findsOneWidget);
    expect(find.descendant(of: resumeTile, matching: find.text('Reprendre')),
        findsOneWidget);
    expect(
        find.descendant(
            of: resumeTile, matching: find.byType(LinearProgressIndicator)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les acteurs principaux et invités ouvrent leur biographie',
      (tester) async {
    final actor = Actor(
        id: '1', name: 'Acteur principal', character: '', profilePath: '');
    final guest = Actor(
        id: '2',
        name: 'Acteur invité',
        character: '',
        profilePath: '',
        isGuestStar: true);
    await open(tester, _WatchedService(), _Progress(), cast: [
      actor
    ], guests: {
      1: [guest]
    });
    await tester.ensureVisible(find.text('Acteur principal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acteur principal'));
    await tester.pumpAndSettle();
    expect(find.text('Biographie Acteur principal'), findsOneWidget);
    GoRouter.of(tester.element(find.text('Biographie Acteur principal'))).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Acteur invité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acteur invité'));
    await tester.pumpAndSettle();
    expect(find.text('Biographie Acteur invité'), findsOneWidget);
  });

  testWidgets('le badge réagit à une pression longue dans les deux états',
      (tester) async {
    final watched = _WatchedService();
    await open(tester, watched, _Progress());
    await tester.longPress(find.byTooltip('Marquer comme vu'));
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme vu ?'), findsOneWidget);
    await tester.tap(find.text('Marquer comme vu').last);
    await tester.pumpAndSettle();
    expect(watched.entries, hasLength(1));
    expect(find.text('1/1 vus'), findsOneWidget);
    await tester.longPress(find.byTooltip('Marquer comme non vu'));
    await tester.pumpAndSettle();
    expect(find.text("Réinitialiser l'épisode ?"), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(watched.entries, hasLength(1));
  });

  testWidgets(
      'le relâchement et les répétitions de OK ne ferment pas le dialogue',
      (tester) async {
    final watched = _WatchedService();
    await open(tester, watched, _Progress());
    final tile = find
        .ancestor(
          of: find.byTooltip('Marquer comme vu'),
          matching: find.byType(TvFocus),
        )
        .first;
    final focusChild =
        find.descendant(of: tile, matching: find.byType(AnimatedBuilder)).first;
    Focus.of(tester.element(focusChild)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme vu ?'), findsOneWidget);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme vu ?'), findsOneWidget);
    expect(watched.entries, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(watched.entries, hasLength(1));
    final watchedTile = find
        .ancestor(
          of: find.byTooltip('Marquer comme non vu'),
          matching: find.byType(TvFocus),
        )
        .first;
    final watchedFocus = find
        .descendant(
          of: watchedTile,
          matching: find.byType(AnimatedBuilder),
        )
        .first;
    Focus.of(tester.element(watchedFocus)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text("Réinitialiser l'épisode ?"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(watched.entries, isEmpty);
  });

  testWidgets(
      'réinitialiser un épisode auto-vu efface sa progression sans le marquer vu',
      (tester) async {
    final watched = _WatchedService();
    final progress = _Progress()
      ..progress = const PlaybackProgress(
          positionMs: 850, durationMs: 1000, updatedAt: 0);
    await open(tester, watched, progress);
    await tester.longPress(find.byTooltip('Marquer comme non vu'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(
        find.descendant(of: dialog, matching: find.byType(TextButton)).last);
    await tester.pumpAndSettle();
    expect(progress.progress, isNull);
    expect(watched.entries, isEmpty);
    expect(find.byTooltip('Marquer comme vu'), findsOneWidget);
  });

  testWidgets('une erreur de suppression conserve le badge vu', (tester) async {
    final watched = _WatchedService();
    await open(tester, watched, _Progress());
    await tester.tap(find.byTooltip('Marquer comme vu'));
    await tester.pumpAndSettle();
    watched.failRemove = true;
    await tester.longPress(find.byTooltip('Marquer comme non vu'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(
        find.descendant(of: dialog, matching: find.byType(TextButton)).last);
    await tester.pumpAndSettle();
    expect(watched.entries, hasLength(1));
    expect(find.byTooltip('Marquer comme non vu'), findsOneWidget);
    expect(find.text('Impossible de modifier le statut de cet épisode.'),
        findsOneWidget);
    expect(find.text('1/1 vus'), findsOneWidget);
  });
}
