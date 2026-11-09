import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/playback_progress_writer.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

class _ProgressService extends PlaybackProgressService {
  final calls = <String>[];
  Completer<void>? wait;

  @override
  Future<void> save(String id, int positionMs, int durationMs) async {
    calls.add('save:$id:$positionMs/$durationMs');
    final pending = wait;
    if (pending != null) {
      wait = null;
      await pending.future;
    }
  }

  @override
  Future<void> clear(String id) async {
    calls.add('clear:$id');
  }
}

void main() {
  test('marks watched at 80%, clears strictly after 95%', () async {
    final service = _ProgressService();
    final writer = PlaybackProgressWriter(service);
    var watched = 0;
    void save(int position, {bool preserve = false, int duration = 100}) {
      writer.save(
        id: 'episode',
        positionMs: position,
        durationMs: duration,
        preserveOnError: preserve,
        markWatched: () => watched++,
      );
    }

    save(79);
    expect(watched, 0);
    save(80);
    save(95);
    save(96);
    save(99, preserve: true);
    save(10, duration: 0);
    await writer.pending;
    expect(watched, 4);
    expect(service.calls, [
      'save:episode:79/100',
      'save:episode:80/100',
      'save:episode:95/100',
      'clear:episode',
      'save:episode:99/100',
      'save:episode:10/0',
    ]);
  });

  test('serializes writes and exposes the latest completion', () async {
    final service = _ProgressService()..wait = Completer<void>();
    final first = service.wait!;
    final writer = PlaybackProgressWriter(service);
    writer.save(
      id: 'one',
      positionMs: 20,
      durationMs: 100,
      preserveOnError: false,
    );
    writer.save(
      id: 'two',
      positionMs: 98,
      durationMs: 100,
      preserveOnError: false,
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.calls, ['save:one:20/100']);
    first.complete();
    await writer.pending;
    expect(service.calls, ['save:one:20/100', 'clear:two']);
  });
}
