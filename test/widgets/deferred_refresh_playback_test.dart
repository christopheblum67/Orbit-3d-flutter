import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/playback_refresh_gate.dart';
import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

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
}
