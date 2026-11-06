import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Permet de remonter tout en haut d'une page défilante à la télécommande :
/// quand la flèche haut ne trouve plus aucun élément focusable au-dessus
/// (en-tête purement visuel), la page est ramenée au début.
class TvScrollToTop extends StatelessWidget {
  const TvScrollToTop({super.key, required this.child});

  final Widget child;

  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final scrollable = _verticalScrollable(
      FocusManager.instance.primaryFocus?.context,
    );
    final moved =
        FocusScope.of(context).focusInDirection(TraversalDirection.up);
    if (moved) {
      // Le focus a quitté la zone défilante (ex. barre d'actions) : on
      // ramène quand même la page tout en haut.
      final newScrollable = _verticalScrollable(
        FocusManager.instance.primaryFocus?.context,
      );
      if (scrollable != null && newScrollable != scrollable) {
        _scrollToTop(scrollable);
      }
      return KeyEventResult.handled;
    }
    if (scrollable == null) return KeyEventResult.ignored;
    return _scrollToTop(scrollable)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  /// Défileur vertical le plus proche du focus (ignore les carrousels).
  ScrollableState? _verticalScrollable(BuildContext? focusContext) {
    if (focusContext == null) return null;
    ScrollableState? scrollable = Scrollable.maybeOf(focusContext);
    while (scrollable != null && scrollable.axisDirection.index.isOdd) {
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    return scrollable;
  }

  bool _scrollToTop(ScrollableState scrollable) {
    final position = scrollable.position;
    if (position.pixels <= position.minScrollExtent) return false;
    position.animateTo(
      position.minScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => _onKey(context, event),
      child: child,
    );
  }
}
