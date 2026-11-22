class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.themeId,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String themeId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? scheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForTheme(themeId),
              size: 18,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? scheme.primary : scheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTheme(String themeId) {
    switch (themeId) {
      case 'characters':
        return Icons.face;
      case 'smileys':
        return Icons.sentiment_very_satisfied;
      case 'blackWhite':
        return Icons.circle_outlined;
      case 'pixels':
        return Icons.apps;
      default:
        return Icons.image;
    }
  }
}