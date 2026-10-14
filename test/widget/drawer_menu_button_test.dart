import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/core/widgets/drawer_menu_button.dart';

/// Reproduit la topologie réelle : le widget qui **crée** le `Scaffold` place
/// le bouton ☰ dans l'`AppBar` (donc dans un contexte situé *au-dessus* du
/// `Scaffold`).
///
/// C'est exactement là que `Scaffold.of(context)` échoue s'il est appelé
/// directement depuis ce contexte : le motif était cassé dans `HomeShell`
/// (tiroir de gauche) et `DuoProfileSelectionScreen` (tiroir de droite) — le
/// tap sur ☰ ne faisait rien. Ces tests échouent si un jour on remplace le
/// `Builder` interne de [DrawerMenuButton] par un appel direct.
class _ShellOwner extends StatelessWidget {
  const _ShellOwner({required this.end});

  final bool end;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(child: Text('DRAWER_LEFT')),
      endDrawer: const Drawer(child: Text('DRAWER_RIGHT')),
      appBar: AppBar(leading: DrawerMenuButton(end: end)),
    );
  }
}

void main() {
  testWidgets('ouvre le tiroir gauche depuis la coquille qui crée le Scaffold',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ShellOwner(end: false)));

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('DRAWER_LEFT'), findsOneWidget);
  });

  testWidgets('ouvre le tiroir droit quand end=true', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ShellOwner(end: true)));

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('DRAWER_RIGHT'), findsOneWidget);
  });
}
