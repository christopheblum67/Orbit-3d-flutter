import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart' as gap;

/// Raccourci de test : le comblement de trous avec les paramètres usuels.
List<EPGProgram> fillForTest({
  required List<EPGProgram> programs,
  required DateTime start,
  required DateTime end,
}) =>
    gap.EpgGapFiller.fill(programs: programs, windowStart: start, windowEnd: end);

/// Programme d'une heure, dans la fenêtre de la journée.
EPGProgram prog(String title, int startHour) {
  final day = DateTime.now();
  final start = DateTime(day.year, day.month, day.day, startHour);
  return EPGProgram(
    channelId: 'c1',
    title: title,
    description: '',
    start: start,
    end: start.add(const Duration(hours: 1)),
  );
}

/// Enveloppe la grille dans une surface contrainte, pour reproduire la mise en
/// page réelle (le `Expanded` de l'écran).
Widget harness(List<String> channels, Map<String, List<EPGProgram>> data) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          height: 700,
          child: EpgGrid2DView(channels: channels, epgData: data),
        ),
      ),
    ),
  );
}

void main() {
  group('EpgGrid2DView — les données chargées après coup sont visibles', () {
    testWidgets('une grille montée vide se remplit quand les données arrivent',
        (tester) async {
      // Régression du défaut le plus coûteux de la grille : le programme était
      // bien chargé (589 chaînes tracées) mais rien ne s'affichait.
      //
      // Cause : un `ListView.builder` ne rappelle `itemBuilder` que s'il
      // RECYCLE une ligne. Les lignes déjà affichées gardaient le painter
      // construit au premier rendu, avec un cache de rendu vide. Seule une
      // révision de données, écoutée via `repaint`, les fait repeindre.
      final channels = ['TF1 HD', 'FRANCE 2 HD'];

      await tester.pumpWidget(harness(channels, const {}));
      await tester.pump();
      expect(
        find.byType(EpgGrid2DView),
        findsOneWidget,
        reason: 'la grille doit se monter même sans aucune donnée',
      );

      final before =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView))
              .debugDataRevision;

      // Les données arrivent après coup, comme le fait le chargement EPG.
      await tester.pumpWidget(
        harness(channels, {
          'TF1 HD': [prog('LE JT', 10)],
          'FRANCE 2 HD': [prog('LE 19H', 19)],
        }),
      );
      await tester.pump();

      // C'est l'assertion qui compte : la révision doit avoir changé, sinon
      // aucune ligne déjà affichée ne se repeint et la grille reste vide.
      final after =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView))
              .debugDataRevision;
      expect(
        after,
        greaterThan(before),
        reason: 'les painters déjà construits doivent être prévenus du '
            'changement de données, sans quoi aucun bloc n\'apparaît',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('des données identiques ne déclenchent pas de repeint inutile',
        (tester) async {
      await tester.pumpWidget(
        harness(['TF1 HD'], {
          'TF1 HD': [prog('LE JT', 10)],
        }),
      );
      await tester.pump();
      final state =
          tester.state<EpgGrid2DViewState>(find.byType(EpgGrid2DView));
      final revision = state.debugDataRevision;

      await tester.pumpWidget(
        harness(['TF1 HD'], {
          'TF1 HD': [prog('LE JT', 10)],
        }),
      );
      await tester.pump();

      expect(
        state.debugDataRevision,
        revision,
        reason: 'le cache ne doit pas être reconstruit à l\'identique : '
            'repainter 628 lignes sans raison coûte cher',
      );
    });

    testWidgets('les canaux sans données ne provoquent pas d\'exception',
        (tester) async {
      await tester.pumpWidget(
        harness(['A', 'B'], {
          'A': [prog('X', 8)],
          // 'B' volontairement absent : c'est le cas réel de la plupart des
          // chaînes d'un panel.
        }),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('un changement de catégorie reconstruit la grille', (tester) async {
      await tester.pumpWidget(
        harness(['TF1 HD'], {
          'TF1 HD': [prog('LE JT', 10)],
        }),
      );
      await tester.pump();

      await tester.pumpWidget(
        harness(['SPORT 1'], {
          'SPORT 1': [prog('FOOT', 20)],
        }),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('SPORT 1'), findsOneWidget);
    });
  });

  group('EpgGapFiller — la grille est continue', () {
    test('une journée entière est couverte sans trou', () {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final filled = fillForTest(
        programs: [prog('Nuit', 0)],
        start: day,
        end: day.add(const Duration(days: 1)),
      );
      var covered = Duration.zero;
      for (final b in filled) {
        covered += b.end.difference(b.start);
      }
      expect(covered, const Duration(days: 1));
    });

    test('les blocs sont contigus', () {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final filled = fillForTest(
        programs: [prog('A', 10), prog('B', 12)],
        start: day,
        end: day.add(const Duration(days: 1)),
      );
      for (var i = 1; i < filled.length; i++) {
        expect(filled[i].start, filled[i - 1].end);
      }
    });
  });
}