import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

EPGProgram pg(DateTime start, DateTime end) => EPGProgram(
      channelId: 'C1',
      title: 'Programme',
      description: '',
      start: start,
      end: end,
    );

void main() {
  group('isReplayableProgram', () {
    final now = DateTime(2026, 9, 13, 18, 0, 0);

    test('false si la chaîne ne supporte pas le replay', () {
      expect(
        isReplayableProgram(
          pg(
            now.subtract(const Duration(hours: 2)),
            now.subtract(const Duration(hours: 1)),
          ),
          now: now,
          channelSupportsReplay: false,
        ),
        false,
      );
    });

    test('false si le programme est en cours de diffusion', () {
      expect(
        isReplayableProgram(
          pg(
            now.subtract(const Duration(minutes: 10)),
            now.add(const Duration(minutes: 50)),
          ),
          now: now,
          channelSupportsReplay: true,
        ),
        false,
      );
    });

    test('false si le programme est à venir', () {
      expect(
        isReplayableProgram(
          pg(
            now.add(const Duration(hours: 1)),
            now.add(const Duration(hours: 2)),
          ),
          now: now,
          channelSupportsReplay: true,
        ),
        false,
      );
    });

    test('true si le programme est terminé et la chaîne DVR', () {
      expect(
        isReplayableProgram(
          pg(
            now.subtract(const Duration(hours: 2)),
            now.subtract(const Duration(minutes: 30)),
          ),
          now: now,
          channelSupportsReplay: true,
        ),
        true,
      );
    });
  });
}
