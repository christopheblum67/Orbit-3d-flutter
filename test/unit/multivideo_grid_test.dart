import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/multivideo/multivideo_screen.dart';

/// Dimensions de la grille multi-vue.
///
/// C'est ce calcul qui décide combien de colonnes/lignes occupe l'écran. Il est
/// extrait du widget pour être testable : avant, la grille était un `GridView`
/// à `childAspectRatio: 1.5` fixe, qui laissait une bande noire sous les tuiles
/// au lieu de remplir l'écran.
void main() {
  group('multiViewGridDimensions', () {
    test('un seul flux occupe tout l\'écran', () {
      final dims = multiViewGridDimensions(1, landscape: true);
      expect(dims.columns, 1);
      expect(dims.rows, 1);
      expect(multiViewGridDimensions(0, landscape: false).columns, 1);
    });

    test('deux flux côte à côte en paysage', () {
      final dims = multiViewGridDimensions(2, landscape: true);
      expect(dims.columns, 2);
      expect(dims.rows, 1);
    });

    test('deux flux empilés en portrait', () {
      final dims = multiViewGridDimensions(2, landscape: false);
      expect(dims.columns, 1);
      expect(dims.rows, 2);
    });

    test('trois flux tiennent dans une grille 2×2', () {
      final dims = multiViewGridDimensions(3, landscape: true);
      expect(dims.columns, 2);
      expect(dims.rows, 2);
    });

    test('quatre flux : grille 2×2', () {
      final dims = multiViewGridDimensions(4, landscape: true);
      expect(dims.columns, 2);
      expect(dims.rows, 2);
    });

    test('le nombre de cellules couvre toujours les flux demandés', () {
      for (final count in [1, 2, 3, 4]) {
        for (final landscape in [true, false]) {
          final dims = multiViewGridDimensions(count, landscape: landscape);
          expect(
            dims.columns * dims.rows,
            greaterThanOrEqualTo(count),
            reason: 'count=$count landscape=$landscape',
          );
        }
      }
    });
  });
}
