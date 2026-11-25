import 'package:flutter/material.dart';

/// Bouton d'action dans le même style que « Regarder » sur la TV.
class TvWatchStyleButton extends StatelessWidget {
  const TvWatchStyleButton({
    super.key,
    required this.focusNode,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.autofocus = false,
  });

  final FocusNode focusNode;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    const focusColor = Color(0xFF00CFE8);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedScale(
          scale: focused ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: focusColor.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: FilledButton.icon(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                focused ? label.toUpperCase() : label,
                style: TextStyle(
                  fontWeight: focused ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: focused ? 1.2 : 0,
                ),
                textAlign: TextAlign.center,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: focused ? focusColor : scheme.primary,
                foregroundColor: focused ? Colors.black : scheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ).copyWith(
                side: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? const BorderSide(color: Colors.white, width: 4)
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
