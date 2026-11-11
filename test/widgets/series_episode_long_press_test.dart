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

  Future<void> open(WidgetTester tester, _WatchedService watched, _Progress progress, {List<Actor> cast = const [], Map<int, List<Actor>> guests = const {}}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SeriesDetailScreen(seriesId: 'series')),
      GoRoute(path: '/actor/detail', builder: (_, state) => Text('Biographie ${(state.extra as Actor).name}', textDirection: TextDirection.ltr)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        seriesInfoProvider('series').overrideWith((ref) async => series),
        seriesDetailProvider(series).overrideWith((ref) async => SeriesDetail.fromSeries(series).copyWith(cast: cast, guestStarsPerSeason: guests)),
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        watchedEpisodesServiceProvider.overrideWithValue(watched),
        playbackProgressServiceProvider.overrideWith((ref) => progress),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip(
      progress.progress != null && progress.progress!.fraction >= 0.8
          ? 'Marquer comme non vu'
          : 'Marquer comme vu',
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('les acteurs principaux et invités ouvrent leur biographie', (tester) async {
    final actor = Actor(id: '1', name: 'Acteur principal', character: '', profilePath: '');
    final guest = Actor(id: '2', name: 'Acteur invité', character: '', profilePath: '', isGuestStar: true);
    await open(tester, _WatchedService(), _Progress(), cast: [actor], guests: {1: [guest]});
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

  testWidgets('le badge réagit à une pression longue dans les deux états', (tester) async {
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

  testWidgets('le relâchement et les répétitions de OK ne ferment pas le dialogue', (tester) async {
    final watched = _WatchedService();
    await open(tester, watched, _Progress());
    final tile = find.ancestor(
      of: find.byTooltip('Marquer comme vu'),
      matching: find.byType(TvFocus),
    ).first;
    final focusChild = find.descendant(of: tile, matching: find.byType(AnimatedBuilder)).first;
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
    final watchedTile = find.ancestor(
      of: find.byTooltip('Marquer comme non vu'),
      matching: find.byType(TvFocus),
    ).first;
    final watchedFocus = find.descendant(
      of: watchedTile,
      matching: find.byType(AnimatedBuilder),
    ).first;
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

  testWidgets('réinitialiser un épisode auto-vu efface sa progression sans le marquer vu', (tester) async {
    final watched = _WatchedService();
    final progress = _Progress()
      ..progress = const PlaybackProgress(positionMs: 850, durationMs: 1000, updatedAt: 0);
    await open(tester, watched, progress);
    await tester.longPress(find.byTooltip('Marquer comme non vu'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.byType(TextButton)).last);
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
    await tester.tap(find.descendant(of: dialog, matching: find.byType(TextButton)).last);
    await tester.pumpAndSettle();
    expect(watched.entries, hasLength(1));
    expect(find.byTooltip('Marquer comme non vu'), findsOneWidget);
    expect(find.text('Impossible de modifier le statut de cet épisode.'), findsOneWidget);
    expect(find.text('1/1 vus'), findsOneWidget);
  });
}
