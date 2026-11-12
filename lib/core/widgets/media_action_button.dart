import 'package:flutter/material.dart';

class MediaActionButton extends StatefulWidget {
  const MediaActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isTvLayout,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isTvLayout;
  final bool autofocus;

  @override
  State<MediaActionButton> createState() => _MediaActionButtonState();
}

class _MediaActionButtonState extends State<MediaActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _focused ? 1.06 : 1,
      duration: const Duration(milliseconds: 150),
      child: FilledButton.icon(
        autofocus: widget.autofocus,
        onPressed: widget.onPressed,
        onFocusChange: (focused) => setState(() => _focused = focused),
        icon: Icon(widget.icon, size: widget.isTvLayout ? 22.5 : 20),
        label: Text(widget.label),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.5),
          minimumSize:
              widget.isTvLayout ? const Size(165, 48) : const Size(0, 44),
          padding: EdgeInsets.symmetric(
            vertical: widget.isTvLayout ? 12.75 : 10,
            horizontal: widget.isTvLayout ? 22.5 : 16,
          ),
          textStyle: TextStyle(
            fontSize: widget.isTvLayout ? 15 : 14,
            fontWeight: FontWeight.w700,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: colors.onPrimaryContainer, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
