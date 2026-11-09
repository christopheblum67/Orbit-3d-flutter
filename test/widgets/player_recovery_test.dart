import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/rust_proxy_manager.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _Online extends ConnectivityMonitor {
  @override
  bool get isOnline => true;
}

class _Subtitles extends SubtitleController {
  final List<int> playersWithTracks = [];

  @override
  void resetForNewContent() {}

  @override
  void setEmbeddedContext({
    required int playerId,
    required List<EmbeddedSubtitleTrack> tracks,
  }) {
    if (tracks.isNotEmpty) playersWithTracks.add(playerId);
    super.setEmbeddedContext(playerId: playerId, tracks: tracks);
  }
}

class _Progress extends PlaybackProgressService {
  final List<int> writes = [];
  @override
  Future<void> save(String id, int positionMs, int durationMs) async {
    writes.add(positionMs);
  }
}

class _History extends HistoryService {
  final entries = <(String, String, String)>[];

  @override
  Future<void> addEntry(String type, String title, String url) async {
    entries.add((type, title, url));
  }
}

class _Recent extends RecentlyWatchedNotifier {
  final entries = <(ContentType, String, String, String)>[];

  @override
  Map<String, RecentEntry> build() => {};

  @override
  Future<void> record(
    ContentType type,
    String id,
    String title, {
    String posterUrl = '',
    String subtitle = '',
    String streamUrl = '',
  }) async {
    entries.add((type, id, title, streamUrl));
  }
}

class _VideoPlatform extends VideoPlayerPlatform {
  int next = 0;
  final calls = <String>[];
  final sources = <DataSource>[];
  final streams = <int, StreamController<VideoEvent>>{};
  final positions = <int, Duration>{};
  final pauseGates = <int, Completer<void>>{};
  final delayedInitializations = <int>{};
  List<VideoAudioTrack> audioTracks = [];

  @override
  Future<void> init() async {}
  @override
  Future<void> setMixWithOthers(bool value) async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = ++next;
    sources.add(options.dataSource);
    calls.add('create:$id');
    positions[id] = Duration.zero;
    streams[id] = StreamController<VideoEvent>(onListen: () {
      if (!delayedInitializations.contains(id)) {
        scheduleMicrotask(() => initialize(id));
      }
    }, onCancel: () async {
      calls.add('cancel:$id');
    });
    return id;
  }

  void initialize(int id) => streams[id]!.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 10),
        size: const Size(1920, 1080),
      ));

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<List<VideoAudioTrack>> getAudioTracks(int playerId) async => audioTracks;
  @override
  Future<void> selectAudioTrack(int playerId, String trackId) async {
    calls.add('audio:$playerId:$trackId');
  }
  @override
  Future<void> play(int playerId) async => calls.add('play:$playerId');
  @override
  Future<void> pause(int playerId) async {
    calls.add('pause:$playerId');
    final gate = pauseGates[playerId];
    if (gate != null) await gate.future;
  }
  @override
  Future<void> seekTo(int playerId, Duration position) async {
    positions[playerId] = position;
    calls.add('seek:$playerId:${position.inMilliseconds}');
  }

  @override
  Future<Duration> getPosition(int playerId) async => positions[playerId]!;
  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose:$playerId');
    unawaited(streams[playerId]!.close());
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();

  void fail(int id, String kind) => streams[id]!.addError(PlatformException(
        code: 'VideoError',
        message: 'MediaCodecVideoRenderer error orbitDecoder=$kind',
      ));

  void failWith(int id, String message) => streams[id]!.addError(
        PlatformException(code: 'VideoError', message: message),
      );

  void complete(int id) =>
      streams[id]!.add(VideoEvent(eventType: VideoEventType.completed));
}

