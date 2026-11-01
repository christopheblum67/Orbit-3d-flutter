/// Reproduit la rangée d'actions du dialogue d'abonnement
/// (`AlertDialog` + `TvFocus(focusNode:)` + `TextButton`/`FilledButton`) pour
/// vérifier quelles touches activent réellement les boutons.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

class _Host extends StatelessWidget {
  const _Host({
    required this.cancelFocus,
    required this.saveFocus,
    required this.onCancel,
    required this.onSave,
  });

  final FocusNode cancelFocus;
  final FocusNode saveFocus;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AlertDialog(
          title: const Text('Nouvel abonnement'),
          content: const Text('…'),
          actions: [
            TvFocus(
              focusNode: cancelFocus,
              onActivate: onCancel,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.escape ||
                        event.logicalKey == LogicalKeyboardKey.gameButtonB)) {
                  onCancel();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Annuler'),
              ),
            ),
            TvFocus(
              focusNode: saveFocus,
              onActivate: onSave,
              onKeyEvent: (node, event) => KeyEventResult.ignored,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  Future<({int cancel, int save})> pumpAndPress(
    WidgetTester tester,
    LogicalKeyboardKey key,
  ) async {
    var cancel = 0;
    var save = 0;
    final cancelFocus = FocusNode(debugLabel: 'cancel');
    final saveFocus = FocusNode(debugLabel: 'save');
    addTearDown(cancelFocus.dispose);
    addTearDown(saveFocus.dispose);

    await tester.pumpWidget(
      _Host(
        cancelFocus: cancelFocus,
        saveFocus: saveFocus,
        onCancel: () => cancel++,
        onSave: () => save++,
      ),
    );
    await tester.pump();

    saveFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(key);
    await tester.pump();
    return (cancel: cancel, save: save);
  }

  const keys = <String, LogicalKeyboardKey>{
    'enter': LogicalKeyboardKey.enter,
    'numpadEnter': LogicalKeyboardKey.numpadEnter,
    'select': LogicalKeyboardKey.select,
    'space': LogicalKeyboardKey.space,
    'gameButtonA': LogicalKeyboardKey.gameButtonA,
  };

  for (final entry in keys.entries) {
    testWidgets('touche ${entry.key} active le bouton focalisé',
        (tester) async {
      final counts = await pumpAndPress(tester, entry.value);
      expect(counts.save, 1,
          reason: '${entry.key} doit activer « Ajouter » exactement une fois');
      expect(counts.cancel, 0);
    });
  }

  testWidgets('le bouton interne focalisé s\'active aussi', (tester) async {
    var save = 0;
    final cancelFocus = FocusNode(debugLabel: 'cancel');
    final saveFocus = FocusNode(debugLabel: 'save');
    addTearDown(cancelFocus.dispose);
    addTearDown(saveFocus.dispose);
    await tester.pumpWidget(
      _Host(
        cancelFocus: cancelFocus,
        saveFocus: saveFocus,
        onCancel: () {},
        onSave: () => save++,
      ),
    );
    await tester.pump();
    // Le FilledButton a son propre FocusNode interne : on l'atteint par le
    // parcours clavier (Tab), pas par `saveFocus`.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(save, 1);
  });
}
