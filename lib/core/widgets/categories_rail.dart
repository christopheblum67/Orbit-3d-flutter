import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/models/category.dart';

/// Barre latérale de catégories, fixe à gauche.
///
/// - Sur petit écran : format compact (~76px, icônes + libellés courts)
///   pour préserver l'espace du contenu.
/// - Sur grand écran : format large (180px, libellés complets).
///
/// Compatible TV : chaque tuile est focusable au D-pad (haut/bas) avec un
/// indicateur de focus visible, et activable via OK/Entrée ou au tap.
class CategoriesRail extends StatelessWidget {
  const CategoriesRail({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.title = 'Catégories',
  });

  final List<MediaCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Container(
      width: isWide ? 208 : 96,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          if (isWide)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
            ),
          for (final category in categories)
            _FocusableCategoryTile(
              name: category.name,
              selected: category.id == selectedId,
              compact: !isWide,
              onTap: () => onSelected(category.id),
            ),
        ],
      ),
    );
  }
}

class _FocusableCategoryTile extends StatefulWidget {
  const _FocusableCategoryTile({
    required this.name,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_FocusableCategoryTile> createState() =>
      _FocusableCategoryTileState();
}

class _FocusableCategoryTileState extends State<_FocusableCategoryTile> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused != _hasFocus) {
      setState(() => _hasFocus = focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final showRing = selected || _hasFocus;
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.compact ? 4 : 6,
            vertical: 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 16,
            vertical: widget.compact ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: showRing
                  ? scheme.primary
                  : Colors.transparent,
              width: _hasFocus ? 2.5 : 1.5,
            ),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: showRing ? scheme.primary : scheme.onSurface,
                  fontSize: widget.compact ? 12 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
