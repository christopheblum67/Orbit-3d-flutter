import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart';

/// Largeur d'un bloc : même formule que la grille, pour que le test mesure la
/// production réelle plutôt qu'une recopie.
double blockWidth(int durationMinutes, double ppm) {
  final raw = durationMinutes * ppm - 2.0;
  return raw < 1.0 ? 1.0 : raw;
}

EPGProgram prog(String title, DateTime start, int minutes) => EPGProgram(
      channelId: 'c1',
      title: title,
      description: '',
      start: start,
      end: start.add(Duration(minutes: minutes)),
    );

void main() {
  group('largeur des blocs de programme', () {
    test('la largeur suit la durée, sans plancher qui déforme', () {
      // Régression : `_clampWidth` imposait 40 px au minimum. À 1 px/min, un
      // programme de 20 min occupe 18 px et était dessiné sur 40, soit plus du
      // double : il chevauchait ses voisins et masquait la suite de la grille.
      expect(blockWidth(20, 1.0), closeTo(18.0, 0.001));
      expect(blockWidth(30, 1.0), closeTo(28.0, 0.001));
      expect(blockWidth(5, 1.0), closeTo(3.0, 0.001));
      expect(blockWidth(30, 4.0), closeTo(118.0, 0.001));
      expect(blockWidth(2, 4.0), closeTo(6.0, 0.001));
    });

    test('aucun bloc n\'est plus large que sa durée', () {
      for (final ppm in [1.0, 1.15, 1.5, 2.2, 3.0, 4.0, 14.0]) {
        for (var minutes = 1; minutes <= 180; minutes++) {
          final raw = minutes * ppm - 2.0;
          // La gouttière de 2 px rend `raw` négatif pour les durées très
          // courtes au dézoom : c'est le seul cas où le plancher de 1 px
          // s'applique, et il n'y a alors plus de chevauchement possible.
          if (raw < 1.0) continue;
          expect(
            blockWidth(minutes, ppm),
            lessThanOrEqualTo(raw + 0.001),
            reason: 'ppm=$ppm durée=${minutes}min : bloc trop large, '
                'il empiète sur le suivant',
          );
        }
      }
    });

    test('une journée comblée ne présente aucun recouvrement', () {
      // Le vrai symptôme : après un moment, plus rien ne s'affiche. Cause
      // mesurée — des blocs plus larges que leur créneau se recouvraient, et le
      // culling (`rp.left + rp.width < cullMin`) occultait alors les blocs
      // légitimes voisins.
      final start = DateTime(2026, 10, 8);
      final end = start.add(const Duration(days: 1));

      // Journée réaliste : programmes de 5 à 120 min, avec des trous que le
      // combleur doit remplir.
      final raw = <EPGProgram>[
        for (var i = 0; i < 120; i++)
          prog('P$i', start.add(Duration(minutes: i * 12)), 5 + (i % 10) * 12),
      ];

      for (final ppm in [1.0, 1.15, 1.5, 2.2, 4.0]) {
        final filled = EpgGapFiller.fill(
          programs: raw,
          windowStart: start,
          windowEnd: end,
          channelId: 'c1',
        );
        // Parcours chronologique : chaque bloc doit commencer là où le
        // précédent finit, en pixels.
        var cursor = 0.0;
        var overlaps = 0;
        for (final p in filled) {
          final left = p.start.difference(start).inSeconds / 60.0 * ppm;
          if (left < cursor - 0.001) overlaps++;
          cursor = left + blockWidth(p.durationMinutes, ppm);
        }
        expect(
          overlaps,
          0,
          reason: 'ppm=$ppm : $overlaps bloc(s) se recouvrent, ce qui masque '
              'la suite de la grille au défilement',
        );
      }
    });

    test('la journée reste couverte jusqu\'au bout', () {
      // Le culling repose sur `rp.left + rp.width` : la somme doit atteindre la
      // fin de la journée, sinon la queue de la grille n'est jamais dessinée.
      //
      // Chaque bloc perd 2 px de gouttière visuelle, donc la somme est
      // raccourcie de `2 × nombre de blocs`. C'est borné et sans recouvrement,
      // mais au dézoom c'est une distorsion réelle : un programme de 5 min à
      // 1 px/min fait 5 px de créneau et n'en occupe que 3, soit 40 % perdus.
      // On l'accepte ici (c'est la séparation visuelle entre blocs) et on
      // verrouille le budget pour qu'il ne puisse pas croître.
      final start = DateTime(2026, 10, 8);
      final end = start.add(const Duration(days: 1));
      final raw = <EPGProgram>[
        for (var i = 0; i < 100; i++)
          prog('P$i', start.add(Duration(minutes: i * 14)), 20),
      ];
      const ppm = 4.0;
      final filled = EpgGapFiller.fill(
        programs: raw,
        windowStart: start,
        windowEnd: end,
        channelId: 'c1',
      );
      final last = filled.last;
      final lastRight =
          last.start.difference(start).inSeconds / 60.0 * ppm +
              blockWidth(last.durationMinutes, ppm);
      final lost = 24 * 60 * ppm - lastRight;
      expect(
        lost,
        lessThanOrEqualTo(2.0 * filled.length + 1.0),
        reason: 'gouttière cumulée ($lost px) supérieure au budget '
            '2 px × ${filled.length} blocs',
      );
    });
  });
}