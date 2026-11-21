import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_loading_cinematic.dart';

void main() {
  double opacity(WidgetTester tester, int index) => tester
      .widget<Opacity>(find.byKey(ValueKey('orbit-letter-$index')))
      .opacity;

  testWidgets('reveals letters, blinks twice and repeats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OrbitLoadingCinematic())),
    );
    await tester.pump();
    expect([for (var i = 0; i < 5; i++) opacity(tester, i)], [1, 0, 0, 0, 0]);
    await tester.pump(const Duration(milliseconds: 750));
    expect([for (var i = 0; i < 5; i++) opacity(tester, i)], [1, 1, 1, 1, 0]);
    await tester.pump(const Duration(milliseconds: 300));
    expect([for (var i = 0; i < 5; i++) opacity(tester, i)], [1, 1, 1, 1, 1]);
    await tester.pump(const Duration(milliseconds: 950));
    expect([for (var i = 0; i < 5; i++) opacity(tester, i)], [0, 0, 0, 0, 0]);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(tester, 0), 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(tester, 0), 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(tester, 0), 1);
    await tester.pump(const Duration(milliseconds: 700));
    expect([for (var i = 0; i < 5; i++) opacity(tester, i)], [1, 0, 0, 0, 0]);
  });

  testWidgets('loading animation appears only after two seconds',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: OrbitDelayedLoadingIndicator()),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(OrbitLoadingCinematic), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(OrbitLoadingCinematic), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion keeps all letters visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(body: OrbitLoadingCinematic()),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    expect([for (var i = 0; i < 5; i++) opacity(tester, i)], [1, 1, 1, 1, 1]);
  });

  testWidgets('fits a compact multi-video cell', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 120,
          height: 80,
          child: OrbitLoadingCinematic(),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(OrbitLoadingCinematic)),
        const Size(120, 80));
  });
}
