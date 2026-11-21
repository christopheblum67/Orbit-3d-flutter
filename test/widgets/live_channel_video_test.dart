import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/live_channel_video.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _PreviewPlatform extends VideoPlayerPlatform {
  _PreviewPlatform(this.size);

  final Size size;
  late final StreamController<VideoEvent> events;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    events = StreamController<VideoEvent>(
      onListen: () {
        scheduleMicrotask(() => events.add(VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(minutes: 1),
              size: size,
            )));
      },
    );
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;

  @override
  Future<void> setMixWithOthers(bool value) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> dispose(int playerId) async {
    unawaited(events.close());
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox(key: ValueKey('preview-video'));
}

void main() {
  for (final size in [Size.zero, const Size(1920, 1080), const Size(4, 3)]) {
    testWidgets('preview allocates a visible surface for $size',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final previous = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = _PreviewPlatform(size);
      addTearDown(() => VideoPlayerPlatform.instance = previous);
      const channel = MethodChannel('orbit/player_config');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          deviceProfileProvider.overrideWithValue(DeviceProfile.standard)
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 180,
                child: LiveChannelVideo(
                  onWatch: () {},
                  channel: Channel(
                    id: 'preview',
                    name: 'Preview',
                    logoUrl: '',
                    streamUrl: 'https://example.test/live',
                    group: '',
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      for (var i = 0;
          i < 30 &&
              find.byKey(const ValueKey('preview-video')).evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final rect = tester.getRect(find.byKey(const ValueKey('preview-video')));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
      expect(rect.width / rect.height,
          closeTo(size == Size.zero ? 16 / 9 : size.width / size.height, 0.01));
      liveWatchFocusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('WATCH'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.focused}),
        const Color(0xFF00CFE8),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
