import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/playback_refresh_gate.dart';
import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/epg_data_cache.dart';

class _EpgCache extends EPGDataCache {
  int calls = 0;
  final pending = Completer<List<EPGProgram>>();

  @override
  Future<List<EPGProgram>> loadFull(
    ApiService api, {
    bool forceRefresh = false,
  }) {
    calls++;
    if (calls == 1) return Future.error(StateError('EPG unavailable'));
    return pending.future;
  }
}

void main() {
  for (final valid in [true, false]) {
    testWidgets('deferred startup waits for playback; still valid: $valid',
        (tester) async {
      final gate = PlaybackRefreshGate();
      final lease = gate.acquire();
      var loads = 0;
      final controller = StartupRefreshController(
        ApiService(),
        steps: {StartupStep.radio},
        playbackGate: gate,
        deferredStillValid: () => valid,
        loadLiveChannels: () async => <Channel>[],
        loadMovies: () async => <Movie>[],
        loadSeries: () async => <Series>[],
        loadRadioChannels: () async {
          loads++;
          return <Channel>[];
        },
      );
      await tester.pumpWidget(const SizedBox());
      controller.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 3));
      expect(loads, 0);
      lease.release();
      await tester.pump();
      expect(loads, valid ? 1 : 0);
      await tester.pump(const Duration(seconds: 1));
      controller.dispose();
    });
  }

  for (final stillValid in [true, false]) {
    testWidgets('EPG retry respects subscription validity: $stillValid',
        (tester) async {
      final cache = _EpgCache();
      var refreshed = 0;
      var valid = true;
      cache.onRevalidated = () => refreshed++;
      final controller = StartupRefreshController(
        ApiService(),
        steps: {StartupStep.epg},
        epgCache: cache,
        playbackGate: PlaybackRefreshGate(),
        deferredStillValid: () => valid,
        loadLiveChannels: () async => <Channel>[],
        loadMovies: () async => <Movie>[],
        loadSeries: () async => <Series>[],
        loadRadioChannels: () async => <Channel>[],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(const SizedBox());
      controller.start();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isFinished, isTrue);
      expect(cache.calls, 0);
      await tester.pump(const Duration(milliseconds: 2500));
      expect(cache.calls, 1);
      valid = stillValid;
      await tester.pump(const Duration(seconds: 5));
      expect(cache.calls, stillValid ? 2 : 1);
      expect(controller.isFinished, isTrue);
      if (stillValid) {
        cache.pending.complete([]);
        await tester.pump();
        expect(refreshed, 1);
        await tester.pump(const Duration(seconds: 1));
      } else {
        expect(refreshed, 0);
      }
    });
  }
}
