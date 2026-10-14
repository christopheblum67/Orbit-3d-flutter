import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le motif « `await` puis accès à l'État », mesuré à l'exécution.
///
/// Un détecteur statique a été tenté puis abandonné : chaque heuristique
/// ajoutée produisait de nouveaux faux positifs (arguments de l'appel attendu,
/// corps de closure `async`, gardes de bloc, frontières de méthode). Un outil
/// de ce genre coûte plus qu'il ne protège, et un faux positif dans une suite
/// de tests apprend à l'équipe à ignorer les avertissements.
///
/// Ce test prend l'autre chemin : il EXÉCUTE le motif et mesure ce qui se
/// passe au moment où la suspension se résout. C'est la propriété qui rend les
/// 21 gardes ajoutées nécessaires — et non théoriques.
class _AsyncResume extends StatefulWidget {
  const _AsyncResume({required this.gate});

  final Completer<void> gate;

  @override
  State<_AsyncResume> createState() => _AsyncResumeState();
}

class _AsyncResumeState extends State<_AsyncResume> {
  /// `mounted` tel qu'il était quand la suspension s'est résolue.
  bool? mountedWhenResumed;

  /// La garde `mounted` se serait-elle déclenchée ?
  bool guardWouldHaveFired = false;

  bool _done = false;

  Future<void> _run() async {
    await widget.gate.future;
    // C'est la ligne que 21 sites d'application ont franchie sans se protéger.
    mountedWhenResumed = mounted;
    if (!mounted) {
      guardWouldHaveFired = true;
      return;
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _run,
      child: Text(_done ? 'fait' : 'en cours'),
    );
  }
}

void main() {
  testWidgets(
      'la suspension se résout sur un State DÉMONTÉ : la garde est indispensable',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _AsyncResume(gate: gate)),
      ),
    );

    final state = tester.state<_AsyncResumeState>(find.byType(_AsyncResume));

    await tester.tap(find.text('en cours'));
    await tester.pump();

    // Sortie de l'écran avec la télécommande, l'appel est encore en attente.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(state.mounted, isFalse, reason: 'précondition du test');

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    // Le cœur de la démonstration : sans ce `if (!mounted) return;`, les 21
    // sites corrigés exécutaient un `setState` ou lisaient `ref` sur un State
    // déjà défunt.
    expect(
      state.mountedWhenResumed,
      isFalse,
      reason: 'la continuation doit observer un State démonté',
    );
    expect(state.guardWouldHaveFired, isTrue);
    // Aucune exception : la sortie par la garde est propre.
    expect(tester.takeException(), isNull);
  });

  testWidgets('la même suspension résolue AVANT le démontage reste saine',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _AsyncResume(gate: gate)),
      ),
    );

    final state = tester.state<_AsyncResumeState>(find.byType(_AsyncResume));

    await tester.tap(find.text('en cours'));
    await tester.pump();
    // L'appel se termine alors que l'écran est encore là.
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(state.mountedWhenResumed, isTrue);
    expect(state.guardWouldHaveFired, isFalse);
    expect(find.text('fait'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
