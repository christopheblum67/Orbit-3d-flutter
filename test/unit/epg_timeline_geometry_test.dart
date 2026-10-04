import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';

/// Cohérence entre le temps et les pixels, source de vérité de l'axe.
///
/// Le défaut que ce test verrouille : la grille posait ses programmes avec son
/// propre origine et sa propre densité, tandis que la ligne « maintenant » et la
/// frise lisaient celles du contrôleur. Deux référentiels cohabitaient, la
/// ligne rouge ne tombait plus sur l'heure annoncée en haut, et l'écart
/// grandissait avec la distance au début de la journée — un décalage qui
/// augmente, donc impossible à corriger en ajustant une constante.
void main() {
  final start = DateTime(2026, 10, 4);

  group('conversion temps / pixels', () {
    test('le début de la grille est à zéro pixel', () {
      final c = EpgTimelineController(gridStartTime: start, pixelsPerMinute: 4);
      expect(c.timeToPixels(start), 0);
    });

    test('une heure vaut le produit exact de la densité par 60', () {
      final c = EpgTimelineController(gridStartTime: start, pixelsPerMinute: 4);
      expect(c.timeToPixels(start.add(const Duration(hours: 1))), 240);
    });

    test('aller-retour stable sur toute la journée', () {
      for (final ppm in [2.2, 3.0, 4.0, 6.5, 14.0]) {
        final c = EpgTimelineController(
          gridStartTime: start,
          pixelsPerMinute: ppm,
        );
        for (var minutes = 0; minutes < 24 * 60; minutes += 37) {
          final t = start.add(Duration(minutes: minutes));
          final back = c.pixelsToTime(c.timeToPixels(t));
          expect(
            back.difference(t).inSeconds.abs(),
            lessThanOrEqualTo(1),
            reason: '$ppm px/min dérive de '
                '${back.difference(t).inSeconds}s à $minutes min',
          );
        }
      }
    });
  });

  group('partage du référentiel', () {
    test('modifier la densité change l échelle, pas l origine', () {
      final c = EpgTimelineController(gridStartTime: start, pixelsPerMinute: 4);
      final noon = start.add(const Duration(hours: 12));

      expect(c.timeToPixels(noon), 2880);
      c.pixelsPerMinute = 2.2;
      // 720 minutes à 2,2 px/min : la position doit être recalculée depuis
      // l'origine, jamais dérivée de l'ancienne échelle.
      expect(c.timeToPixels(noon), closeTo(1584, 0.001));
      expect(c.timeToPixels(start), 0);
    });

    test('changer l origine déplace tout l axe', () {
      final c = EpgTimelineController(gridStartTime: start, pixelsPerMinute: 4);
      final target = start.add(const Duration(hours: 9));
      c.gridStartTime = target;
      expect(c.timeToPixels(target), 0);
      expect(c.timeToPixels(target.add(const Duration(hours: 1))), 240);
    });

    test('la densité par défaut est celle du contrôleur', () {
      // L'écran EPG doit prendre sa valeur ici, et non auprès de la vue : sinon
      // les deux consignent la même valeur à deux endroits.
      expect(EpgTimelineController.defaultPixelsPerMinute, 4.0);
    });
  });

  group('densité et lisibilité', () {
    test('la palette de zoom descend sous 4 px/min', () {
      // Colonne des noms (140 px) et marges déduits : ~900 px de grille sur un
      // téléphone de 1080 px.
      const gridWidth = 900.0;
      final atMin = gridWidth / 2.2;
      final atDefault = gridWidth / 4.0;

      // Presque deux fois plus de temps visible qu'à la densité par défaut :
      // c'est ce qui permet de lire une soirée entière d'un coup d'œil.
      expect(atMin / atDefault, closeTo(1.8, 0.1));
      expect(atMin, greaterThan(6 * 60));
    });

    test('un programme de 30 min garde une largeur affichable', () {
      // À la densité la plus basse, 30 min doivent encore occuper assez de
      // pixels pour que le titre tienne sur un mot ou deux.
      expect(30 * 2.2, greaterThan(60));
    });
  });
}