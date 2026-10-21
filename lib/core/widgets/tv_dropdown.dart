import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

/// Dropdown focusable TV (D-pad) pour remplacer PopupMenuButton.
///
/// Utilisation :
/// ```dart
/// TvDropdown<String>(
///   value: selectedValue,
///   items: [
///     TvDropdownItem(value: 'edit', label: 'Modifier', icon: Icons.edit),
///     TvDropdownItem(value: 'delete', label: 'Supprimer', icon: Icons.delete),
///   ],
///   onChanged: (v) => handleAction(v),
///   focusNode: _dropdownFocus,
/// )
/// ```
class TvDropdownItem<T> {
  const TvDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
}

class TvDropdown<T> extends StatefulWidget {
  const TvDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.focusNode,
    this.label,
    this.hint,
    this.autofocus = false,
    this.enabled = true,
  });

  final T? value;
  final List<TvDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final bool autofocus;
  final bool enabled;

  @override
  State<TvDropdown<T>> createState() => _TvDropdownState<T>();
}

class _TvDropdownState<T> extends State<TvDropdown<T>> {
  late FocusNode _focusNode;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _closeDropdown();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _showOverlay();
      } else {
        _closeDropdown();
      }
    });
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(context),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _selectItem(T value) {
    widget.onChanged(value);
    _closeDropdown();
    _focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      _toggleDropdown();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.gameButtonB) {
      if (_isOpen) {
        _closeDropdown();
        return KeyEventResult.handled;
      }
    }

    if (_isOpen) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Navigation dans l'overlay gérée par le focus interne
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        return KeyEventResult.ignored;
      }
    }

    return KeyEventResult.ignored;
  }

  Widget _buildOverlay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    return Stack(
      children: [
        // Barrière pour fermer au clic extérieur
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Dropdown positionné sous le bouton
        Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4,
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: scheme.surfaceContainerHigh,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300, minWidth: 200),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = widget.value == item.value;
                      return _DropdownItemTile<T>(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => _selectItem(item.value),
                        autofocus: index == 0 && _isOpen,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: TvFocus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onActivate: _toggleDropdown,
        onKeyEvent: _onKey,
        onFocusChange: (hasFocus) {
          if (!hasFocus && _isOpen) {
            _closeDropdown();
          }
        },
        child: InkWell(
          onTap: widget.enabled ? _toggleDropdown : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOpen ? scheme.primary : scheme.outlineVariant,
                width: _isOpen ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedItem.icon != null) ...[
                  Icon(
                    selectedItem.icon,
                    size: 20,
                    color: selectedItem.iconColor ?? scheme.primary,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  selectedItem.label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: scheme.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItemTile<T> extends StatefulWidget {
  const _DropdownItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.autofocus = false,
  });

  final TvDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  State<_DropdownItemTile<T>> createState() => _DropdownItemTileState<T>();
}

class _DropdownItemTileState<T> extends State<_DropdownItemTile<T>> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _focused
                ? scheme.primary.withValues(alpha: 0.15)
                : widget.isSelected
                    ? scheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 20,
                  color: widget.item.isDestructive
                      ? scheme.error
                      : (widget.item.iconColor ?? scheme.onSurface),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.item.isDestructive
                        ? scheme.error
                        : scheme.onSurface,
                    fontSize: 14,
                    fontWeight: _focused || widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_circle, color: scheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}