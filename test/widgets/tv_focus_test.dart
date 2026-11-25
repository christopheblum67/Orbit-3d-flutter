import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';

void main() {
  testWidgets('le fond du focus couvre toute la tuile sans masquer le contenu',
      (tester) async {
    final container = ProviderContainer();
    container.read(tvModeNotifierProvider).enable();
    addTearDown(container.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var activated = 0;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 240,
                child: TvFocus(
                  focusNode: focusNode,
                  fillFocusBackground: true,
                  onActivate: () => activated++,
                  child: const Column(
                    children: [
                      Expanded(
                        child: ColoredBox(
                          key: ValueKey('poster'),
                          color: Colors.red,
                        ),
                      ),
                      Text('Un titre sur deux lignes'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final focus = find.byType(TvFocus);
    final box = find.descendant(
      of: focus,
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.widget<AnimatedContainer>(box).decoration, isNull);
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    final decoration =
        tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
    expect(
      decoration.color,
      Theme.of(tester.element(focus))
          .colorScheme
          .primary
          .withValues(alpha: 0.08),
    );
    expect(
      tester.getRect(box).contains(
            tester.getCenter(find.text('Un titre sur deux lignes')),
          ),
      isTrue,
    );
    expect(
      tester.widget<ColoredBox>(find.byKey(const ValueKey('poster'))).color,
      Colors.red,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, 1);
    focusNode.unfocus();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedContainer>(box).decoration, isNull);
  });

  testWidgets('TvFocus applique les effets en mode TV quand focusé', (tester) async {
    final container = ProviderContainer();
    container.read(tvModeControllerProvider).enable();
    addTearDown(container.dispose);

    final focusNode = FocusNode();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TvFocus(
              focusNode: focusNode,
              autofocus: false,
              child: const Text('Focusable'),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(find.byType(TvFocus), findsOneWidget);
    expect(find.text('Focusable'), findsOneWidget);
  });

  testWidgets('TvModeDetector active le mode TV sur interaction clavier', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TvModeDetector(
              // Un descendant doit avoir le focus pour que l'événement clavier
              // remonte jusqu'au `Focus` du détecteur.
              child: Focus(
                autofocus: true,
                child: const Text('Detect'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(container.read(tvModeProvider), true);
  });

  testWidgets('la touche Espace n active pas le mode TV', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TvModeDetector(
              child: Focus(
                autofocus: true,
                child: const Text('Detect'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // `space` sort du clavier virtuel d'un téléphone (champ de recherche) et
    // activait le mode TV : l'overscan encadrait alors toute l'application.
    // `goBack` est retiré des déclencheurs pour la même raison, mais il n'est
    // pas simulable ici : Flutter ne fournit aucune touche physique associée
    // (`sendKeyEvent` lève une assertion), la touche Retour Android ne passant
    // pas par le système de touches.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(
      container.read(tvModeProvider),
      false,
      reason: 'la barre espace du clavier virtuel ne doit pas activer le mode '
          "TV (il encadrerait alors toute l'application)",
    );
  });

  testWidgets('Extension tvFocus fonctionne', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: const Text('Test').tvFocus(),
          ),
        ),
      ),
    );

    expect(find.byType(TvFocus), findsOneWidget);
  });
}
