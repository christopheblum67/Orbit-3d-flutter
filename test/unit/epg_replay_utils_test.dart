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

  group('buildXtreamReplayUrl', () {
    test('construit une URL timeshift Xtream avec epochs et durée', () {
      final start = DateTime.utc(2026, 9, 13, 18, 0, 0);
      final end = DateTime.utc(2026, 9, 13, 19, 0, 0);
      final url = buildXtreamReplayUrl(
        baseUrl: 'http://panel.example.com:8080/',
        username: 'user@domain',
        password: 'p@ss:word',
        channelId: '123',
        start: start,
        end: end,
      );
      expect(url, isNotNull);
      expect(
        url,
        startsWith(
          'http://panel.example.com:8080/streaming/timeshift.php'
          '?username=user%40domain&password=p%40ss%3Aword&stream=123',
        ),
      );
      expect(url, contains('&start=${start.millisecondsSinceEpoch ~/ 1000}'));
      expect(url, contains('&duration=3600'));
    });

    test('supprime les slashs de fin du baseUrl', () {
      final url = buildXtreamReplayUrl(
        baseUrl: 'http://panel.example.com:8080///',
        username: 'u',
        password: 'p',
        channelId: '1',
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 1, 1),
      );
      expect(url, startsWith('http://panel.example.com:8080/streaming/'));
      expect(url, isNot(contains('8080///')));
    });

    test('null si la durée est nulle ou négative', () {
      final t = DateTime.utc(2026, 1, 1);
      expect(
        buildXtreamReplayUrl(
          baseUrl: 'http://x.com',
          username: 'u',
          password: 'p',
          channelId: '1',
          start: t,
          end: t,
        ),
        isNull,
      );
    });
  });
}