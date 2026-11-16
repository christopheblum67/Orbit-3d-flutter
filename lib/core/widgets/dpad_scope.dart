import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DpadScope extends StatelessWidget {
  const DpadScope({super.key, required this.child});

  final Widget child;

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final focus = FocusManager.instance.primaryFocus;
    final editable =
        focus?.context?.findAncestorStateOfType<EditableTextState>();
    if (focus == null || editable == null) return KeyEventResult.ignored;
    final selection = editable.widget.controller.selection;
    final length = editable.widget.controller.text.length;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowRight
          when !selection.isValid ||
              (selection.isCollapsed && selection.extentOffset >= length) =>
        TraversalDirection.right,
      LogicalKeyboardKey.arrowLeft
          when !selection.isValid ||
              (selection.isCollapsed && selection.extentOffset <= 0) =>
        TraversalDirection.left,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    focus.focusInDirection(direction);
    return KeyEventResult.handled;
  }

  static ButtonStyle _style() => ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.focused) ? const Color(0xFFFFC107) : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused) ? Colors.black : null,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused) ? Colors.black : null,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? const BorderSide(color: Colors.white, width: 3)
              : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(style: _style()),
        textButtonTheme: TextButtonThemeData(style: _style()),
        outlinedButtonTheme: OutlinedButtonThemeData(style: _style()),
        iconButtonTheme: IconButtonThemeData(style: _style()),
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: child,
      ),
    );
  }
}
