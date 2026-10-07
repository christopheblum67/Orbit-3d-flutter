import 'package:flutter/foundation.dart' show immutable;
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// État des lignes de la grille EPG, en trois catégories distinctes.
///
/// ## Pourquoi il fallait les distinguer
///
/// Deux mesures coexistaient, qui NE COMPTENT PAS LA MÊME CHOSE et qui
/// ressemblaient pourtant à des chiffres comparables :
///
/// - le chargeur annonçait « X chaînes avec programmes » en ne comptant que les
///   chaînes ayant au moins un VRAI programme dans la fenêtre ;
/// - la grille annonçait « Y lignes avec programmes » en comptant les lignes
///   non vides — donc y compris celles qui ne contiennent que des BLOCS DE
///   COMBLAGE.
///
/// Un écart entre les deux ne meant donc rien par lui-même : `Y` pouvait
/// compter des lignes qui n'ont aucun programme réel, simplement remplies par
/// `EpgGapFiller` pour que l'axe reste continu. Impossible alors de conclure si
/// le problème était « données absentes » ou « programmes hors fenêtre ».
///
/// [EpgRowDiagnostics] compte les trois états séparément, ce qui rend le bilan
/// comparable à celui du chargeur et le diagnostic enfin décidable.
@immutable
class EpgRowDiagnostics {
  const EpgRowDiagnostics({
    required this.rows,
    required this.withRealPrograms,
    required this.onlyGapBlocks,
    required this.empty,
  });

  /// Lignes knownues du cache de rendu.
  final int rows;

  /// Lignes contenant au moins un vrai programme.
  final int withRealPrograms;

  /// Lignes non vides mais ne contenant QUE des blocs de comblage.
  ///
  /// Visuellement remplies, mais sans information : c'est l'état qui donne à une
  /// grille l'apparence d'être « peuplée » alors qu'aucun programme n'a été
  /// trouvé.
  final int onlyGapBlocks;

  /// Lignes sans rien du tout.
  final int empty;

  /// Une seule mesure, comparable à celle du chargeur.
  int get rowsWithData => withRealPrograms + onlyGapBlocks;

  @override
  String toString() =>
      'lignes=$rows, avec vrais programmes=$withRealPrograms, '
      'comblées seules=$onlyGapBlocks, vides=$empty';
}

/// Compte les trois états à partir du cache passé au widget.
///
/// Fonction pure et séparée du widget pour être testée directement : c'est la
/// mesure elle-même qui intereste à vérifier, pas son affichage.
EpgRowDiagnostics diagnoseEpgRows(Map<String, List<EPGProgram>> epgData) {
  var withRealPrograms = 0;
  var onlyGapBlocks = 0;
  var empty = 0;

  for (final programs in epgData.values) {
    if (programs.isEmpty) {
      empty++;
      continue;
    }
    final hasReal = programs.any((p) => !p.isDummy);
    if (hasReal) {
      withRealPrograms++;
    } else {
      onlyGapBlocks++;
    }
  }

  return EpgRowDiagnostics(
    rows: epgData.length,
    withRealPrograms: withRealPrograms,
    onlyGapBlocks: onlyGapBlocks,
    empty: empty,
  );
}