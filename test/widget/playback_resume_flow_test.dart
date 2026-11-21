import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/series/episode_detail_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

void main() {
  late Directory hiveDirectory;
  late PlaybackProgressService progressService;
  late Box<dynamic> progressBox;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('orbit_resume_flow_');
    Hive.init(hiveDirectory.path);
    progressService = PlaybackProgressService();
    await progressService.init();
    progressBox = Hive.box('playback_progress');
  });

  setUp(() async {
    await progressBox.clear();
    await progressService.save('episode-episode-42', 125000, 900000);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('untitled episodes use the selected language', (tester) async {
    final series = Series(
      id: 'series-1',
      title: 'Series',
      description: '',
      coverUrl: '',
      year: 2024,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: const [],
    );
    final episode = Episode(
      id: 'episode-42',
      title: '',
      season: 1,
      episodeNumber: 2,
      streamUrl: '',
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
        favoritesProvider.overrideWithBuild((ref, notifier) => {}),
        playbackProgressServiceProvider
            .overrideWith((ref) => PlaybackProgressService()),
        downloadTasksStreamProvider.overrideWith((ref) => const AsyncData([])),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Episode S01E02'), findsOneWidget);
  });

  testWidgets('resume opens the episode with its saved playback position',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final series = Series(
      id: 'series-1',
      title: 'Série',
      description: '',
      coverUrl: '',
      year: 2024,
      genre: 'Drame',
      director: '',
      rating: 0,
      pegi: '',
      episodes: const [],
    );
    final episode = Episode(
      id: 'episode-42',
      title: 'Série - Le départ',
      season: 1,
      episodeNumber: 2,
      streamUrl: 'https://media.example.test/episode.m3u8',
    );
    final router = GoRouter(
      initialLocation: '/episode',
      routes: [
        GoRoute(
          path: '/episode',
          builder: (context, state) => EpisodeDetailScreen(
            series: series,
            episode: episode,
          ),
        ),
        GoRoute(
          path: '/player',
          builder: (context, state) {
            final routeData = state.extra! as PlayerRouteData;
            return Scaffold(
              body: Text(
                '${routeData.streamUrl}|${routeData.progressId}|'
                '${routeData.initialPositionMs}',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesProvider.overrideWithBuild((ref, notifier) => {}),
          playbackProgressServiceProvider
              .overrideWith((ref) => progressService),
          downloadTasksStreamProvider.overrideWith(
            (ref) => const AsyncData([]),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Repris à 2 min'), findsOneWidget);
    await tester.runAsync(
      () => progressService.save('episode-episode-42', 250000, 900000),
    );
    await tester.pump();
    expect(find.text('Repris à 4 min'), findsOneWidget);

    await tester.tap(find.text('Reprendre'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'https://media.example.test/episode.m3u8|episode-episode-42|250000',
      ),
      findsOneWidget,
    );
  });
}
