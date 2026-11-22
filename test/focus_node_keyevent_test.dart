/// Diagnostic D-pad du formulaire d'abonnement.
///
/// `_SubscriptionFormDialog` pose `onKeyEvent` sur des `FocusNode` créés à la
/// main, puis les passe à des `TextFormField`. Si `FocusNode.attach` réécrit
/// `onKeyEvent` avec celui du widget `Focus` interne d'`EditableText` (null),
/// les flèches Haut/Bas ne changent plus de champ : c'est exactement le
/// symptôme « le D-pad ne répond pas dans le dialogue ».
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un FocusNode de TextFormField conserve son onKeyEvent',
      (tester) async {
    var seen = 0;
    final node = FocusNode(
      debugLabel: 'test.field',
      onKeyEvent: (n, e) {
        seen++;
        return KeyEventResult.ignored;
      },
    );
    addTearDown(node.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextFormField(focusNode: node),
        ),
      ),
    );
    await tester.pump();

    expect(node.onKeyEvent, isNotNull,
        reason: 'FocusNode.attach ne doit pas effacer le handler fourni');

    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(seen, greaterThan(0));
  });
}
