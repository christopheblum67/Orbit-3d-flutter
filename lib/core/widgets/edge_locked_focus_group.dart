import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Déplace le focus D-pad entre les éléments d'une liste/barre dans l'ordre
/// visuel, sans jamais boucler : aux extrémités la touche est consommée, le
/// focus reste sur le premier/dernier élément.
class EdgeLockedFocusGroup extends StatelessWidget {
  const EdgeLockedFocusGroup({
    super.key,
    required this.axis,
    required this.child,
  });

  final Axis axis;
  final Widget child;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final forward = axis == Axis.horizontal
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowDown;
    final backward = axis == Axis.horizontal
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowUp;
    if (key != forward && key != backward) return KeyEventResult.ignored;
    final current = FocusManager.instance.primaryFocus;
    if (current == null) return KeyEventResult.ignored;
    final items = node.traversalDescendants.toList()
      ..sort((a, b) => axis == Axis.horizontal
          ? a.rect.left.compareTo(b.rect.left)
          : a.rect.top.compareTo(b.rect.top));
    final index = items.indexOf(current);
    if (index < 0) return KeyEventResult.ignored;
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final target = index + (key == forward ? 1 : -1);
    if (target < 0 || target >= items.length) return KeyEventResult.handled;
    final next = items[target];
    next.requestFocus();
    final context = next.context;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: child,
    );
  }
}
