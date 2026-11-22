/// Vérifie que `TvFocus` avec `onActivate` non null reçoit l'activation Enter/OK
/// même quand un `onKeyEvent` custom est fourni. Sans ce correctif, le bouton
/// « Ajouter / Annuler » dans le dialogue d'abonnement restait inerte au D-pad.
///
/// Le test envoie une vraie touche clavier (et non un `tap`) : c'est le chemin
/// `Focus.onKeyEvent` qu'on veut couvrir, pas le geste tactile.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('TvFocus activation chaining', () {
    testWidgets('Enter active le bouton même avec custom onKeyEvent',
        (tester) async {
      var activated = false;
      await tester.pumpWidget(
        _host(
          TvFocus(
            autofocus: true,
            onActivate: () => activated = true,
            onKeyEvent: (node, event) {
              // Custom handler qui ignore Enter (simule le formulaire abonnement)
              return KeyEventResult.ignored;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      // Laisse l'autofocus s'appliquer avant l'envoi de la touche.
      await tester.pump();

      // Avant le correctif, le handler custom court-circuitait `_handleKeyEvent`
      // et `onActivate` n'était jamais appelé. Après le correctif (chaînage),
      // `onActivate` est appelé même si le handler custom ignore.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(activated, isTrue);
    });

    testWidgets('un handler custom qui consomme la touche coupe l\'activation',
        (tester) async {
      var activated = false;
      var customSeen = false;
      await tester.pumpWidget(
        _host(
          TvFocus(
            autofocus: true,
            onActivate: () => activated = true,
            onKeyEvent: (node, event) {
              customSeen = true;
              return KeyEventResult.handled;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(customSeen, isTrue);
      expect(activated, isFalse,
          reason: 'un handler custom qui répond `handled` garde la priorité');
    });

    testWidgets('sans onActivate, la touche n\'est pas consommée',
        (tester) async {
      // Cas d'un TvFocus qui enveloppe un champ de saisie : Espace/Entrée
      // doivent continuer d'aller au champ enfant.
      await tester.pumpWidget(
        _host(
          TvFocus(
            autofocus: true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
