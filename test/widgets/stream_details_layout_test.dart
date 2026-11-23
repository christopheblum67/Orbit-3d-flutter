import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/stream_details_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/subtitle_providers.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart' show VideoPlayerController;
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  _VideoPlatform({this.manyTracks = false, this.withVideoTracks = false});

  final bool manyTracks;
  final bool withVideoTracks;
  final events = StreamController<VideoEvent>.broadcast();
  String? selectedAudio;
  VideoTrack? selectedVideo;

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
  Future<List<VideoTrack>> getVideoTracks(int playerId) async => withVideoTracks
      ? [const VideoTrack(id: 'hd', label: 'HD', isSelected: false)]
      : [];

  @override
  Future<void> selectAudioTrack(int playerId, String trackId) async {
    selectedAudio = trackId;
  }

  @override
  Future<void> selectVideoTrack(int playerId, VideoTrack? track) async {
    selectedVideo = track;
  }

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> pause(int playerId) async {}
}

FocusNode _trackFocus(WidgetTester tester, String label) {
  final tile = find.ancestor(
    of: find.text(label),
    matching: find.byType(ListTile),
  );
  return Focus.of(tester.element(tile))
      .ancestors
      .firstWhere((node) => node.canRequestFocus);
}

void main() {
  testWidgets('embedded subtitle labels follow the selected language',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final previous = VideoPlayerPlatform.instance;
    final platform = _VideoPlatform();
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

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(subtitleControllerProvider).setEmbeddedContext(
      playerId: 1,
      tracks: const [
        EmbeddedSubtitleTrack(
          id: '1',
          label: 'English',
          language: 'en',
          isSelected: false,
          isForced: true,
          mimeType: null,
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StreamDetailsSheet(
            controller: controller,
            mediaKey: 'live',
            isLive: true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Embedded subtitles'), findsOneWidget);
    expect(find.text('EN · Forced · Embedded'), findsOneWidget);
    expect(find.text('Sous-titres intégrés'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(controller.dispose());
  });

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
      expect(dialog.height, lessThanOrEqualTo(size.height * 0.78 + 0.1));
      expect(dialog.width, lessThanOrEqualTo(size.width - 24));
      expect(tester.takeException(), isNull);
      final landscape = size.width > size.height;
      final lists = find.byType(ListView);
      expect(lists, findsNWidgets(landscape ? 3 : 1));
      if (landscape) {
        final rects =
            List.generate(3, (index) => tester.getRect(lists.at(index)));
        expect(rects[0].right, lessThanOrEqualTo(rects[1].left));
        expect(rects[1].right, lessThanOrEqualTo(rects[2].left));
      } else {
        expect(find.byKey(const ValueKey('stream-details-portrait')),
            findsOneWidget);
      }
      _trackFocus(tester, 'Piste 0').requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(platform.selectedAudio, '1');
      for (var i = 0; i < 9; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: lists.first,
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.pixels, greaterThan(0));
      await tester.drag(lists.first, const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      unawaited(controller.dispose());
    });
  }

  testWidgets('landscape D-pad moves between tracks and restores focus',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final previous = VideoPlayerPlatform.instance;
    final platform = _VideoPlatform(manyTracks: true, withVideoTracks: true);
    VideoPlayerPlatform.instance = platform;
    addTearDown(() {
      VideoPlayerPlatform.instance = previous;
      platform.events.close();
    });
    const channel = MethodChannel('flutter.io/videoPlayer/tracks');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(subtitleControllerProvider).setEmbeddedContext(
      playerId: 1,
      tracks: const [
        EmbeddedSubtitleTrack(
          id: 'sub',
          label: 'English captions',
          language: 'en',
          isSelected: false,
          isForced: false,
          mimeType: null,
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              autofocus: true,
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
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    _trackFocus(tester, 'Piste 0').requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_trackFocus(tester, 'Automatic').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_trackFocus(tester, 'HD').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(platform.selectedVideo?.id, 'hd');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_trackFocus(tester, 'English captions').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(container.read(subtitleControllerProvider).activeEmbeddedTrackId,
        'sub');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_trackFocus(tester, 'HD').hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(Focus.of(tester.element(find.text('Open'))).hasFocus, isTrue);
    container.read(subtitleControllerProvider).detachEmbedded(1);
    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(controller.dispose());
  });

  for (final size in [
    const Size(960, 540),
    const Size(360, 640),
    const Size(450, 320),
    const Size(400, 300),
  ]) {
    testWidgets('non-live layout supports large text at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final previous = VideoPlayerPlatform.instance;
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      addTearDown(() {
        VideoPlayerPlatform.instance = previous;
        platform.events.close();
      });
      final controller = VideoPlayerController.networkUrl(
        Uri.parse('https://example.test/video'),
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
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.7)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showStreamDetailsSheet(
                  context,
                  controller,
                  'video',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final wideLandscape = size.width > size.height;
      expect(find.byType(ListView), findsNWidgets(wideLandscape ? 3 : 1));
      expect(find.text('Kein Audiotrack erkannt'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(StreamDetailsSheet), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(controller.dispose());
    });
  }
}
