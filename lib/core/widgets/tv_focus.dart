import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocus extends StatelessWidget {
  final Widget child;
  final FocusNode? focusNode;
  final void Function()? onActivate;
  final void Function(bool focused)? onFocusChange;

  const TvFocus({
    super.key,
    required this.child,
    this.focusNode,
    this.onActivate,
    this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (focused) {
        if (focused) {
          HapticFeedback.selectionClick();
        }
        onFocusChange?.call(focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          HapticFeedback.heavyImpact();
          onActivate?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: onActivate,
        child: child,
      ),
    );
  }
}
