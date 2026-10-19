import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';

void main() {
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
