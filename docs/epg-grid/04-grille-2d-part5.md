# EPG — grille : 4. la grille 2D

> **Partie 5/5**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_grid_2d_view.dart`, `lib/features/epg/widgets/epg_row_diagnostics.dart`

### 4.1 `EpgGrid2dView` — la grille — suite 5/5

`lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1601–1651

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1601–1651 · partie 1/1

```dart
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: (cullMax - cullMin).clamp(0.0, size.width));
        if (cullMin <= 8 && emptyPainter.width > 0) {
          emptyPainter.paint(
              canvas, Offset(8, y + (h - emptyPainter.height) / 2),);
        }
      }
    }

    // La ligne « maintenant » n'est PAS tracée ici.
    //
    // Une ligne = un canvas, donc ce tracé était répété 628 fois et s'interrompait
    // aux bords de chaque ligne : elle se lisait comme une suite de tirets sans
    // signification. Elle est désormais peinte une seule fois, par-dessus toute la
    // grille, dans `_NowLineOverlay`.
  }

  /// Rectangle à bordure pointillée, pour les blocs de trou.
  ///
  /// `Paint` n'a pas de style pointillé : on trace donc le chemin segment par
  /// segment. Le motif dit « il n'y a rien ici » sans se confondre avec les
  /// programmes voisins.
  void _drawDashedRect(Canvas canvas, RRect rect, Paint paint) {
    final path = Path()..addRRect(rect.deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 3;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EpgGridPainter old) {
    // La map n'est plus capturée : c'est [dataRevision] qui arbitre, et il est
    // déjà écouté via `repaint`. On ne compare donc plus l'identité d'une map
    // — deux painters successifs lisaient la même instance, et l'égalité
    // disait « rien à repeindre » alors que son contenu venait de changer.
    if (old.dataRevision != dataRevision) return true;
    return old.gridStartTime != gridStartTime ||
        old.pixelsPerMinute != pixelsPerMinute ||
        old.viewportWidth != viewportWidth ||
        old.channelIndex != channelIndex;
  }
}
```

### 4.2 `epg_row_diagnostics` — diagnostics de ligne

`lib/features/epg/widgets/epg_row_diagnostics.dart` · lignes 1–86

#### `lib/features/epg/widgets/epg_row_diagnostics.dart` · lignes 1–86 · partie 1/1

```dart
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
```
