import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/stream_details_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart' show VideoPlayerController;
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  _VideoPlatform({this.manyTracks = false});

  final bool manyTracks;
  final events = StreamController<VideoEvent>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;

  @override
  Future<List<VideoAudioTrack>> getAudioTracks(int playerId) async => manyTracks
      ? List.generate(
          12,
          (index) => VideoAudioTrack(
            id: '$index',
            label: 'Piste $index',
            language: 'fr',
            isSelected: index == 0,
          ),
        )
      : [];

  @override
  Future<List<VideoTrack>> getVideoTracks(int playerId) async => [];

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> pause(int playerId) async {}
}

void main() {
  for (final size in [const Size(960, 540), const Size(360, 640)]) {
    testWidgets('live details fit and are vertically centered at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final previous = VideoPlayerPlatform.instance;
      final platform = _VideoPlatform(manyTracks: true);
      VideoPlayerPlatform.instance = platform;
      addTearDown(() {
        VideoPlayerPlatform.instance = previous;
        platform.events.close();
      });
      final controller = VideoPlayerController.networkUrl(
        Uri.parse('https://example.test/live'),
      );
      final initialized = controller.initialize();
      await tester.pump();
      platform.events.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: Duration.zero,
        size: const Size(16, 9),
      ));
      await initialized;

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showStreamDetailsSheet(
                  context,
                  controller,
                  'live',
                  isLive: true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final dialog = tester.getRect(
        find.byKey(const ValueKey('live-stream-details-panel')),
      );
      expect(dialog.center.dy, closeTo(size.height / 2, 0.1));
      expect(dialog.height, lessThanOrEqualTo(size.height - 24));
      expect(dialog.height, greaterThan(size.height * 0.9));
      expect(dialog.width, lessThanOrEqualTo(size.width - 24));
      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
      Focus.of(tester.element(find.byIcon(Icons.close))).requestFocus();
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.pixels, greaterThan(0));
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      unawaited(controller.dispose());
    });
  }
}
