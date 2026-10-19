import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';

/// Test de non-régression : la couleur par défaut de [AppCard] doit provenir
/// du thème (`colorScheme.surfaceContainer`) et non d'une constante codée en dur
/// (anciennement 0xFF33181C).
///
/// Ce test échoue sur l'ancien code (couleur hardcodée) et passe après la
/// correction systémique.
void main() {
  // Palette de test connue : surfaceContainer = 0xFF2C2C2C (exemple dark)
  final testColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00B8D4), // Cyan palette
    brightness: Brightness.dark,
  );

  Widget buildTestApp({ColorScheme? colorScheme, Widget? child}) => MaterialApp(
        theme: ThemeData(
          colorScheme: colorScheme ?? testColorScheme,
          useMaterial3: true,
        ),
        home: Scaffold(body: Center(child: child ?? const AppCard(child: Text('Test')))),
      );

  testWidgets('AppCard sans couleur explicite utilise surfaceContainer du thème', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Trouve l'AnimatedContainer qui porte la décoration
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(AnimatedContainer),
      ).first,
    );

    final decoration = container.decoration as BoxDecoration?;
    expect(decoration, isNotNull, reason: 'AppCard doit avoir une BoxDecoration');

    final backgroundColor = decoration!.color;
    expect(
      backgroundColor,
      equals(testColorScheme.surfaceContainer),
      reason:
          'La couleur de fond par défaut doit être colorScheme.surfaceContainer '
          'du thème, pas une constante hardcodée (ex. 0xFF33181C). '
          'Reçu: ${backgroundColor?.value.toRadixString(16)}, '
          'attendu: ${testColorScheme.surfaceContainer.value.toRadixString(16)}',
    );

    // Vérifie aussi que ce n'est PAS l'ancienne valeur hardcodée
    expect(
      backgroundColor,
      isNot(equals(const Color(0xFF33181C))),
      reason: 'L\'ancienne couleur par défaut hardcodée (0xFF33181C) ne doit plus être utilisée',
    );
  });

  testWidgets('AppCard avec color: Colors.transparent n\'a pas de bordure/ombre', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(
      child: const AppCard(color: Colors.transparent, child: Text('Transparent')),
    ));
    await tester.pumpAndSettle();

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(AnimatedContainer),
      ).first,
    );

    final decoration = container.decoration as BoxDecoration?;
    expect(decoration, isNotNull);
    expect(decoration!.border, isNull, reason: 'Carte transparente => pas de bordure');
    expect(decoration.boxShadow, isNull, reason: 'Carte transparente => pas d\'ombre');
    expect(decoration.color, equals(Colors.transparent));
  });

  testWidgets('AppCard avec couleur explicite utilise cette couleur', (tester) async {
    const customColor = Color(0xFF123456);
    await tester.pumpWidget(buildTestApp(
      child: const AppCard(color: customColor, child: Text('Custom')),
    ));
    await tester.pumpAndSettle();

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(AnimatedContainer),
      ).first,
    );

    final decoration = container.decoration as BoxDecoration?;
    expect(decoration, isNotNull);
    expect(decoration!.color, equals(customColor));
  });

  testWidgets('Bordure par défaut utilise outlineVariant du thème', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(AnimatedContainer),
      ).first,
    );

    final decoration = container.decoration as BoxDecoration?;
    expect(decoration, isNotNull);
    expect(
      decoration!.border,
      isNotNull,
      reason: 'Carte non-transparente => bordure présente',
    );
    final borderColor = decoration.border!.top.color;
    expect(
      borderColor,
      equals(testColorScheme.outlineVariant),
      reason: 'La bordure par défaut doit être colorScheme.outlineVariant du thème',
    );
  });
}