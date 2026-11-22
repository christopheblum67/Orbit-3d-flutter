import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/responsive_grid.dart';

/// Nombre maximum de profils autorisés
const int kMaxProfiles = 6;

class AvatarItem {
  final String id;
  final String name;
  final String category;
  final String assetPath;
  final IconData? icon;
  final Color? color;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.icon,
    this.color,
  });
}

/// Sélecteur d'avatar — grille unique de tous les avatars (TV-friendly)
///
/// Affiche :
/// - En-tête : nom/pseudo + barre de texte
/// - Grille unique de tous les avatars (6 colonnes)
/// - Navigation D-pad complète (←/→/↑/↓/Enter/Select/Space/GamepadA)
class ProfileAvatarSelector extends StatefulWidget {
  final List<AvatarItem> avatars;
  final String selectedAvatarId;
  final Function(AvatarItem) onAvatarSelected;
  final String? profileName;

  const ProfileAvatarSelector({
    super.key,
    required this.avatars,
    required this.selectedAvatarId,
    required this.onAvatarSelected,
    this.profileName,
  });

  @override
  State<ProfileAvatarSelector> createState() => _ProfileAvatarSelectorState();
}

class _ProfileAvatarSelectorState extends State<ProfileAvatarSelector> {
  late List<FocusNode> _avatarFocusNodes;
  final ScrollController _gridScroll = ScrollController();
  int _focusedIndex = 0;
  int _columns = 1;
  double _rowExtent = 0;
  String? _selectedCategory;

  List<AvatarItem> get _filteredAvatars => _selectedCategory == null
      ? widget.avatars
      : widget.avatars.where((a) => a.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();

    // Trouve l'index de l'avatar actuellement sélectionné
    final selectedIndex = widget.avatars.indexWhere(
      (a) => a.id == widget.selectedAvatarId,
    );
    _focusedIndex = selectedIndex >= 0 ? selectedIndex : 0;

    _avatarFocusNodes = List.generate(
      widget.avatars.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    for (final node in _avatarFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatarSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatars.length != widget.avatars.length) {
      for (final node in _avatarFocusNodes) {
        node.dispose();
      }
      _avatarFocusNodes = List.generate(widget.avatars.length, (_) => FocusNode());
      _focusedIndex = 0;
    }
    if (_selectedCategory != null &&
        !widget.avatars.any((a) => a.category == _selectedCategory)) {
      _selectedCategory = null;
      _focusedIndex = 0;
    }
    if (_focusedIndex >= _filteredAvatars.length) _focusedIndex = 0;
  }

  void _onAvatarSelected(int index) {
    final avatars = _filteredAvatars;
    if (index >= 0 && index < avatars.length) {
      setState(() => _focusedIndex = index);
      widget.onAvatarSelected(avatars[index]);
    }
  }

  void _requestFocus(int index) {
    if (index >= 0 && index < _avatarFocusNodes.length) {
      if (_gridScroll.hasClients && _rowExtent > 0) {
        final position = _gridScroll.position;
        final rowTop = (index ~/ _columns) * _rowExtent;
        final rowBottom = rowTop + _rowExtent;
        var offset = position.pixels;
        if (rowTop < offset) {
          offset = rowTop;
        } else if (rowBottom > offset + position.viewportDimension) {
          offset = rowBottom - position.viewportDimension;
        }
        _gridScroll.jumpTo(offset.clamp(0.0, position.maxScrollExtent));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && index < _avatarFocusNodes.length) {
          _avatarFocusNodes[index].requestFocus();
        }
      });
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int columns) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final totalItems = _filteredAvatars.length;
    if (totalItems == 0) return KeyEventResult.ignored;

