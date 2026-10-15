import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';

/// Placement horizontal des blocs de la grille EPG.
///
/// Régression verrouillée : la grille quantifiait les programmes en créneaux de
/// 2 h (`slotIndex * 120`). Tous ceux d'une même tranche recevaient la MÊME
/// abscisse et la MÊME largeur, donc se masquaient les uns les autres — seul le
/// dernier peint restait visible, ce qui se lisait « les programmes
/// disparaissent ». On place désormais chaque bloc à son heure réelle.
void main() {
  // Origine de la journée = minuit local (`EpgDayWindow.ofNow().start`).
  final midnight = DateTime(2026, 10, 15);

  group('placement exact des blocs EPG', () {
    test('l\'abscisse suit l\'heure réelle, pas un créneau de 2 h', () {
      const ppm = 4.0;
      // 14:15 → 855 min → 3420 px ; 14:45 → 885 min → 3540 px.
      expect(
        programLeftPx(DateTime(2026, 10, 15, 14, 15), midnight, ppm),
        closeTo(3420.0, 0.001),
      );
      expect(
        programLeftPx(DateTime(2026, 10, 15, 14, 45), midnight, ppm),
        closeTo(3540.0, 0.001),
      );
    });

    test('deux programmes d\'une même tranche de 2 h ne partagent plus '
        'l\'abscisse', () {
      const ppm = 4.0;
      // 14:00 et 15:59 tombent dans le même créneau avec l'ancien modèle :
      // ils étaient collés à `1 * 120 * ppm`.
      final a = programLeftPx(DateTime(2026, 10, 15, 14, 0), midnight, ppm);
      final b = programLeftPx(DateTime(2026, 10, 15, 15, 59), midnight, ppm);
      expect(b, greaterThan(a));
      expect(b - a, closeTo(119 * ppm, 0.001));
    });

    test('un programme à cheval sur minuit garde une abscisse négative', () {
      // Le culling s'en charge : ce n'est PAS un cas à replafonner.
      final left = programLeftPx(DateTime(2026, 10, 14, 23, 30), midnight, 4.0);
      expect(left, lessThan(0));
      expect(left, closeTo(-30 * 4.0, 0.001));
    });

    test('la largeur suit la durée réelle, sans créneau de 2 h', () {
      const ppm = 4.0;
      // Avec l'ancien modèle, 30 min et 90 min recevaient tous deux 1 créneau
      // (480 px), et 120 min en recevait 1 aussi.
      expect(programWidthPx(30, ppm), closeTo(120.0, 0.001));
      expect(programWidthPx(90, ppm), closeTo(360.0, 0.001));
      expect(programWidthPx(120, ppm), closeTo(480.0, 0.001));
    });

    test('les blocs contigus ne se recouvrent pas (durées réalistes)', () {
      const ppm = 1.0;
      for (final minutes in [5, 10, 15, 30, 45, 60, 90, 120]) {
        final start = DateTime(2026, 10, 15, 12);
        final left = programLeftPx(start, midnight, ppm);
        final width = programWidthPx(minutes, ppm);
        final nextLeft = programLeftPx(
          start.add(Duration(minutes: minutes)),
          midnight,
          ppm,
        );
        expect(
          left + width,
          lessThanOrEqualTo(nextLeft + 0.001),
          reason: 'durée=$minutes min : le bloc empiète sur le suivant',
        );
      }
    });

    test('le plancher de largeur reste minuscule et borné', () {
      // Un bloc de durée nulle ne disparaît pas (largeur ≥ 4 px), mais le
      // plancher ne peut pas déborder comme l'ancien 40 px — le garde-fou
      // de cliquabilité est conservé pour les appareils anciens sans
      // réintroduire le recouvrement qui masquait la grille.
      expect(kMinProgramBlockWidth, 4.0);
      expect(programWidthPx(0, 1.0), 4.0);
      expect(programWidthPx(1, 1.0), 4.0);
    });
  });
}
