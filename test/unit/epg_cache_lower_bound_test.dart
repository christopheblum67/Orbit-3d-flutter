import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart';

/// Reproduit le filtrage appliqué au cache EPG avant l'indexation.
List<EPGProgram> filterLikeCache(
  List<EPGProgram> programs, {
  required DateTime lowerBound,
  required DateTime horizon,
}) =>
    programs
        .where((p) => p.end.isAfter(lowerBound) && p.end.isBefore(horizon))
        .toList();

void main() {
  final window = EpgDayWindow.ofNow();
  final now = DateTime.now();
  final start = DateTime.now().subtract(const Duration(hours: 3));
  final end = now.add(const Duration(hours: 1));

  EPGProgram p(String title, DateTime s, DateTime e) => EPGProgram(
        channelId: 'tf1.fr',
        title: title,
        description: '',
        start: s,
        end: e,
      );

  group('borne basse du cache EPG', () {
    // Le cas réel n'est pas le programme « en cours » (sa fin est dans le
    // futur, il survit à n'importe quelle borne), mais les programmes DÉJÀ
    // terminés aujourd'hui : la grille les affiche et la borne « maintenant »
    // les supprimait au chargement.
    test('la borne « maintenant » écarte un programme terminé ce matin', () {
      final morningStart = DateTime(now.year, now.month, now.day, 10);
      final morningEnd = DateTime(now.year, now.month, now.day, 11);
      if (morningEnd.isBefore(now)) {
        final kept = filterLikeCache(
          [p('Matin', morningStart, morningEnd)],
          lowerBound: now,
          horizon: now.add(const Duration(hours: 48)),
        );
        expect(kept, isEmpty);
      }
    });

    test('la borne « début de journée » conserve un programme de ce matin', () {
      final morningStart = DateTime(now.year, now.month, now.day, 10);
      final morningEnd = DateTime(now.year, now.month, now.day, 11);
      if (morningEnd.isBefore(now)) {
        final kept = filterLikeCache(
          [p('Matin', morningStart, morningEnd)],
          lowerBound: window.start,
          horizon: now.add(const Duration(hours: 48)),
        );
        expect(kept.length, 1);
        expect(kept.single.title, 'Matin');
      }
    });

    test('la borne « début de journée » conserve le programme en cours', () {
      final kept = filterLikeCache(
        [p('En cours', start, end)],
        lowerBound: window.start,
        horizon: now.add(const Duration(hours: 48)),
      );
      expect(kept.length, 1);
      expect(kept.single.title, 'En cours');
    });

    test('un programme terminé cette nuit est conservé', () {
      final nightStart = DateTime(now.year, now.month, now.day, 0, 30);
      final nightEnd = DateTime(now.year, now.month, now.day, 1, 30);
      // Case limite : avant minuit le cache ne garderait rien.
      if (nightEnd.isAfter(now)) {
        final kept = filterLikeCache(
          [p('Nuit', nightStart, nightEnd)],
          lowerBound: window.start,
          horizon: now.add(const Duration(hours: 48)),
        );
        expect(kept.length, 1);
      }
    });

    test('la fenêtre de jour reste entièrement couverte après filtrage', () {
      final kept = filterLikeCache(
        [
          p('Matin', window.start, window.start.add(const Duration(hours: 6))),
          p('Après-midi', now, now.add(const Duration(hours: 1))),
        ],
        lowerBound: window.start,
        horizon: now.add(const Duration(hours: 48)),
      );
      final filled = EpgGapFiller.fill(
        programs: kept,
        windowStart: window.start,
        windowEnd: window.end,
      );
      final realBlocks = filled.where((b) => !b.isDummy).length;
      // Sans la correction, ce nombre valait 0 : la grille entière était vide.
      expect(realBlocks, 2);
      // Couverture sans trou : chaque bloc commence exactement là où le
      // précédent finit. On compare les `DateTime` et non la somme des durées,
      // parce que `inMilliseconds` tronque la fraction de seconde de `now()` et
      // ferait apparaître un faux trou d'1 ms.
      expect(filled.first.start, window.start);
      expect(filled.last.end, window.end);
      for (var i = 1; i < filled.length; i++) {
        expect(
          filled[i].start,
          filled[i - 1].end,
          reason: 'trou entre les blocs $i-1 et $i',
        );
      }
    });

    test('rien de plus vieux que minuit n’est conservé', () {
      final yesterday = window.start.subtract(const Duration(hours: 2));
      final kept = filterLikeCache(
        [p('Hier', yesterday, yesterday.add(const Duration(hours: 1)))],
        lowerBound: window.start,
        horizon: now.add(const Duration(hours: 48)),
      );
      expect(kept, isEmpty);
    });

    test('rien au-delà de 48 h n’est conservé', () {
      final late = now.add(const Duration(hours: 72));
      final kept = filterLikeCache(
        [p('Dans 3 jours', late, late.add(const Duration(hours: 1)))],
        lowerBound: window.start,
        horizon: now.add(const Duration(hours: 48)),
      );
      expect(kept, isEmpty);
    });
  });
}
