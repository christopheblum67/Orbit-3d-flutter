import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';

/// Tuile déroulante des réglages (Live, DNS, …), pilotée au D-pad.
///
/// Non-régression du défaut « FocusNode partagé » : le `Focus` parent et le
/// `DropdownButton` recevaient le même `FocusNode`, ce qui levait
/// `FocusNode._reparent: assert(child != this)` à chaque frame — contenu non
/// rendu en debug. Ce test échouerait sans la séparation des nœuds.
Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 480, child: child)),
  ),
);

Widget _tile() => StatefulBuilder(
  builder: (ctx, setState) => SettingsDropdownTile<String>(
    title: 'Qualité du flux',
    subtitle: 'Résolution automatique',
    value: 'Auto',
    options: const ['Auto', 'Haute', 'Moyenne'],
    onChanged: (_) => setState(() {}),
  ),
);

void main() {
  testWidgets('se construit sans assertion de FocusNode partagé', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_tile()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Qualité du flux'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('le Focus parent et le sélecteur n\'utilisent pas le même nœud', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_tile()));
    await tester.pumpAndSettle();

    // Le Focus parent n'expose plus de nœud : il n'est qu'un repère visuel.
    final parent = tester.widget<Focus>(
      find
          .ancestor(
            of: find.byType(ListTile),
            matching: find.byType(Focus),
          )
          .first,
    );
    expect(parent.focusNode, isNull);

    // …tandis que le DropdownButton porte son propre nœud focalisable.
    final dropdownNodes = <FocusNode>[];
    void visit(Element element) {
      final w = element.widget;
      if (w is Focus && w.focusNode != null) dropdownNodes.add(w.focusNode!);
      element.visitChildren(visit);
    }

    tester.element(find.byType(DropdownButton<String>)).visitChildren(visit);
    expect(
      dropdownNodes,
      isNotEmpty,
      reason: 'le sélecteur doit être atteignable au D-pad',
    );
  });

  testWidgets('le sélecteur prend le focus et Entrée ouvre le menu', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_tile()));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final primary = FocusManager.instance.primaryFocus;
    expect(primary, isNotNull, reason: 'la traversée doit atterrir quelque part');
    expect(
      primary!.hasFocus,
      isTrue,
      reason: 'le Focus parent (canRequestFocus: false) doit être contourné',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Haute'), findsWidgets);
  });
}
