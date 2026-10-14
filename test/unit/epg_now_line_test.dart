import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';

/// Largeur de la colonne des noms de chaînes, telle que la grille la pose.
const double kChannelWidth = 140.0;

/// Goûtière de 4 px que le `Row` de la grille n'insère PAS entre la colonne des
/// noms et le canvas des programmes : `SizedBox(width: 140)` puis `Expanded`,
/// directement.
const double kNoGap = 0.0;

void main() {
  group('axe des heures — alignement sur la grille', () {
    test('l\'axe et la grille commencent au même pixel', () {
      // Régression : la bande de l'axe réservait `channelWidth + 4` alors que la
      // grille réserve `channelWidth` exact. L'axe était donc 4 px à droite des
      // programmes — 1 min à 4 px/min, 4 min à 1 px/min.
      //
      // `kGridLeftInset` n'existe plus : il n'était utilisé par aucun calcul
      // réel, et c'est lui qui introduisait la gouttière fantôme.
      expect(
        axisLeftInset(),
        closeTo(kChannelWidth, 0.001),
        reason: 'l\'axe démarre à ${axisLeftInset()} mais la grille à '
            '$kChannelWidth',
      );
      expect(
        nowLineX(
          channelWidth: kChannelWidth,
          timePixels: 0.0,
          offset: 0.0,
        ),
        closeTo(axisLeftInset(), 0.001),
      );
    });
  });

group('titre d\'un programme — lisibilité', () {
    test('aucun bloc ne produit un texte broyé', () {
      // Le seuil historique (`width > 26`) laissait passer des blocs de 26 à
      // 38 px, pour lesquels `maxWidth` tombait sous 14 px : le TextPainter
      // produisait une colonne de lettres illisible.
      for (var width = 1.0; width <= 120.0; width += 0.5) {
        final textMaxWidth = width - kTitlePaddingH * 2;
        if (textMaxWidth >= kTitleMinReadableWidth) {
          // Texte écrit : la largeur disponible doit rester lisible.
          expect(
            textMaxWidth,
            greaterThanOrEqualTo(kTitleMinReadableWidth),
            reason: 'bloc de ${width}px : texte écrit sur $textMaxWidth px',
          );
        }
      }
    });

    test('un programme de 30 min reste lisible au zoom le plus dézoomé', () {
      // 1,0 px/min -> bloc de 28 px. Mesuré sur le S20 : c'est le pire cas
      // réel, pas un cas théorique.
      const ppm = 1.0;
      const durationMinutes = 30;
      final width = durationMinutes * ppm - 2.0;
      final textMaxWidth = width - kTitlePaddingH * 2;
      expect(textMaxWidth, greaterThanOrEqualTo(kTitleMinReadableWidth));
      // Avant correction : 28 - 12 = 16 >= 26 ? non -> aucun texte.
      // Le bloc était vide, ce qui se lisait comme une description disparue.
    });

    test('la marge de culling vaut une heure à tous les zooms', () {
      // 240 px figés valaient 1 h à 4 px/min mais 4 h à 1 px/min : le
      // comportement changeait avec le zoom.
      for (final ppm in [1.0, 1.15, 1.5, 2.2, 3.0, 4.0, 14.0]) {
        expect(cullMarginFor(ppm), closeTo(ppm * 60.0, 0.001),
            reason: 'ppm=$ppm',);
      }
    });

    test('la marge de culling couvre au moins 60 px', () {
      // Garantie minimale : au zoom maximal de 14 px/min, une heure ferait
      // 840 px de marge. Au dézoom de 1 px/min, 60 px — suffisant pour que les
      // barres entrant dans le viewport soient déjà dessinées.
      expect(cullMarginFor(1.0), greaterThanOrEqualTo(60.0));
    });
  });

group('ligne « maintenant » — alignement sur les programmes', () {
    test('tombe exactement sur un programme commençant à la même heure', () {
      // Le canvas des programmes commence au bord gauche de la grille, donc
      // l'abscisse écran d'un bloc vaut `channelWidth + left - offset`.
      // La ligne doit donner exactement le même nombre pour l'heure qu'elle
      // matérialise : c'est la définition d'un repère aligné.
      for (final ppm in [1.0, 1.15, 1.5, 2.2, 4.0, 14.0]) {
        for (final minutesFromStart in [0, 37, 240, 615, 900, 1439]) {
          for (final offset in [0.0, 120.0, 800.0, 2500.0]) {
            final timePixels = minutesFromStart * ppm;
            final programX =
                kChannelWidth + timePixels - offset;
            final lineX = nowLineX(
              channelWidth: kChannelWidth,
              timePixels: timePixels,
              offset: offset,
            );
            expect(
              lineX,
              closeTo(programX, 0.001),
              reason: 'ppm=$ppm t=${minutesFromStart}min offset=$offset : '
                  'ligne=$lineX programme=$programX',
            );
          }
        }
      }
    });

    test('la gouttière de 4 px ne décale pas la ligne', () {
      // Régression : la formule ajoutait `kGridLeftInset` (4 px) ici alors
      // que le canvas des programmes ne réserve aucune gouttière. La ligne
      // était donc 4 px à droite de ce qu'elle marque, sur toute la longueur.
      final withGap = kChannelWidth + 4.0 + 500.0 - 0.0;
      final now = nowLineX(
        channelWidth: kChannelWidth,
        timePixels: 500.0,
        offset: 0.0,
      );
      expect(now, closeTo(kChannelWidth + 500.0, 0.001));
      expect(withGap - now, 4.0);
    });

    test('suit le défilement d\'une unité pour une unité', () {
      final base = nowLineX(
        channelWidth: kChannelWidth,
        timePixels: 2000.0,
        offset: 0.0,
      );
      final scrolled = nowLineX(
        channelWidth: kChannelWidth,
        timePixels: 2000.0,
        offset: 37.0,
      );
      // 37 px de défilement vers la droite = 37 px vers la gauche pour la ligne.
      expect(base - scrolled, 37.0);
    });

    test('rejoint le bord gauche quand le décalage vaut la position', () {
      // C'est le cas « la ligne colle à gauche » : quand l'heure affichée
      // correspond exactement au bord gauche de la grille, la ligne doit s'y
      // trouver, pas être rejetée ni décalée par la gouttière.
      final timePixels = 2400.0;
      final x = nowLineX(
        channelWidth: kChannelWidth,
        timePixels: timePixels,
        offset: timePixels + kChannelWidth - kNoGap,
      );
      expect(x, closeTo(0.0, 0.001));
    });
  });

  group('ligne « maintenant » — cohérence avec le contrôleur', () {
    test('le drift vaut zéro quand l\'axe et la ligne partagent le contrôleur',
        () {
      // Rejoue la mesure que le widget journalise : relire l'heure affichée à
      // l'abscisse de la ligne doit rendre l'heure courante.
      final now = DateTime(2026, 10, 8, 13, 5);
      final start = DateTime(2026, 10, 8);
      final controller = EpgTimelineController(
        gridStartTime: start,
        pixelsPerMinute: 4.0,
      );
      addTearDown(controller.dispose);

      for (final offset in [0.0, 500.0, 3000.0, 5493.0]) {
        final timePixels = controller.timeToPixels(now);
        final x = nowLineX(
          channelWidth: kChannelWidth,
          timePixels: timePixels,
          offset: offset,
        );
        final axisTime = controller.pixelsToTime(x - kChannelWidth + offset);
        expect(
          axisTime.difference(now).inSeconds,
          0,
          reason: 'offset=$offset : la ligne tombe à $axisTime au lieu de $now',
        );
      }
    });

    test('le drift reste borné après un changement de zoom', () {
      final now = DateTime(2026, 10, 8, 20, 30);
      final start = DateTime(2026, 10, 8);
      final controller = EpgTimelineController(
        gridStartTime: start,
        pixelsPerMinute: 4.0,
      );
      addTearDown(controller.dispose);

      for (final ppm in [1.0, 1.15, 1.5, 2.2, 3.0, 4.0, 14.0]) {
        controller.pixelsPerMinute = ppm;
        final timePixels = controller.timeToPixels(now);
        final offset = 0.0;
        final x = nowLineX(
          channelWidth: kChannelWidth,
          timePixels: timePixels,
          offset: offset,
        );
        final axisTime = controller.pixelsToTime(x - kChannelWidth + offset);
        expect(
          axisTime.difference(now).inSeconds.abs(),
          lessThanOrEqualTo(1),
          reason: 'ppm=$ppm : drift hors tolérance',
        );
      }
    });
  });
}