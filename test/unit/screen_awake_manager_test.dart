import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:orbit_3d_flutter/core/services/screen_awake_manager.dart';
import 'package:orbit_3d_flutter/services/radio_service.dart';

class _AudioPlayer extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  bool fail = false;
  Completer<Duration?>? loadGate;

  @override
  Stream<PlayerState> get playerStateStream => states.stream;

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    if (fail) throw PlayerException(0, '403', null);
    if (loadGate != null) return loadGate!.future;
    return null;
  }

  @override
  Future<void> play() async {
    scheduleMicrotask(
      () => states.add(PlayerState(true, ProcessingState.ready)),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => states.close();
}

void main() {
  test('owners cannot turn off another player and requests stay ordered',
      () async {
    final calls = <bool>[];
    final first = Completer<void>();
    final manager = ScreenAwakeManager(setScreenOn: (enabled) async {
      calls.add(enabled);
      if (calls.length == 1) await first.future;
      return true;
    });
    final video = Object();
    final radio = Object();
    manager.setActive(video, true);
    manager.setActive(radio, true);
    manager.setActive(video, false);
    manager.setActive(radio, false);
    await Future<void>.delayed(Duration.zero);
    expect(calls, [true]);
    first.complete();
    await manager.pending;
    expect(calls, [true, false]);
  });

  test('radio keeps screen awake while playing and releases on stop or error',
      () async {
    final calls = <bool>[];
    final manager = ScreenAwakeManager(setScreenOn: (enabled) async {
      calls.add(enabled);
      return true;
    });
    final player = _AudioPlayer();
    final radio = RadioService(player: player, screenAwake: manager);
    await radio.play('https://example.test/radio');
    await manager.pending;
    expect(radio.isPlaying, isTrue);
    expect(calls, [true]);

    await radio.stop();
    await manager.pending;
    expect(calls, [true, false]);

    await radio.play('https://example.test/radio');
    await manager.pending;
    player.fail = true;
    await radio.play('https://example.test/unavailable');
    await manager.pending;
    expect(radio.error, isNotNull);
    expect(calls, [true, false, true, false]);
    radio.dispose();
  });

  test('late radio startup cannot reactivate awake mode after disposal',
      () async {
    final calls = <bool>[];
    final manager = ScreenAwakeManager(setScreenOn: (enabled) async {
      calls.add(enabled);
      return true;
    });
    final player = _AudioPlayer()..loadGate = Completer<Duration?>();
    final radio = RadioService(player: player, screenAwake: manager);
    final starting = radio.play('https://example.test/radio');
    await Future<void>.delayed(Duration.zero);
    radio.dispose();
    player.loadGate!.complete(null);
    await starting;
    await manager.pending;
    expect(calls, isEmpty);
  });
}
