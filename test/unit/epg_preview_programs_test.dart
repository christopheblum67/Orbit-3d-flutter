import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Aperçu EPG dans l'écran Live TV (liste sous la chaîne sélectionnée).
///
/// Le nombre de lignes affichées est une décision produit : l'ancienne limite
/// de 5 coupait la soirée trop tôt sur les chaînes au rythme court. On la porte
/// à 7 (`kEpgPreviewMaxPrograms`). Ce test verrouille la sélection, extraite du
/// widget pour être vérifiable sans monter tout l'écran Live TV.
EPGProgram _prog(DateTime start, {int hours = 1, String title = 'P'}) =>
    EPGProgram(
      channelId: 'tf1',
      title: title,
      description: '',
      start: start,
      end: start.add(Duration(hours: hours)),
    );

void main() {
  final now = DateTime(2026, 1, 1, 12, 0);

  group('epgPreviewPrograms', () {
    test('affiche jusqu\'à 7 programmes à venir (+2 vs l\'ancienne limite)', () {
      final programs = [
        for (var i = 0; i < 10; i++) _prog(now.add(Duration(hours: i + 1))),
      ];

      final visible = epgPreviewPrograms(programs, now);

      expect(visible, hasLength(kEpgPreviewMaxPrograms));
      expect(visible, hasLength(7));
      // Preuve du changement : l'ancienne limite de 5 aurait tronqué la liste.
      expect(visible.length, greaterThan(5));
    });

    test('écarte les programmes terminés', () {
      final programs = [
        _prog(now.subtract(const Duration(hours: 3))), // passé
        _prog(now.subtract(const Duration(hours: 1))), // passé
        _prog(now.add(const Duration(hours: 1))), // à venir
        _prog(now.add(const Duration(hours: 2))), // à venir
      ];

      final visible = epgPreviewPrograms(programs, now);

      expect(visible, hasLength(2));
      expect(visible.every((p) => p.end.isAfter(now)), isTrue);
    });

    test('garde le programme en cours (début passé, fin future)', () {
      final live = EPGProgram(
        channelId: 'tf1',
        title: 'En cours',
        description: '',
        start: now.subtract(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 30)),
      );

      final visible = epgPreviewPrograms([live], now);

      expect(visible, hasLength(1));
      expect(visible.single.title, 'En cours');
    });

    test('moins de programmes que la limite → tous conservés', () {
      final programs = [_prog(now.add(const Duration(hours: 1)))];
      expect(epgPreviewPrograms(programs, now), hasLength(1));
    });

    test('liste vide → vide', () {
      expect(epgPreviewPrograms(const [], now), isEmpty);
    });

    test('la limite reste paramétrable', () {
      final programs = [
        for (var i = 0; i < 10; i++) _prog(now.add(Duration(hours: i + 1))),
      ];
      expect(epgPreviewPrograms(programs, now, maxPrograms: 3), hasLength(3));
    });
  });
}