void main() {
  for (final config in [
    (enabled: false, type: PlaybackContentType.vod, url: 'https://example.test/video.mp4?secret=abc', proxied: false),
    (enabled: true, type: PlaybackContentType.vod, url: 'https://example.test/video.mp4?secret=abc', proxied: true),
    (enabled: true, type: PlaybackContentType.series, url: 'https://example.test/video.mp4?secret=abc', proxied: true),
    (enabled: true, type: PlaybackContentType.live, url: 'https://example.test/video.mp4?secret=abc', proxied: false),
    (enabled: true, type: PlaybackContentType.vod, url: 'https://example.test/video.mpd', proxied: false),
  ]) {
    testWidgets('le lecteur respecte le relais local : $config',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({});
      PlayerProfileService.invalidate();
      final previousPlatform = VideoPlayerPlatform.instance;
      final video = _VideoPlatform();
      VideoPlayerPlatform.instance = video;
      addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const connectivityChannel =
          MethodChannel('dev.fluttercommunity.plus/connectivity');
      const connectivityStatus =
          MethodChannel('dev.fluttercommunity.plus/connectivity_status');
      messenger.setMockMethodCallHandler(connectivityChannel, (_) async => ['wifi']);
      messenger.setMockMethodCallHandler(connectivityStatus, (_) async => null);
      addTearDown(() {
        messenger.setMockMethodCallHandler(connectivityChannel, null);
        messenger.setMockMethodCallHandler(connectivityStatus, null);
      });
      final monitor = _Online();
      addTearDown(monitor.dispose);
      for (final name in ['orbit/night_focus', 'orbit/player_config']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
        addTearDown(
          () => messenger.setMockMethodCallHandler(MethodChannel(name), null),
        );
      }
      final container = ProviderContainer(overrides: [
        connectivityMonitorProvider.overrideWithValue(monitor),
        subtitleControllerProvider.overrideWith((ref) => _Subtitles()),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
        rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
        activeSubscriptionProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);
      await container.read(advancedSettingsProvider.notifier).setLocalVideoProxy(config.enabled);
      await tester.runAsync(() async {
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PlayerScreen(
              streamUrl: config.url,
              contentType: config.type,
            ),
          ),
        ));
        for (var i = 0; i < 50 && video.sources.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(video.sources, hasLength(1));
        final source = video.sources.single;
        if (config.proxied) {
          expect(Uri.parse(source.uri!).host, '127.0.0.1');
          expect(source.uri, isNot(contains('secret')));
          expect(source.httpHeaders, isEmpty);
        } else {
          expect(source.uri, config.url);
          expect(source.httpHeaders, isNotEmpty);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    });
  }
  testWidgets('a Cloudflare challenge stops recovery without a new player',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    PlayerProfileService.invalidate();
    final previousPlatform = VideoPlayerPlatform.instance;
    final video = _VideoPlatform();
    VideoPlayerPlatform.instance = video;
    addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
    final monitor = _Online();
    addTearDown(monitor.dispose);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['orbit/night_focus', 'orbit/player_config']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
      addTearDown(
        () => messenger.setMockMethodCallHandler(MethodChannel(name), null),
      );
    }
    await tester.pumpWidget(ProviderScope(
      overrides: [
        connectivityMonitorProvider.overrideWithValue(monitor),
        subtitleControllerProvider.overrideWith((ref) => _Subtitles()),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
        rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
        activeSubscriptionProvider.overrideWithValue(null),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerScreen(
          streamUrl: 'https://example.test/video.mp4',
          contentType: PlaybackContentType.vod,
        ),
      ),
    ));
    for (var i = 0; i < 50 && !video.calls.contains('play:1'); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.calls, contains('play:1'));
    video.failWith(1, 'HTTP 403 Cloudflare challenge');
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.next, 1);
    expect(video.calls, contains('dispose:1'));
    final l = AppLocalizationsFr();
    expect(find.text(l.cloudflareCheckRequired), findsOneWidget);
    expect(find.text(l.cloudflareChallengeHelp), findsOneWidget);
    expect(find.text(l.openProviderWebsite), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  for (final config in [
    (tv: false, enabled: true, expectedPlayers: 2),
    (tv: true, enabled: true, expectedPlayers: 1),
    (tv: false, enabled: false, expectedPlayers: 1),
  ]) {
    testWidgets('preload respects playback and settings: $config', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({});
      PlayerProfileService.invalidate();
      final previousPlatform = VideoPlayerPlatform.instance;
      final video = _VideoPlatform();
      VideoPlayerPlatform.instance = video;
      addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
      final monitor = _Online();
      addTearDown(monitor.dispose);
      final tv = TvModeNotifier()..setEnabled(config.tv);
      addTearDown(tv.dispose);
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final name in ['orbit/night_focus', 'orbit/player_config']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
        addTearDown(() => messenger.setMockMethodCallHandler(MethodChannel(name), null));
      }
      final channels = List.generate(
        2,
        (i) => Channel(
          id: '$i',
          name: 'Channel $i',
          logoUrl: '',
          streamUrl: 'https://example.test/$i.m3u8',
          group: '',
        ),
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          connectivityMonitorProvider.overrideWithValue(monitor),
          subtitleControllerProvider.overrideWith((ref) => _Subtitles()),
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
          rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
          activeSubscriptionProvider.overrideWithValue(null),
          tvModeNotifierProvider.overrideWithValue(tv),
          advancedSettingsProvider.overrideWithBuild(
            (ref, notifier) => AdvancedSettings(zeroLagPrefetch: config.enabled),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlayerScreen(
            streamUrl: channels.first.streamUrl,
            channels: channels,
          ),
        ),
      ));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.calls, contains('play:1'));
      expect(video.next, config.expectedPlayers);
      if (config.expectedPlayers == 2) {
        expect(video.calls, contains('pause:2'));
        expect(video.calls, isNot(contains('play:2')));
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  for (final rapid in [false, true]) {
    testWidgets('zapping waits for pause and rejects stale switches: $rapid',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({});
      PlayerProfileService.invalidate();
      final previousPlatform = VideoPlayerPlatform.instance;
      final video = _VideoPlatform();
      VideoPlayerPlatform.instance = video;
      addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
      final monitor = _Online();
      addTearDown(monitor.dispose);
      final tv = TvModeNotifier()..setEnabled(false);
      addTearDown(tv.dispose);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final name in ['orbit/night_focus', 'orbit/player_config']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
        addTearDown(() => messenger.setMockMethodCallHandler(MethodChannel(name), null));
      }
      final channels = List.generate(
        3,
        (i) => Channel(
          id: '$i',
          name: 'Channel $i',
          logoUrl: '',
          streamUrl: 'https://example.test/$i.m3u8',
          group: '',
        ),
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          connectivityMonitorProvider.overrideWithValue(monitor),
          subtitleControllerProvider.overrideWith((ref) => _Subtitles()),
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
          rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
          activeSubscriptionProvider.overrideWithValue(null),
          tvModeNotifierProvider.overrideWithValue(tv),
          advancedSettingsProvider.overrideWithBuild(
            (ref, notifier) => const AdvancedSettings(zeroLagPrefetch: false),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlayerScreen(
            streamUrl: channels.first.streamUrl,
            channels: channels,
          ),
        ),
      ));
      for (var i = 0; i < 30 && !video.calls.contains('play:1'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.calls, contains('play:1'));
      final gate = Completer<void>();
      video.pauseGates[1] = gate;
      final before = video.calls.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.channelDown);
      await tester.pump();
      expect(video.calls.skip(before), contains('pause:1'));
      expect(video.next, 1);
      if (rapid) {
        await tester.sendKeyEvent(LogicalKeyboardKey.channelDown);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(video.next, 1);
        expect(video.calls, isNot(contains('play:2')));
      }
      gate.complete();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.next, 2);
      if (rapid) {
        expect(video.calls, contains('dispose:1'));
        expect(video.calls, contains('play:2'));
      } else {
        expect(video.calls, contains('play:2'));
        expect(video.calls, isNot(contains('dispose:1')));
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(video.calls.where((call) => call == 'dispose:1'), hasLength(1));
      expect(video.calls.where((call) => call == 'dispose:2'), hasLength(1));
    });
  }

  testWidgets('a late preload cannot replace the active channel', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    PlayerProfileService.invalidate();
    final previousPlatform = VideoPlayerPlatform.instance;
    final video = _VideoPlatform()..delayedInitializations.add(2);
    VideoPlayerPlatform.instance = video;
    addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
    final monitor = _Online();
    addTearDown(monitor.dispose);
    final tv = TvModeNotifier()..setEnabled(false);
    addTearDown(tv.dispose);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['orbit/night_focus', 'orbit/player_config']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(MethodChannel(name), null));
    }
    final channels = List.generate(
      2,
      (i) => Channel(
        id: '$i',
        name: 'Channel $i',
        logoUrl: '',
        streamUrl: 'https://example.test/$i.m3u8',
        group: '',
      ),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        connectivityMonitorProvider.overrideWithValue(monitor),
        subtitleControllerProvider.overrideWith((ref) => _Subtitles()),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
        rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
        activeSubscriptionProvider.overrideWithValue(null),
        tvModeNotifierProvider.overrideWithValue(tv),
        advancedSettingsProvider.overrideWithBuild(
          (ref, notifier) => const AdvancedSettings(zeroLagPrefetch: true),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerScreen(
          streamUrl: channels.first.streamUrl,
          channels: channels,
        ),
      ),
    ));
    for (var i = 0; i < 30 && video.next < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.next, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.channelDown);
    for (var i = 0; i < 30 && !video.calls.contains('play:3'); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.calls, contains('play:3'));
    video.initialize(2);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.calls, contains('dispose:2'));
    expect(video.calls, isNot(contains('play:2')));
    expect(video.calls, isNot(contains('dispose:3')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(video.calls.where((call) => call == 'dispose:3'), hasLength(1));
  });

  testWidgets('next episode countdown stops after three episodes', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    PlayerProfileService.invalidate();
    final previousPlatform = VideoPlayerPlatform.instance;
    final video = _VideoPlatform();
    final history = _History();
    final recent = _Recent();
    VideoPlayerPlatform.instance = video;
    addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
    final monitor = _Online();
    addTearDown(monitor.dispose);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['orbit/night_focus', 'orbit/player_config']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(MethodChannel(name), null));
    }
    final episodes = List.generate(
      4,
      (i) => Episode(
        id: '${i + 1}',
        title: 'Episode ${i + 1}',
        season: 1,
        episodeNumber: i + 1,
        streamUrl: 'https://example.test/${i + 1}.mp4',
      ),
    );
    final series = Series(
      id: 'series',
      title: 'Serie',
      description: '',
      coverUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: episodes,
    );
    final router = GoRouter(
      initialLocation: '/player',
      routes: [
        GoRoute(
          path: '/player',
          builder: (_, state) {
            final data = state.extra as PlayerRouteData?;
            return PlayerScreen(
              key: GlobalKey<PlayerScreenState>(),
              streamUrl: data?.streamUrl ?? episodes.first.streamUrl,
              contentType: PlaybackContentType.series,
              series: data?.series ?? series,
              episode: data?.episode ?? episodes.first,
              consecutiveEpisodes: data?.consecutiveEpisodes ?? 1,
              favorite: const FavoriteEntry(
                type: ContentType.series,
                id: 'series',
                title: 'Serie',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        connectivityMonitorProvider.overrideWithValue(monitor),
        subtitleControllerProvider.overrideWith((ref) => _Subtitles()),
        deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
        playbackProgressServiceProvider.overrideWith((ref) => _Progress()),
        rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
        activeSubscriptionProvider.overrideWithValue(null),
        historyServiceProvider.overrideWithValue(history),
        recentlyWatchedProvider.overrideWith(() => recent),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    for (var i = 0; i < 50 && !video.calls.contains('play:1'); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.calls, contains('play:1'));
    expect(history.entries, [('series', 'Serie', episodes.first.streamUrl)]);
    expect(recent.entries, [
      (ContentType.series, 'series', 'Serie', episodes.first.streamUrl),
    ]);
    video.complete(1);
    await tester.pump();
    expect(find.textContaining('Episode 2 (15 s)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 14));
    expect(video.next, 1);
    await tester.pump(const Duration(seconds: 1));
    for (var i = 0; i < 50 && !video.calls.contains('play:2'); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.calls, contains('play:2'));
    video.complete(2);
    await tester.pump();
    expect(find.textContaining('Episode 3 (15 s)'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    for (var i = 0; i < 50 && !video.calls.contains('play:3'); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(video.calls, contains('play:3'));
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaFastForward);
    await tester.pump();
    expect(video.calls, contains('seek:3:30000'));
    final pausesBefore = video.calls.where((call) => call == 'pause:3').length;
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPause);
    await tester.pump();
    expect(
      video.calls.where((call) => call == 'pause:3'),
      hasLength(pausesBefore + 1),
    );
    final playsBefore = video.calls.where((call) => call == 'play:3').length;
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlay);
    await tester.pump();
    expect(
      video.calls.where((call) => call == 'play:3'),
      hasLength(playsBefore + 1),
    );
    video.complete(3);
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(video.next, 3);
    expect(find.textContaining('Episode 4'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  for (final externalAvailable in [false, true]) {
    testWidgets(
        'restores position and handles external player: $externalAvailable',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({
        'player_track.audio.episode-test': 'fr',
      });
      PlayerProfileService.invalidate();
      final previousPlatform = VideoPlayerPlatform.instance;
      final video = _VideoPlatform();
      video.audioTracks = [
        VideoAudioTrack(
          id: 'fr',
          label: 'Français',
          language: 'fr',
          isSelected: false,
        ),
      ];
      VideoPlayerPlatform.instance = video;
      addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);
      final progress = _Progress();
      final subtitles = _Subtitles();
      final monitor = _Online();
      addTearDown(monitor.dispose);
      final modes = <int>[];
      final externalCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const tracksChannel = MethodChannel('flutter.io/videoPlayer/tracks');
      messenger.setMockMethodCallHandler(tracksChannel, (call) async {
        if (call.method != 'getSubtitleTracks') return null;
        return [
          {
            'id': 'subtitle',
            'label': 'Français',
            'language': 'fr',
            'isSelected': false,
            'isForced': false,
          },
        ];
      });
      addTearDown(() => messenger.setMockMethodCallHandler(tracksChannel, null));
      for (final name in ['orbit/night_focus', 'orbit/player_config']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
          if (name == 'orbit/player_config') {
            modes.add((call.arguments as Map)['decoderMode'] as int);
          }
          const externalChannel = MethodChannel('orbit/external_player');
          messenger.setMockMethodCallHandler(externalChannel, (call) async {
            externalCalls.add(call);
            return externalAvailable;
          });
          addTearDown(
              () => messenger.setMockMethodCallHandler(externalChannel, null));
          return null;
        });
        addTearDown(() =>
            messenger.setMockMethodCallHandler(MethodChannel(name), null));
      }
      await tester.pumpWidget(ProviderScope(
        overrides: [
          connectivityMonitorProvider.overrideWithValue(monitor),
          subtitleControllerProvider.overrideWith((ref) => subtitles),
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard),
          playbackProgressServiceProvider.overrideWith((ref) => progress),
          rustProxyManagerProvider.overrideWithValue(RustProxyManager.instance),
          activeSubscriptionProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlayerScreen(
            streamUrl: 'https://example.test/video.mp4',
            progressId: 'episode-test',
            initialPositionMs: 50000,
            contentType: PlaybackContentType.series,
          ),
        ),
      ));
      for (var i = 0; i < 50 && !video.calls.contains('play:1'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.calls.indexOf('seek:1:50000'),
          lessThan(video.calls.indexOf('play:1')));
      for (var i = 0; i < 50 && !video.calls.contains('audio:1:fr'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.calls, contains('audio:1:fr'));
      expect(subtitles.playersWithTracks, contains(1));
      video.positions[1] = const Duration(seconds: 90);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      video.fail(1, 'software');
      for (var i = 0; i < 50 && !video.calls.contains('play:2'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(progress.writes, contains(90000));
      expect(video.calls.indexOf('dispose:1'),
          lessThan(video.calls.indexOf('create:2')));
      expect(video.calls.indexOf('seek:2:90000'), greaterThanOrEqualTo(0));
      expect(video.calls.indexOf('seek:2:90000'),
          lessThan(video.calls.indexOf('play:2')));
      for (var i = 0; i < 50 && !video.calls.contains('audio:2:fr'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.calls, contains('audio:2:fr'));
      expect(subtitles.playersWithTracks, contains(2));
      expect(modes.last, 0);
      video.fail(2, 'hardware');
      for (var i = 0; i < 50 && !video.calls.contains('play:3'); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(video.calls.indexOf('seek:3:90000'),
          lessThan(video.calls.indexOf('play:3')));
      expect(modes.last, 2);
      video.fail(3, 'software');
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (externalCalls.isNotEmpty) break;
      }
      await tester.pump();
      expect(video.next, 3);
      expect(externalCalls, hasLength(1));
      expect((externalCalls.single.arguments as Map)['engine'], 'vlc');
      expect(
        find.text(externalAvailable
            ? 'Lecture ouverte dans un lecteur externe'
            : 'Lecture indisponible'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
