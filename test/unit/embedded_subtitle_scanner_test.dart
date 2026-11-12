import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/embedded_subtitle_scanner.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';

void main() {
  const first = EmbeddedSubtitleTrack(
    id: '1',
    label: 'Français',
    language: 'fr',
    isSelected: false,
    isForced: false,
    mimeType: null,
  );
  const second = EmbeddedSubtitleTrack(
    id: '2',
    label: 'English',
    language: 'en',
    isSelected: false,
    isForced: false,
    mimeType: null,
  );

  testWidgets(
      'publishes waves once, retains tracks through transient emptiness',
      (tester) async {
    final responses = <List<EmbeddedSubtitleTrack>>[
      [],
      [first],
      [],
      [first],
      [first, second],
    ];
    var calls = 0;
    final published = <String>[];
    final states = <bool>[];
    final scanner = EmbeddedSubtitleScanner<Object>(
      fetchTracks: (_) async => responses[calls++],
      duration: const Duration(seconds: 4),
    );
    addTearDown(scanner.stop);
    scanner.start(
      player: Object(),
      isCurrent: () => true,
      onTracks: (tracks, current) async {
        states.add(current());
        published.add(tracks.map((t) => t.id).join(','));
      },
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 5);
    expect(published, ['', '1', '1,2']);
    expect(states, [true, true, true]);
  });

  testWidgets('does not overlap probes and stops when the player is disposed',
      (tester) async {
    final response = Completer<List<EmbeddedSubtitleTrack>>();
    final player = Object();
    var calls = 0;
    final published = <List<EmbeddedSubtitleTrack>>[];
    final scanner = EmbeddedSubtitleScanner<Object>(
      fetchTracks: (_) {
        calls++;
        return response.future;
      },
    );
    addTearDown(scanner.stop);
    scanner.start(
      player: player,
      isCurrent: () => true,
      onTracks: (tracks, _) async => published.add(tracks),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 1);
    scanner.stopPlayer(player);
    response.complete([first]);
    await tester.pump();
    expect(published, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 1);
  });

  testWidgets('new player starts while old response is pending',
      (tester) async {
    final old = Object();
    final next = Object();
    final oldResponse = Completer<List<EmbeddedSubtitleTrack>>();
    final published = <String>[];
    final scanner = EmbeddedSubtitleScanner<Object>(
      fetchTracks: (player) =>
          identical(player, old) ? oldResponse.future : Future.value([second]),
    );
    addTearDown(scanner.stop);
    scanner.start(
      player: old,
      isCurrent: () => true,
      onTracks: (tracks, _) async => published.add('old'),
    );
    scanner.start(
      player: next,
      isCurrent: () => true,
      onTracks: (tracks, _) async => published.add(tracks.single.id),
    );
    await tester.pump();
    expect(published, ['2']);
    oldResponse.complete([first]);
    await tester.pump();
    expect(published, ['2']);
    scanner.stopPlayer(old);
    await tester.pump(const Duration(seconds: 1));
    expect(published, ['2']);
    scanner.stop();
    await tester.pump();
  });

  testWidgets('replacement invalidates callbacks from the same player',
      (tester) async {
    final player = Object();
    final callbackStarted = Completer<void>();
    final releaseCallback = Completer<void>();
    bool? oldCurrentAfterAwait;
    final scanner = EmbeddedSubtitleScanner<Object>(
      fetchTracks: (_) async => [first],
    );
    addTearDown(scanner.stop);
    scanner.start(
      player: player,
      isCurrent: () => true,
      onTracks: (tracks, current) async {
        callbackStarted.complete();
        await releaseCallback.future;
        oldCurrentAfterAwait = current();
      },
    );
    await tester.pump();
    await callbackStarted.future;
    scanner.start(
      player: player,
      isCurrent: () => true,
      onTracks: (_, __) async {},
    );
    releaseCallback.complete();
    await tester.pump();
    expect(oldCurrentAfterAwait, isFalse);
    scanner.stop();
    await tester.pump();
  });

  testWidgets('ignores a response after the generation becomes stale',
      (tester) async {
    final response = Completer<List<EmbeddedSubtitleTrack>>();
    var current = true;
    var published = false;
    final scanner = EmbeddedSubtitleScanner<Object>(
      fetchTracks: (_) => response.future,
    );
    addTearDown(scanner.stop);
    scanner.start(
      player: Object(),
      isCurrent: () => current,
      onTracks: (_, __) async => published = true,
    );
    current = false;
    response.complete([first]);
    await tester.pump();
    expect(published, isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('retries a failed probe on the next tick', (tester) async {
    var attempts = 0;
    final published = <String>[];
    final scanner = EmbeddedSubtitleScanner<Object>(
      fetchTracks: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('unavailable');
        return [first];
      },
    );
    addTearDown(scanner.stop);
    scanner.start(
      player: Object(),
      isCurrent: () => true,
      onTracks: (tracks, _) async => published.add(tracks.single.id),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(attempts, 2);
    expect(published, ['1']);
    scanner.stop();
    await tester.pump();
  });
}
