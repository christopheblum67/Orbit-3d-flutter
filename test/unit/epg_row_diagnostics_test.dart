import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_row_diagnostics.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart';

/// Les trois états d'une ligne de grille EPG.
///
/// Le reproche porte sur la MESURE, pas sur l'affichage : deux journaux
/// existants annonçaient des chiffres qui ne comptaient pas la même chose, et
/// leur écart ne significait donc rien. On ne peut pas diagnostiquer une grille
/// « vide » tant que « vide » recouvre trois causes différentes.
void main() {
  final base = DateTime(2026, 1, 1);

  EPGProgram program({
    int minutes = 0,
    bool dummy = false,
    String title = 'Programme',
  }) =>
      EPGProgram(
        channelId: 'c1',
        title: title,
        description: '',
        start: base.add(Duration(minutes: minutes)),
        end: base.add(Duration(minutes: minutes + 30)),
        isDummy: dummy,
      );

  test('une ligne avec un vrai programme est comptée comme telle', () {
    final d = diagnoseEpgRows({
      'TF1': [program(minutes: 0)],
    });
    expect(d.rows, 1);
    expect(d.withRealPrograms, 1);
    expect(d.onlyGapBlocks, 0);
    expect(d.empty, 0);
  });

  test('une ligne de blocs de comblage SEULE n\'est pas un faux positif', () {
    // C'est le cas qui rendait l'ancien diagnostic inutilisable : la ligne est
    // non vide, donc comptée « avec programmes », alors qu'elle ne dit rien.
    final d = diagnoseEpgRows({
      'TF1': [program(minutes: 0, dummy: true, title: EpgGapFiller.noDataTitle)],
    });
    expect(d.withRealPrograms, 0);
    expect(d.onlyGapBlocks, 1);
    expect(d.empty, 0);
    expect(
      d.rowsWithData,
      1,
      reason: 'elle est bien dessinée, mais sans information',
    );
  });

  test('un mélange compte comme ayant un vrai programme', () {
    final d = diagnoseEpgRows({
      'TF1': [
        program(minutes: 0, dummy: true),
        program(minutes: 60),
      ],
    });
    expect(d.withRealPrograms, 1);
    expect(d.onlyGapBlocks, 0);
  });

  test('une ligne totalement vide est comptée vide', () {
    final d = diagnoseEpgRows({
      'TF1': <EPGProgram>[],
    });
    expect(d.empty, 1);
    expect(d.withRealPrograms, 0);
    expect(d.onlyGapBlocks, 0);
    expect(d.rowsWithData, 0);
  });

  test('les trois états se cumulent sur une grille réelle', () {
    final d = diagnoseEpgRows({
      'A': [program()],
      'B': [program(dummy: true)],
      'C': <EPGProgram>[],
      'D': [program(), program(dummy: true)],
    });
    expect(d.rows, 4);
    expect(d.withRealPrograms, 2);
    expect(d.onlyGapBlocks, 1);
    expect(d.empty, 1);
    expect(d.withRealPrograms + d.onlyGapBlocks + d.empty, d.rows);
  });

  test('un cache vide ne plante pas', () {
    final d = diagnoseEpgRows(const {});
    expect(d.rows, 0);
    expect(d.toString(), contains('vides=0'));
  });

  test('le comblage produit bien des marqueurs isDummy', () {
    // Prérequis de tout ce qui précède : si `EpgGapFiller` ne marquait pas ses
    // blocs, la separation serait fausse et le diagnostic trompeur.
    final filled = EpgGapFiller.fill(
      programs: const <EPGProgram>[],
      windowStart: base,
      windowEnd: base.add(const Duration(hours: 6)),
    );
    expect(filled, isNotEmpty);
    expect(filled.every((p) => p.isDummy), isTrue);
    expect(filled.any((p) => p.title == EpgGapFiller.noDataTitle), isTrue);
  });
}
