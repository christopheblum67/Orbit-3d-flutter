import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/time_progress_bar.dart';
import 'package:video_player/video_player.dart';

class _Player extends VideoPlayerController {
  _Player({Duration duration = const Duration(minutes: 2)})
      : super.networkUrl(Uri.parse('https://example.test/video')) {
    value = VideoPlayerValue(
      duration: duration,
      position: const Duration(seconds: 45),
      isInitialized: true,
    );
  }

  final List<Duration> seeks = [];
  Completer<void>? waitForSeek;

  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position);
    final pending = waitForSeek;
    if (pending != null) {
      waitForSeek = null;
      await pending.future;
    }
    value = value.copyWith(position: position);
  }
}

void main() {
  testWidgets('remote moves focus and seeks in bounded 30-second steps',
      (tester) async {
    final player = _Player();
    var interactions = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TimeProgressBar(
              controller: player,
              onInteraction: () => interactions++,
            ),
            TextButton(
                autofocus: true, onPressed: () {}, child: const Text('Play')),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    final bar = find.descendant(
      of: find.byType(TimeProgressBar),
      matching: find.byType(GestureDetector),
    );
    expect(Focus.of(tester.element(bar)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 75));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(player.seeks.last, const Duration(minutes: 2));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(player.seeks.last, const Duration(seconds: 90));
    expect(interactions, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Play'))).hasFocus, isTrue);
  });

  testWidgets('repeated keys coalesce without losing the target',
      (tester) async {
    final player = _Player();
    final pending = Completer<void>();
    player.waitForSeek = pending;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TimeProgressBar(controller: player)),
    ));
    final bar = find.descendant(
      of: find.byType(TimeProgressBar),
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(bar)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(player.seeks, [const Duration(seconds: 75)]);
    pending.complete();
    await tester.pumpAndSettle();
    expect(player.seeks, [
      const Duration(seconds: 75),
      const Duration(seconds: 105),
    ]);
  });

  testWidgets('unknown duration cannot be selected for seeking',
      (tester) async {
    final player = _Player(duration: Duration.zero);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TimeProgressBar(controller: player)),
    ));
    final focus = tester.widget<Focus>(find.descendant(
      of: find.byType(TimeProgressBar),
      matching: find.byType(Focus),
    ));
    expect(focus.canRequestFocus, isFalse);
    expect(player.seeks, isEmpty);
  });

  testWidgets('controller replacement ignores an old pending seek',
      (tester) async {
    final oldPlayer = _Player();
    final newPlayer = _Player();
    final pending = Completer<void>();
    oldPlayer.waitForSeek = pending;

    Widget page(VideoPlayerController player) => MaterialApp(
          home: Scaffold(body: TimeProgressBar(controller: player)),
        );

    await tester.pumpWidget(page(oldPlayer));
    final bar = find.descendant(
      of: find.byType(TimeProgressBar),
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(bar)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpWidget(page(newPlayer));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    pending.complete();
    await tester.pumpAndSettle();
    expect(oldPlayer.seeks, [const Duration(seconds: 75)]);
    expect(newPlayer.seeks, [const Duration(seconds: 75)]);
    expect(find.text('01:15'), findsOneWidget);
  });
}
