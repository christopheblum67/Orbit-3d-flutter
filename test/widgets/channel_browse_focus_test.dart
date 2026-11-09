import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/channel_browse_view.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/live_channel_video.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('wide TV places the programme guide below the preview',
      (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = Channel(
      id: '1',
      name: 'France 4',
      logoUrl: '',
      streamUrl: '',
      group: '',
      epgChannelId: '1',
    );
    final now = DateTime.now();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tvModeNotifierProvider.overrideWithValue(tvMode),
        channelPreviewEpgProvider.overrideWith(
          (ref, _) => Stream.value([
            EPGProgram(
              channelId: '1',
              title: 'Programme actuel',
              description: 'Un résumé du programme.',
              start: now,
              end: now.add(const Duration(hours: 1)),
            ),
            EPGProgram(
              channelId: '1',
              title: 'Programme suivant',
              description: 'Un autre résumé.',
              start: now.add(const Duration(hours: 1)),
              end: now.add(const Duration(hours: 2)),
            ),
          ]),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(left: 64),
            child: ChannelBrowseView(
              previewActive: false,
              channels: [channel],
              selected: channel,
              onSelect: (_) {},
              onWatch: () {},
              onBack: () {},
              categoryName: 'Tous',
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final preview = tester.getRect(find.byType(LiveChannelVideo));
    final guide = tester.getRect(find.text('Programme actuel'));
    expect(guide.top, greaterThanOrEqualTo(preview.bottom));
    expect(liveWatchFocusNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Programme actuel'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Un résumé du programme.'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(Focus.of(tester.element(find.text('Programme actuel'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Programme suivant'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(liveWatchFocusNode.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opening a channel moves focus from the grid to watch',
      (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    final channel = Channel(
      id: '1',
      name: 'France 4',
      logoUrl: '',
      streamUrl: '',
      group: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tvModeNotifierProvider.overrideWithValue(tvMode)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                autofocus: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: ChannelBrowseView(
                        previewActive: false,
                        channels: [channel],
                        selected: channel,
                        onSelect: (_) {},
                        onWatch: () {},
                        onBack: () {},
                        categoryName: 'Tous',
                      ),
                    ),
                  ),
                ),
                child: const Text('Chaîne'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(liveWatchFocusNode.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('watch remains immediately accessible while EPG is loading',
      (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    final pendingGuide = Completer<List<EPGProgram>>();
    final channel = Channel(
      id: '1',
      name: 'France 4',
      logoUrl: '',
      streamUrl: '',
      group: '',
      epgChannelId: '1',
    );
    var watched = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tvModeNotifierProvider.overrideWithValue(tvMode),
          channelPreviewEpgProvider.overrideWith(
            (ref, channel) => Stream.fromFuture(pendingGuide.future),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChannelBrowseView(
              previewActive: false,
              channels: [channel],
              selected: channel,
              onSelect: (_) {},
              onWatch: () => watched = true,
              onBack: () {},
              categoryName: 'Tous',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(liveWatchFocusNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(watched, isTrue);
    pendingGuide.complete([]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('updates the displayed guide as progressive results arrive',
      (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    final guide = StreamController<List<EPGProgram>>();
    addTearDown(guide.close);
    final channel = Channel(
      id: '1',
      name: 'France 4',
      logoUrl: '',
      streamUrl: '',
      group: '',
      epgChannelId: '1',
    );
    final now = DateTime.now();
    EPGProgram program(String title) => EPGProgram(
          channelId: '1',
          title: title,
          description: '',
          start: now,
          end: now.add(const Duration(hours: 1)),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tvModeNotifierProvider.overrideWithValue(tvMode),
          channelPreviewEpgProvider.overrideWith((ref, _) => guide.stream),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChannelBrowseView(
              previewActive: false,
              channels: [channel],
              selected: channel,
              onSelect: (_) {},
              onWatch: () {},
              onBack: () {},
              categoryName: 'Tous',
            ),
          ),
        ),
      ),
    );
    guide.add([program('Guide rapide')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Guide rapide'), findsOneWidget);
    guide.add([program('Guide complet')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Guide rapide'), findsNothing);
    expect(find.text('Guide complet'), findsOneWidget);
    expect(liveWatchFocusNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(liveWatchFocusNode.hasPrimaryFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(liveWatchFocusNode.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
