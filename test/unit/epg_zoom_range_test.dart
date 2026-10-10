import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';

/// Largeur utile de la grille EPG, en pixels logiques.
///
/// La grille reserve a gauche une colonne de `channelWidth` (140) plus
/// `kGridLeftInset` (4) pour les noms de chaines ; le reste represente le
/// temps. Sur le S20 de test : 1080 px en 420 dpi = 411 dp, moins 144.
const double s20GridWidth = 1080 / (420 / 160) - 144;

/// Surface du harnais de `epg_grid_render_test.dart`.
const double harnessGridWidth = 500.0 - 144;

/// Heures visibles dans une grille de largeur [gridWidth] a [ppm] px/min.
double hoursVisible(double gridWidth, double ppm) => gridWidth / ppm / 60.0;

void main() {
  group('bornes de zoom de la grille EPG', () {
    test('le zoom par defaut ne montre qu\'environ une heure sur S20', () {
      // Documentaire : 4,0 px/min est le defaut historique du controleur. Ce
      // test echouerait si le defaut changeait, ce qui est voulu : il oblige a
      // reassumer le nouveau choix dans la plage de une heure.
      final hours = hoursVisible(
        s20GridWidth,
        EpgTimelineController.defaultPixelsPerMinute,
      );
      expect(hours, greaterThan(0.9));
      expect(hours, lessThan(1.5));
    });

    test('un palier affiche entre 4 et 6 heures sur S20', () {
      final spans = EpgGrid2DViewState.zoomSteps
          .map((ppm) => hoursVisible(s20GridWidth, ppm))
          .toList();
      expect(
        spans.any((h) => h >= 4.0 && h <= 6.0),
        isTrue,
        reason: 'aucun palier ne couvre 4-6 h sur $s20GridWidth px : '
            '${EpgGrid2DViewState.zoomSteps}',
      );
    });

    test('le palier le plus dezoome couvre au moins 4 heures', () {
      expect(
        hoursVisible(s20GridWidth, EpgGrid2DViewState.minPixelsPerMinute),
        greaterThanOrEqualTo(4.0),
      );
    });

    test('le palier le plus zoome reste lisible', () {
      // Au-dela, une heure depasse l'ecran et le defilement devient le seul
      // moyen de lire l'axe : le zoom n'apporte plus rien.
      expect(
        hoursVisible(s20GridWidth, EpgGrid2DViewState.maxPixelsPerMinute),
        lessThan(0.75),
      );
    });

    test('tous les paliers sont dans les bornes', () {
      // Un palier hors bornes est propose par `_nextZoomStep` puis ecrete par
      // `_zoomBy` : le bouton devient un no-op sans le signaler.
      for (final ppm in EpgGrid2DViewState.zoomSteps) {
        expect(ppm, greaterThanOrEqualTo(EpgGrid2DViewState.minPixelsPerMinute));
        expect(ppm, lessThanOrEqualTo(EpgGrid2DViewState.maxPixelsPerMinute));
      }
    });

    test('les paliers sont croissants et sans doublon', () {
      final steps = EpgGrid2DViewState.zoomSteps;
      for (var i = 1; i < steps.length; i++) {
        expect(
          steps[i],
          greaterThan(steps[i - 1]),
          reason: 'palier $i non croissant : $steps',
        );
      }
    });

    test('le zoom par defaut est un palier', () {
      // Sinon le premier clic sur `-` ne change rien et l'utilisateur a
      // l'impression que le bouton est casse.
      expect(
        EpgGrid2DViewState.zoomSteps,
        contains(EpgTimelineController.defaultPixelsPerMinute),
      );
    });

    test('le harnais de test voit 4 a 6 h au palier le plus dezoome', () {
      final hours =
          hoursVisible(harnessGridWidth, EpgGrid2DViewState.minPixelsPerMinute);
      expect(hours, greaterThanOrEqualTo(4.0));
      expect(hours, lessThanOrEqualTo(6.0));
    });
  });
}