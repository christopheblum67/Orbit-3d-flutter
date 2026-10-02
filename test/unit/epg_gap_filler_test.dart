import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart';

/// Le comblement des trous de la grille EPG.
///
/// La propriété qui compte n'est pas « il y a un bloc entre deux programmes »,
/// c'est que la ligne couvre **exactement** la fenêtre : sinon l'axe horaire,
/// qui est continu, se retrouve décalé et plus aucun programme n'est à la
/// bonne colonne.
void main() {
  final windowStart = DateTime(2026, 9, 30, 0, 0);
  final windowEnd = DateTime(2026, 10, 1, 0, 0);

  EPGProgram p(
    String title,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute, {
    String channelId = 'c1',
  }) {
    final start = DateTime(2026, 9, 30, startHour, startMinute);
    final end = endHour >= 24
        ? DateTime(2026, 10, 1, endHour - 24, endMinute)
        : DateTime(2026, 9, 30, endHour, endMinute);
    return EPGProgram(
      channelId: channelId,
      title: title,
      description: '',
      start: start,
      end: end,
    );
  }

  int coveredMinutes(List<EPGProgram> programs) => programs.fold(
        0,
        (sum, e) => sum + e.end.difference(e.start).inMinutes,
      );

  group('EpgGapFiller — trous internes', () {
    // Fenêtre calée sur les programmes : on isole ici le trou INTERNE, les
    // trous de tête et de queue ayant leur propre groupe.
    final tightStart = DateTime(2026, 9, 30, 8, 0);

    test('un trou entre deux programmes est comblé', () {
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 8, 30), p('Météo', 9, 0, 9, 15)],
        windowStart: tightStart,
        windowEnd: DateTime(2026, 9, 30, 9, 15),
      );
      expect(
        out.map((e) => e.title).toList(),
        ['JT', EpgGapFiller.noDataTitle, 'Météo'],
      );
    });

    test('le bloc de trou va de la fin du précédent au début du suivant', () {
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 8, 30), p('Météo', 9, 0, 9, 15)],
        windowStart: tightStart,
        windowEnd: DateTime(2026, 9, 30, 9, 15),
      );
      final gap = out[1];
      expect(gap.start, DateTime(2026, 9, 30, 8, 30));
      expect(gap.end, DateTime(2026, 9, 30, 9, 0));
      expect(gap.isDummy, isTrue);
    });

    test('deux programmes jointifs ne laissent aucun trou', () {
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 8, 30), p('Météo', 8, 30, 9, 0)],
        windowStart: tightStart,
        windowEnd: DateTime(2026, 9, 30, 9, 0),
      );
      expect(out.where((e) => e.isDummy), isEmpty);
    });

    test('une journée entière produit des trous de tête et de queue', () {
      // Contre-exemple du test précédent : même données, fenêtre 24 h. Les
      // trous de bord doivent être comblés eux aussi, sinon la grille garde des
      // blancs sur les 23 premières heures.
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 8, 30), p('Météo', 8, 30, 9, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out.first.isDummy, isTrue);
      expect(out.last.isDummy, isTrue);
      expect(out.where((e) => e.isDummy), hasLength(2));
      expect(coveredMinutes(out), 24 * 60);
    });
  });

  group('EpgGapFiller — trous aux bornes', () {
    test('le trou avant le premier programme est comblé', () {
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 9, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out.first.isDummy, isTrue);
      expect(out.first.start, windowStart);
      expect(out.first.end, DateTime(2026, 9, 30, 8, 0));
    });

    test('le trou après le dernier programme est comblé', () {
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 9, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out.last.isDummy, isTrue);
      expect(out.last.start, DateTime(2026, 9, 30, 9, 0));
      expect(out.last.end, windowEnd);
    });

    test('une chaîne sans aucune donnée donne un seul bloc plein', () {
      final out = EpgGapFiller.fill(
        programs: const [],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out, hasLength(1));
      expect(out.single.isDummy, isTrue);
      expect(out.single.start, windowStart);
      expect(out.single.end, windowEnd);
    });
  });

  group('EpgGapFiller — rognage aux bornes', () {
    test('un programme commencé avant la fenêtre est rogné à son début', () {
      // Commencé la veille à 23 h 30, fini à 1 h : dans la grille il doit
      // commencer à 0 h, pas à 23 h 30, sinon il déborde à gauche.
      final spilling = EPGProgram(
        channelId: 'c1',
        title: 'Late night',
        description: '',
        start: DateTime(2026, 9, 29, 23, 30),
        end: DateTime(2026, 9, 30, 1, 0),
      );
      final out = EpgGapFiller.fill(
        programs: [spilling],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out.first.title, 'Late night');
      expect(out.first.start, windowStart);
      expect(out.first.end, DateTime(2026, 9, 30, 1, 0));
    });

    test('un programme dépassant la fin de fenêtre est rogné', () {
      final out = EpgGapFiller.fill(
        programs: [p('Fin de soirée', 23, 0, 26, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      final program = out.firstWhere((e) => !e.isDummy);
      expect(program.start, DateTime(2026, 9, 30, 23, 0));
      expect(program.end, windowEnd);
    });

    test('les programmes hors fenêtre sont ignorés', () {
      final before = EPGProgram(
        channelId: 'c1',
        title: 'Hier soir',
        description: '',
        start: DateTime(2026, 9, 29, 22, 0),
        end: DateTime(2026, 9, 29, 23, 0),
      );
      final out = EpgGapFiller.fill(
        programs: [before],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out, hasLength(1));
      expect(out.single.isDummy, isTrue);
    });
  });

  group('EpgGapFiller — invariants', () {
    test('la couverture vaut exactement la fenêtre', () {
      // La propriété centrale : somme des durées = largeur de la fenêtre.
      final out = EpgGapFiller.fill(
        programs: [
          p('JT', 8, 0, 8, 30),
          p('Météo', 9, 15, 10, 0),
          p('Journal', 19, 0, 19, 30),
        ],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(coveredMinutes(out), 24 * 60);
    });

    test('la couverture vaut la fenêtre même sans aucun programme', () {
      final out = EpgGapFiller.fill(
        programs: const [],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(coveredMinutes(out), 24 * 60);
    });

    test('les blocs se suivent sans trou ni recouvrement', () {
      final out = EpgGapFiller.fill(
        programs: [p('A', 2, 0, 3, 0), p('B', 7, 0, 8, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      for (var i = 1; i < out.length; i++) {
        expect(
          out[i].start,
          out[i - 1].end,
          reason: 'le bloc $i doit commencer où le précédent finit',
        );
      }
    });

    test('les entrées sont triées par début croissant', () {
      final out = EpgGapFiller.fill(
        programs: [p('Tard', 20, 0, 21, 0), p('Tôt', 6, 0, 7, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      for (var i = 1; i < out.length; i++) {
        expect(out[i].start.isBefore(out[i - 1].start), isFalse);
      }
    });

    test('le marqueur isDummy ne se perd pas sur un programme recopié', () {
      final out = EpgGapFiller.fill(
        programs: [p('JT', 8, 0, 9, 0)],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      final program = out.firstWhere((e) => e.title == 'JT');
      expect(program.isDummy, isFalse);
      // Le programme conservé est bien celui d'origine, non une version
      // recomposée : le titre et les bornes temporelles sont inchangés.
      expect(program.end, windowStart.add(const Duration(hours: 9)));
    });

    test('un programme de durée nulle ou négative est écarté', () {
      final zero = EPGProgram(
        channelId: 'c1',
        title: 'Faux',
        description: '',
        start: DateTime(2026, 9, 30, 8, 0),
        end: DateTime(2026, 9, 30, 8, 0),
      );
      final out = EpgGapFiller.fill(
        programs: [zero],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      expect(out.where((e) => e.title == 'Faux'), isEmpty);
      expect(coveredMinutes(out), 24 * 60);
    });

    test('une fenêtre inversée ne renvoie rien', () {
      expect(
        EpgGapFiller.fill(
          programs: [p('JT', 8, 0, 9, 0)],
          windowStart: windowEnd,
          windowEnd: windowStart,
        ),
        isEmpty,
      );
    });
  });
}
