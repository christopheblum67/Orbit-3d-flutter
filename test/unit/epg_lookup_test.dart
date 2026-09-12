import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

EPGProgram _program(String id, DateTime start, DateTime end) => EPGProgram(
      channelId: 'ch1',
      title: id,
      description: '',
      start: start,
      end: end,
    );

void main() {
  final base = DateTime(2026, 9, 10, 20, 0);
  // 'a' se termine à base+60, 'b' commence à base+90 → vrai gap de 30 min.
  final sorted = [
    _program('a', base, base.add(const Duration(minutes: 60))),
    _program('b', base.add(const Duration(minutes: 90)), base.add(const Duration(minutes: 150))),
    _program('c', base.add(const Duration(minutes: 150)), base.add(const Duration(minutes: 210))),
    _program('d', base.add(const Duration(minutes: 210)), base.add(const Duration(minutes: 270))),
  ];

  group('epgCurrentProgram (dichotomie)', () {
    test('programme en cours au milieu', () {
      final now = base.add(const Duration(minutes: 180));
      expect(epgCurrentProgram(sorted, now)?.title, 'c');
    });

    test('début du premier programme', () {
      expect(epgCurrentProgram(sorted, base)?.title, 'a');
    });

    test('juste avant le premier programme -> null', () {
      expect(
        epgCurrentProgram(sorted, base.subtract(const Duration(minutes: 1))),
        isNull,
      );
    });

    test('gap entre deux programmes -> null', () {
      // 'a' a fini à base+60, 'b' commence à base+90 : au milieu -> pas de programme
      final now = base.add(const Duration(minutes: 75));
      expect(epgCurrentProgram(sorted, now), isNull);
    });

    test('après le dernier -> null', () {
      final now = base.add(const Duration(minutes: 300));
      expect(epgCurrentProgram(sorted, now), isNull);
    });

    test('liste vide -> null', () {
      expect(epgCurrentProgram(const [], base), isNull);
    });
  });

  group('epgNextProgram (dichotomie)', () {
    test('programme suivant (fin de la liste)', () {
      final now = base.add(const Duration(minutes: 250));
      expect(epgNextProgram(sorted, now), isNull);
    });

    test('programme suivant après un gap', () {
      final now = base.add(const Duration(minutes: 75)); // dans le gap a→b
      expect(epgNextProgram(sorted, now)?.title, 'b');
    });

    test('juste avant le premier', () {
      final now = base.subtract(const Duration(minutes: 1));
      expect(epgNextProgram(sorted, now)?.title, 'a');
    });

    test('liste vide -> null', () {
      expect(epgNextProgram(const [], base), isNull);
    });
  });

  group('epgCurrentAndNext', () {
    test('retourne la paire (en cours, suivant)', () {
      final now = base.add(const Duration(minutes: 30)); // 'a' en cours
      final (current, next) = epgCurrentAndNext(sorted, now);
      expect(current?.title, 'a');
      expect(next?.title, 'b');
    });
  });
}