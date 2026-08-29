import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocus extends StatelessWidget {
  final Widget child;
  final FocusNode? focusNode;
  final void Function()? onActivate;

  const TvFocus({
    super.key,
    required this.child,
    this.focusNode,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
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
