import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/edge_locked_focus_group.dart';

void main() {
  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('horizontal group stops at edges without wrapping',
      (tester) async {
    final nodes = List.generate(4, (i) => FocusNode(debugLabel: 'n$i'));
    addTearDown(() {
      for (final n in nodes) {
        n.dispose();
      }
    });
    await tester.pumpWidget(MaterialApp(
      home: EdgeLockedFocusGroup(
        axis: Axis.horizontal,
        child: Row(children: [
          for (final n in nodes)
            Focus(focusNode: n, child: const SizedBox(width: 50, height: 50)),
        ]),
      ),
    ));
    nodes.first.requestFocus();
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await press(tester, LogicalKeyboardKey.arrowRight);
    }
    expect(nodes.last.hasPrimaryFocus, isTrue);
    for (var i = 0; i < 6; i++) {
      await press(tester, LogicalKeyboardKey.arrowLeft);
    }
    expect(nodes.first.hasPrimaryFocus, isTrue);
  });
}
