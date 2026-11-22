import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/series/episode_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';

class _WatchedService extends WatchedEpisodesService {
  final entries = <WatchedEpisodeEntry>[];

  @override
  Future<List<WatchedEpisodeEntry>> loadForProfile(String profileId) async =>
      entries.where((entry) => entry.profileId == profileId).toList();

  @override
  Future<void> save(WatchedEpisodeEntry entry) async => entries.add(entry);
}

class _Progress extends PlaybackProgressService {
  @override
  PlaybackProgress? get(String id) => const PlaybackProgress(
        positionMs: 120000,
        durationMs: 900000,
        updatedAt: 0,
      );
}

void main() {
  for (final tvEnabled in [false, true]) {
    testWidgets('resume is focused and watched action works, TV=$tvEnabled',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tvMode = TvModeNotifier();
      if (tvEnabled) tvMode.enable();
      addTearDown(tvMode.dispose);
      final service = _WatchedService();
      final episode = Episode(
        id: 'episode',
        title: 'Episode',
        season: 1,
        episodeNumber: 1,
        streamUrl: 'https://example.test/episode',
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
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              EpisodeDetailScreen(series: series, episode: episode),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          tvModeNotifierProvider.overrideWithValue(tvMode),
          currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
          favoritesProvider.overrideWithBuild((ref, notifier) => {}),
          downloadTasksStreamProvider
              .overrideWith((ref) => const AsyncData([])),
          watchedEpisodesServiceProvider.overrideWithValue(service),
          playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      final start = find.text('Démarrer');
      final resume = find.text('Reprendre');
      final watched = find.text('Marquer comme vu');
      expect(
          tester.getCenter(start).dy, closeTo(tester.getCenter(resume).dy, 1));
      expect(tester.getCenter(resume).dy,
          closeTo(tester.getCenter(watched).dy, 1));
      expect(Focus.of(tester.element(resume)).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(watched)).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.text('Épisode déjà vu'), findsOneWidget);
      expect(service.entries.single.profileId, 'profile');
      expect(service.entries.single.episodeId, 'episode');
    });
  }
}
