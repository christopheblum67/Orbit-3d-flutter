import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/playback_refresh_gate.dart';

void main() {
  test('waits for all playback leases and releases each lease only once',
      () async {
    final gate = PlaybackRefreshGate();
    final player = gate.acquire();
    final preview = gate.acquire();
    var started = false;
    final waiting = gate.waitUntilIdle().then((_) => started = true);
    await Future<void>.delayed(Duration.zero);
    expect(started, isFalse);
    player.release();
    player.release();
    await Future<void>.delayed(Duration.zero);
    expect(started, isFalse);
    preview.release();
    await waiting;
    expect(started, isTrue);
  });

  test('rechecks when playback resumes before a waiter runs', () async {
    final gate = PlaybackRefreshGate();
    final first = gate.acquire();
    var started = false;
    final waiting = gate.waitUntilIdle().then((_) => started = true);
    first.release();
    final second = gate.acquire();
    await Future<void>.delayed(Duration.zero);
    expect(started, isFalse);
    second.release();
    await waiting;
    expect(started, isTrue);
  });
}
