import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Stops directional traversal at the edges of [lockedAxis] only.
class DirectionalFocusBoundary extends StatefulWidget {
  const DirectionalFocusBoundary({
    super.key,
    required this.lockedAxis,
    required this.child,
  });

  final Axis lockedAxis;
  final Widget child;

  @override
  State<DirectionalFocusBoundary> createState() =>
      _DirectionalFocusBoundaryState();
}

class _DirectionalFocusBoundaryState extends State<DirectionalFocusBoundary> {
  final _scope = FocusScopeNode(
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    final isVertical = direction == TraversalDirection.up ||
        direction == TraversalDirection.down;
    if (isVertical != (widget.lockedAxis == Axis.vertical)) {
      return KeyEventResult.ignored;
    }
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.nearestScope != _scope) {
      return KeyEventResult.ignored;
    }
    _scope.directionalTraversalEdgeBehavior = TraversalEdgeBehavior.stop;
    try {
      focus.focusInDirection(direction);
    } finally {
      _scope.directionalTraversalEdgeBehavior =
          TraversalEdgeBehavior.parentScope;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => FocusScope(
        node: _scope,
        onKeyEvent: _onKey,
        child: widget.child,
      );
}
