import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Les deux boutons de sens du tri, à placer dans les `actions` de l'AppBar des
/// écrans qui exposent un tri (Films, Séries, Parcourir).
///
/// La liste de choix (`SortOptionsDialogTV`) ne contient plus qu'un
/// représentant par critère : le sens ne s'y règle plus, il se règle ici.
///
///  - ↑/↓ : inverse le critère courant (`SortModeDirection.reversed`). Désactivé
///    pour « À reprendre », seul critère sans inverse (cf. l'extension).
///  - A→Z : bascule le tri alphabétique (A→Z ⇄ Z→A). Il reste allumé tant que
///    c'est lui qui pilote l'ordre, pour qu'on sache d'où vient la liste même
///    quand aucun critère du dialogue n'est marqué actif.
class SortToolbarButtons extends StatelessWidget {
  const SortToolbarButtons({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  /// Mode de tri courant : pilote la flèche et l'état allumé du bouton A→Z.
  final SortMode mode;

  /// Appelé avec le nouveau mode quand un des deux boutons est activé.
  final ValueChanged<SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reversed = mode.reversed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          // Infobulle = sens actuel de l'ordre, comme la flèche affichée.
          tooltip: mode.isAscending ? l.sortAscending : l.sortDescending,
          icon: Icon(
            mode.isAscending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
          ),
          // `null` désactive le bouton : Material le grise et l'exclut du
          // parcours D-Pad, ce qui signale que ce critère n'a pas d'inverse.
          onPressed: reversed == null ? null : () => onChanged(reversed),
        ),
        IconButton(
          // Infobulle = ordre visé : « Nom (Z → A) » n'apparaît que quand la
          // liste est effectivement triée de Z à A.
          tooltip: mode == SortMode.nameDesc ? l.sortNameZToA : l.sortNameAToZ,
          icon: const Icon(Icons.sort_by_alpha),
          color: mode.isAlphabetical ? Colors.amber : null,
          onPressed: () => onChanged(
            mode == SortMode.nameAsc ? SortMode.nameDesc : SortMode.nameAsc,
          ),
        ),
      ],
    );
  }
}
