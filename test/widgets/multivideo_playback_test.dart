import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Existing video-player test fake uses the platform interface transitively.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

HardwareSpecs specs({
  bool tv = true,
  bool lowRam = false,
  int ram = 4096,
  String chipset = '',
}) =>
    HardwareSpecs(
      deviceName: 'Test',
      brand: 'Test',
      isTv: tv,
      isPhysicalDevice: true,
      totalRamMb: ram,
      lowRam: lowRam,
      sdkInt: 30,
      connection: ConnectionKind.wifi,
      recommendedProfile: DeviceProfile.standard,
      chipset: chipset,
    );

class _VideoPlatform extends VideoPlayerPlatform {
  final events = <int, StreamController<VideoEvent>>{};
  final created = <int>[];
  final disposed = <int>[];
  final cancelled = <int>[];
  final volumes = <int, double>{};
  final played = <int>[];
  Completer<void>? disposeGate;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = created.length + 1;
    created.add(id);
    late StreamController<VideoEvent> stream;
    stream = StreamController<VideoEvent>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          stream.add(
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: Duration.zero,
              size: const Size(16, 9),
            ),
          );
        });
      },
      onCancel: () {
        cancelled.add(id);
      },
    );
    events[id] = stream;
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events[playerId]!.stream;
  @override
  Future<void> setMixWithOthers(bool value) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {
    volumes[playerId] = volume;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async => played.add(playerId);
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> dispose(int playerId) async {
    await disposeGate?.future;
    disposed.add(playerId);
    unawaited(events[playerId]!.close());
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

void main() {
  test('hardware cap respects profiles, TV RAM and Realtek identification', () {
    expect(specs(chipset: 'Realtek').safeMaxMultiView(DeviceProfile.ultra), 2);
    expect(specs(chipset: 'rtd2875').safeMaxMultiView(DeviceProfile.ultra), 2);
    expect(specs(ram: 2048).safeMaxMultiView(DeviceProfile.ultra), 2);
    expect(specs(lowRam: true).safeMaxMultiView(DeviceProfile.ultra), 2);
    expect(
      specs(tv: false, lowRam: true).safeMaxMultiView(DeviceProfile.ultra),
      4,
    );
    expect(specs().safeMaxMultiView(DeviceProfile.ultra), 4);
    expect(specs().safeMaxMultiView(DeviceProfile.eco), 0);
  });

  testWidgets('tiles stagger startup and cancel a removed pending tile',
      (tester) async {
    final awakeCalls = <bool>[];
    const hardware = MethodChannel('orbit/hardware');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    messenger.setMockMethodCallHandler(hardware, (call) async {
      if (call.method == 'setKeepScreenOn') {
        awakeCalls.add((call.arguments as Map)['enabled'] as bool);
      }
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(hardware, null));
    final previous = VideoPlayerPlatform.instance;
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = previous);

    Widget tiles(List<int> indices) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Row(
              children: [
                for (final index in indices)
                  Expanded(
                    child: VideoTile(
                      key: ValueKey(index),
                      index: index,
                      url: 'https://example.test/$index',
                      waitForStartup: () async {},
                      title: '$index',
                      active: index == 0,
                      onActivate: () {},
                      onRemove: () {},
                    ),
                  ),
              ],
            ),
          ),
        );

    await tester.pumpWidget(tiles([0, 1, 2, 3]));
    await tester.pump();
    expect(platform.created.length, 1);
    await tester.pump(const Duration(milliseconds: 249));
    expect(platform.created.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(platform.created.length, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(platform.created.length, 3);
    await tester.pump(const Duration(milliseconds: 249));
    expect(platform.created.length, 3);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(platform.created.length, 4);
    expect(awakeCalls, [true]);
    await tester.pumpWidget(tiles([0, 1, 2]));
    await tester.pumpWidget(tiles([0, 1, 2, 3]));
    await tester.pumpWidget(tiles([0, 1, 2]));
    await tester.pump(const Duration(milliseconds: 750));
    expect(platform.created.length, 4);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    for (var i = 0; i < 10 && platform.disposed.length < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(platform.disposed, containsAll([1, 2, 3, 4]));
    expect(awakeCalls, [true, false]);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('changing a pending tile URL cancels its original startup',
      (tester) async {
    final previous = VideoPlayerPlatform.instance;
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = previous);
    Widget tile(String url) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VideoTile(
              index: 2,
              url: url,
              waitForStartup: () async {},
              title: 'Test',
              active: true,
              onActivate: () {},
              onRemove: () {},
            ),
          ),
        );

    await tester.pumpWidget(tile('https://example.test/old'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(tile('https://example.test/new'));
    await tester.pump();
    expect(platform.created.length, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(platform.created.length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    for (var i = 0; i < 10 && platform.disposed.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(platform.disposed, [1]);
  });

  testWidgets('reloading waits for the previous decoder to be released',
      (tester) async {
    final previous = VideoPlayerPlatform.instance;
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = previous);
    Widget tile(String url) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VideoTile(
              index: 0,
              url: url,
              waitForStartup: () async {},
              title: 'Test',
              active: true,
              onActivate: () {},
              onRemove: () {},
            ),
          ),
        );

    await tester.pumpWidget(tile('https://example.test/first'));
    await tester.pump();
    expect(platform.created, [1]);
    platform.disposeGate = Completer<void>();
    await tester.pumpWidget(tile('https://example.test/second'));
    await tester.pumpWidget(tile('https://example.test/third'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(platform.created, [1]);
    platform.disposeGate!.complete();
    platform.disposeGate = null;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(platform.created, [1, 2]);
    expect(platform.disposed, [1]);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(platform.disposed, [1, 2]);
  });

  testWidgets('remote can search, select a channel and focus its video',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final previous = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _VideoPlatform();
    addTearDown(() => VideoPlayerPlatform.instance = previous);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const config = MethodChannel('orbit/player_config');
    messenger.setMockMethodCallHandler(config, (_) async => true);
    addTearDown(() {
      messenger.setMockMethodCallHandler(config, null);
      PlayerProfileService.invalidate();
    });
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const MultiVideoScreen()),
    ]);
    addTearDown(router.dispose);
    final channels = [
      Channel(
          id: '1',
          name: 'Alpha',
          logoUrl: '',
          streamUrl: 'https://example.test/1',
          group: ''),
      Channel(
          id: '2',
          name: 'Beta',
          logoUrl: '',
          streamUrl: 'https://example.test/2',
          group: ''),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWithValue(tvMode),
        deviceProfileProvider.overrideWithValue(DeviceProfile.ultra),
        multiViewHardwareProvider.overrideWith((ref) async => specs()),
        liveChannelsProvider.overrideWith((ref) async => channels),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.readOnly, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    await tester.enterText(find.byType(TextField), 'Beta');
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.text('Alpha'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VideoTile), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Alpha'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VideoTile), findsNWidgets(2));
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    final alpha = find.byWidgetPredicate(
        (widget) => widget is VideoTile && widget.title == 'Alpha');
    final gesture = find
        .descendant(
          of: alpha,
          matching: find.byType(GestureDetector),
        )
        .first;
    final videoFocus = Focus.of(tester.element(gesture));
    videoFocus.requestFocus();
    await tester.pump();
    expect(videoFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tester.widget<VideoTile>(alpha).active, isTrue);
  });

  testWidgets('adding and removing streams preserves existing players',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final previous = VideoPlayerPlatform.instance;
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = previous);
    PlayerProfileService.invalidate();
    var configCalls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const config = MethodChannel('orbit/player_config');
    messenger.setMockMethodCallHandler(config, (_) async {
      configCalls++;
      return true;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(config, null);
      PlayerProfileService.invalidate();
    });
    final channels = List.generate(
      4,
      (i) => Channel(
        id: '$i',
        name: 'Channel $i',
        logoUrl: '',
        streamUrl: 'https://example.test/$i',
        group: '',
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const MultiVideoScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceProfileProvider.overrideWithValue(DeviceProfile.ultra),
          multiViewHardwareProvider.overrideWith((ref) async => specs()),
          liveChannelsProvider.overrideWith((ref) async => channels),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Channel 0'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(platform.created, [1]);
    expect(platform.played, [1]);
    await tester.tap(find.widgetWithText(ListTile, 'Channel 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(platform.created, [1, 2]);
    expect(platform.disposed, isEmpty);
    expect(platform.volumes[1], 1);
    expect(platform.volumes[2], 0);
    await tester.tap(find.widgetWithText(ListTile, 'Channel 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();
    expect(platform.created, [1, 2, 3]);
    expect(platform.disposed, isEmpty);
    expect(configCalls, 1);
    await tester.tap(find.widgetWithText(ListTile, 'Channel 3'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(platform.created, [1, 2, 3]);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();
    expect(platform.created, [1, 2, 3, 4]);
    await tester.tap(find.widgetWithText(ListTile, 'Channel 0'));
    for (var i = 0; i < 10 && platform.cancelled.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VideoTile), findsNWidgets(3));
    expect(platform.cancelled, [1]);
    expect(platform.created, [1, 2, 3, 4]);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    platform.events[2]!.addError(
      PlatformException(code: 'VideoError', message: 'decoder failure'),
    );
    await tester.pump();
    await tester.pump();
    await tester.idle();
    expect(find.text('Lecture indisponible'), findsOneWidget);
    expect(platform.cancelled, contains(2));
    await tester.tap(find.text('Réessayer'));
    await tester.idle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    for (var i = 0; i < 10 && platform.created.length < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(platform.created, [1, 2, 3, 4, 5]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
