import 'package:flutter/material.dart';

/// Bouton d'action principal très lisible au D-pad : au focus, fond ambre,
/// texte/icône noirs, bordure blanche, agrandissement et halo ambre.
class TvPrimaryButton extends StatefulWidget {
  const TvPrimaryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.autofocus = false,
    this.focusNode,
    this.minimumSize,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final bool autofocus;
  final FocusNode? focusNode;
  final Size? minimumSize;
  final EdgeInsetsGeometry? padding;

  static const Color amber = Color(0xFFFFC107);

  @override
  State<TvPrimaryButton> createState() => _TvPrimaryButtonState();
}

class _TvPrimaryButtonState extends State<TvPrimaryButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return AnimatedScale(
      scale: _focused ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: TvPrimaryButton.amber.withValues(alpha: 0.7),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ]
              : const [],
        ),
        child: FilledButton.icon(
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          onPressed: widget.onPressed,
          onFocusChange: (v) => setState(() => _focused = v),
          icon: widget.icon,
          label: widget.label,
          style: FilledButton.styleFrom(
            minimumSize: widget.minimumSize,
            padding: widget.padding ??
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.focused)
                  ? TvPrimaryButton.amber
                  : null,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.focused) ? Colors.black : null,
            ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            side: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.focused)
                  ? const BorderSide(color: Colors.white, width: 4)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
