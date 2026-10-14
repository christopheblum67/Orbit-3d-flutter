import 'package:flutter/material.dart';

/// Bouton « ☰ » d'app-bar qui ouvre le tiroir du `Scaffold` qui le contient.
///
/// ## Pourquoi ce widget existe
///
/// `Scaffold.of(context)` ne cherche que des **ancêtres**. Appelé depuis le
/// contexte du widget qui *crée* le `Scaffold` (donc au-dessus de lui), il ne
/// trouve rien et lève une `FlutterError` : le bouton paraît alors « mort » —
/// le tap ne fait rien, sans message pour l'utilisateur.
///
/// Le `Builder` interne fournit un contexte situé **sous** le `Scaffold`, seul
/// endroit d'où `Scaffold.of` le voit. Le motif était cassé à deux endroits :
/// la coquille principale (`HomeShell`, tiroir de gauche) et la sélection de
/// profils en mode Duo (tiroir de droite).
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key, this.end = false, this.tooltip = 'Menu'});

  /// Ouvre le tiroir de **droite** (`Scaffold.endDrawer`) au lieu de celui de
  /// gauche (`Scaffold.drawer`).
  final bool end;

  /// Info-bulle affichée au survol / à l'appui long.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: tooltip,
        onPressed: () {
          final scaffold = Scaffold.of(context);
          if (end) {
            scaffold.openEndDrawer();
          } else {
            scaffold.openDrawer();
          }
        },
      ),
    );
  }
}