    int newIndex = _focusedIndex;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final right = event.logicalKey == LogicalKeyboardKey.arrowRight;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      newIndex = (_focusedIndex + (right != rtl ? 1 : -1))
          .clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newIndex = (_focusedIndex + columns).clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newIndex = (_focusedIndex - columns).clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      if (event is KeyDownEvent) _onAvatarSelected(_focusedIndex);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }

    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _requestFocus(newIndex);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatars = _filteredAvatars;
    final categories = widget.avatars.map((avatar) => avatar.category).toSet();

    return Container(
      color: const Color(0xFF0D0E12),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── En-tête : Nom/Pseudo + Barre de texte ───
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profileName?.isNotEmpty == true
                          ? widget.profileName!
                          : 'Choisir un Avatar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.avatars.length} avatars disponibles',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in <String?>[null, ...categories])
                  CategoryChipTV(
                    label: category ?? 'Tous',
                    isSelected: category == _selectedCategory,
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category;
                        final selected = _filteredAvatars.indexWhere(
                          (avatar) => avatar.id == widget.selectedAvatarId,
                        );
                        _focusedIndex = selected < 0 ? 0 : selected;
                      });
                      if (_gridScroll.hasClients) _gridScroll.jumpTo(0);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = ResponsiveGrid.calculateCrossAxisCount(
                constraints.maxWidth,
                minItemWidth: ResponsiveGrid.compactGridConfig.minItemWidth,
                spacing: ResponsiveGrid.compactGridConfig.crossAxisSpacing,
                minColumns: ResponsiveGrid.compactGridConfig.minColumns,
                maxColumns: ResponsiveGrid.compactGridConfig.maxColumns,
              );
              final spacing = ResponsiveGrid.compactGridConfig.crossAxisSpacing;
              final width = (constraints.maxWidth - spacing * (columns - 1)) /
                  columns;
              final aspectRatio = ResponsiveGrid.calculateAspectRatio(
                width,
                isWide: constraints.maxWidth >= ResponsiveGrid.tabletBreakpoint,
              );
              _columns = columns;
              _rowExtent = width / aspectRatio +
                  ResponsiveGrid.compactGridConfig.mainAxisSpacing;
              return Focus(
                onKeyEvent: (node, event) => _handleKeyEvent(event, columns),
                child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: avatars.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun avatar disponible',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : GridView.builder(
                        key: const ValueKey('avatar_grid'),
                        controller: _gridScroll,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing:
                              ResponsiveGrid.compactGridConfig.mainAxisSpacing,
                        ),
                        itemCount: avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = avatars[index];
                          final isCurrent = avatar.id == widget.selectedAvatarId;

                          return AvatarTileLarge(
                            avatar: avatar,
                            isCurrentSelection: isCurrent,
                            focusNode: _avatarFocusNodes[index],
                            autofocus: index == _focusedIndex && isCurrent,
                            onFocusChange: (focused) {
                              if (focused) _focusedIndex = index;
                            },
                            onSelect: () => _onAvatarSelected(index),
                          );
                        },
                      ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// --- BOUTON DE CATÉGORIE ADAPTÉ D-PAD ---
class CategoryChipTV extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const CategoryChipTV({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<CategoryChipTV> createState() => _CategoryChipTVState();
}

class _CategoryChipTVState extends State<CategoryChipTV> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? const Color(0xFF8B5CF6)
                  : (_isFocused ? Colors.white24 : const Color(0xFF1C1F26)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFocused ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: (widget.isSelected || _isFocused)
                    ? Colors.white
                    : Colors.white54,
                fontWeight:
                    widget.isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --- CARTE AVATAR AGRANDIE AVEC EFFET FOCUS D-PAD ---
class AvatarTileLarge extends StatefulWidget {
  const AvatarTileLarge({
    super.key,
    required this.avatar,
    required this.isCurrentSelection,
    required this.onSelect,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
  });

  final AvatarItem avatar;
  final bool isCurrentSelection;
  final VoidCallback onSelect;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<AvatarTileLarge> createState() => _AvatarTileLargeState();
}

class _AvatarTileLargeState extends State<AvatarTileLarge> {
  bool _isFocused = false;

  Widget _buildIconFallback(AvatarItem avatar) {
    final base = avatar.color ?? const Color(0xFF00CFE8);
    final iconColor = avatar.color != null ? Colors.white : Colors.white24;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.white, 0.25)!],
        ),
      ),
      child: Icon(
        avatar.icon ?? Icons.person_pin_rounded,
        size: 76,
        color: iconColor,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Activation: Enter/Space/OK
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onSelect();
      return KeyEventResult.handled;
    }
    // Navigation: let parent handle arrow keys
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        widget.onFocusChange?.call(hasFocus);
      },
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _isFocused ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: const Color(0xFF16181E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF00E5FF)
                    : (widget.isCurrentSelection
                        ? Colors.amber
                        : Colors.white10),
                width: _isFocused ? 4 : (widget.isCurrentSelection ? 2 : 1),
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.95),
                        blurRadius: 38,
                        spreadRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: widget.avatar.assetPath.isNotEmpty
                        ? Image.asset(
                            widget.avatar.assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildIconFallback(widget.avatar),
                          )
                        : _buildIconFallback(widget.avatar),
                  ),
                ),
                Text(
                  widget.avatar.name,
                  style: TextStyle(
                    color: _isFocused ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}