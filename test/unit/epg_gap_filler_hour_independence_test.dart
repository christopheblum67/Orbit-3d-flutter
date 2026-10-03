import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart';

/// Vérifie que le comblement de trous ne dépend pas de l'heure de la journée.
///
/// Un test qui plante entre minuit et 6 h sans planter le reste du temps est un
/// test qui trompe : il a déjà coûté une fausse alerte sur une correction.
/// On rejoue donc le scénario à chaque heure, avec une journée simulée.
void main() {
  EPGProgram p(String title, DateTime s, DateTime e) => EPGProgram(
        channelId: 'c1',
        title: title,
        description: '',
        start: s,
        end: e,
      );

  test('la journée reste couverte et sans trou, à toute heure', () {
    for (var hour = 0; hour < 24; hour++) {
      // Journée simulée : minuit + `hour`. Sans cela, le test dépend de
      // l'heure réelle de la machine.
      final day = DateTime(2026, 10, 3);
      final window = EpgDayWindow.ofDay(day);
      final now = day.add(Duration(hours: hour, minutes: 17));

      final kept = [
        p('Matin', window.start, window.start.add(const Duration(hours: 6))),
        p(
          'Midi',
          window.start.add(const Duration(hours: 12)),
          window.start.add(const Duration(hours: 13)),
        ),
        // Programme en cours, calé sur l'heure simulée.
        p('En cours', now, now.add(const Duration(hours: 1))),
      ].where((x) => x.end.isAfter(window.start)).toList();

      final filled = EpgGapFiller.fill(
        programs: kept,
        windowStart: window.start,
        windowEnd: window.end,
      );

      expect(
        filled.first.start,
        window.start,
        reason: 'pas de trou initial à l\'heure $hour',
      );
      expect(
        filled.last.end,
        window.end,
        reason: 'journée non couverte jusqu\'à minuit à l\'heure $hour',
      );
      for (var i = 1; i < filled.length; i++) {
        expect(
          filled[i].start,
          filled[i - 1].end,
          reason: 'trou entre les blocs $i-1 et $i à l\'heure $hour',
        );
      }
    }
  });

  test('un programme déjà terminé est conservé, sans être masqué', () {
    final day = DateTime(2026, 10, 3);
    final window = EpgDayWindow.ofDay(day);
    for (var hour = 2; hour < 24; hour++) {
      // Avant 2 h du matin, un programme « terminé il y a 1 h » appartient à la
      // veille : il est légitimement hors de la journée affichée. L'assertion
      // ne porte que sur les heures où il tombe vraiment dedans.
      final now = day.add(Duration(hours: hour, minutes: 17));
      final finished = p(
        'Terminé',
        now.subtract(const Duration(hours: 2)),
        now.subtract(const Duration(hours: 1)),
      );
      final kept = [finished]
          .where((x) => x.end.isAfter(window.start))
          .toList();
      final filled = EpgGapFiller.fill(
        programs: kept,
        windowStart: window.start,
        windowEnd: window.end,
      );
      expect(
        filled.where((b) => !b.isDummy).length,
        1,
        reason: 'le programme terminé a disparu à l\'heure $hour',
      );
    }
  });

  test('un programme de la veille est exclu de la journée', () {
    final day = DateTime(2026, 10, 3);
    final window = EpgDayWindow.ofDay(day);
    final now = day.add(const Duration(hours: 0, minutes: 17));
    final finished = p(
      'Terminé',
      now.subtract(const Duration(hours: 2)),
      now.subtract(const Duration(hours: 1)),
    );
    expect(finished.end.isAfter(window.start), isFalse);
    final filled = EpgGapFiller.fill(
      programs: [finished],
      windowStart: window.start,
      windowEnd: window.end,
    );
    expect(filled.where((b) => !b.isDummy), isEmpty);
  });
}
