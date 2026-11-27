import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/directional_focus_boundary.dart';

void main() {
  testWidgets('vertical grid blocks the bottom and can exit up or sideways',
      (tester) async {
    final nodes = List.generate(29, (_) => FocusNode());
    final category = FocusNode();
    final above = FocusNode();
    final below = FocusNode();
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
      category.dispose();
      above.dispose();
      below.dispose();
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Focus(focusNode: above, child: const SizedBox(height: 50)),
            Expanded(
              child: Row(
                children: [
                  Focus(focusNode: category, child: const SizedBox(width: 100)),
                  Expanded(
                    child: DirectionalFocusBoundary(
                      lockedAxis: Axis.vertical,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisExtent: 100,
                        ),
                        itemCount: nodes.length,
                        itemBuilder: (_, index) => Focus(
                          focusNode: nodes[index],
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Focus(focusNode: below, child: const SizedBox(height: 50)),
          ],
        ),
      ),
    ));

    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    nodes[0].requestFocus();
    await tester.pump();
    await press(LogicalKeyboardKey.arrowUp);
    expect(above.hasPrimaryFocus, isTrue);
    nodes[0].requestFocus();
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await press(LogicalKeyboardKey.arrowDown);
    }
    expect(nodes[27].hasPrimaryFocus, isTrue);
    expect(FocusManager.instance.primaryFocus, isNot(category));
    await press(LogicalKeyboardKey.arrowRight);
    expect(nodes[28].hasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(nodes[28].hasPrimaryFocus, isTrue);
    expect(below.hasPrimaryFocus, isFalse);
    await press(LogicalKeyboardKey.arrowLeft);
    for (var i = 0; i < 9; i++) {
      await press(LogicalKeyboardKey.arrowUp);
    }
    expect(nodes[0].hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowUp);
    expect(above.hasPrimaryFocus, isTrue);
    nodes[0].requestFocus();
    await tester.pump();
    await press(LogicalKeyboardKey.arrowLeft);
    expect(category.hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowRight);
    expect(nodes.any((node) => node.hasPrimaryFocus), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('horizontal carousel stays at ends and can exit vertically',
      (tester) async {
    final nodes = List.generate(18, (_) => FocusNode());
    final below = FocusNode();
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
      below.dispose();
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 100,
              child: DirectionalFocusBoundary(
                lockedAxis: Axis.horizontal,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemExtent: 100,
                  itemCount: nodes.length,
                  itemBuilder: (_, index) => Focus(
                    focusNode: nodes[index],
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Focus(focusNode: below, child: const SizedBox(height: 100)),
          ],
        ),
      ),
    ));
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    nodes[0].requestFocus();
    await tester.pump();
    await press(LogicalKeyboardKey.arrowLeft);
    expect(nodes[0].hasPrimaryFocus, isTrue);
    for (var i = 0; i < 20; i++) {
      await press(LogicalKeyboardKey.arrowRight);
    }
    expect(nodes.last.hasPrimaryFocus, isTrue);
    for (var i = 0; i < 20; i++) {
      await press(LogicalKeyboardKey.arrowLeft);
    }
    expect(nodes.first.hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowDown);
    expect(below.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
