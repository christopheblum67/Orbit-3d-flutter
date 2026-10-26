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
  int _focusedIndex = 0;

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
    for (final node in _avatarFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onAvatarSelected(int index) {
    if (index >= 0 && index < widget.avatars.length) {
      setState(() => _focusedIndex = index);
      widget.onAvatarSelected(widget.avatars[index]);
    }
  }

  void _requestFocus(int index) {
    if (index >= 0 && index < _avatarFocusNodes.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _avatarFocusNodes[index].requestFocus();
        }
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    const columns = 6;
    final totalItems = widget.avatars.length;

    int newIndex = _focusedIndex;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newIndex = (_focusedIndex + 1).clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newIndex = (_focusedIndex - 1).clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newIndex = (_focusedIndex + columns).clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newIndex = (_focusedIndex - columns).clamp(0, totalItems - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      _onAvatarSelected(_focusedIndex);
      return KeyEventResult.handled;
    }

    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _requestFocus(newIndex);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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

          // ─── Grille unique de TOUS les avatars ───
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) => _handleKeyEvent(node, event),
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: widget.avatars.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun avatar disponible',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ResponsiveGridView.compactBuilder(
                        key: const ValueKey('avatar_grid'),
                        itemCount: widget.avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = widget.avatars[index];
                          final isCurrent = avatar.id == widget.selectedAvatarId;

                          return AvatarTileLarge(
                            avatar: avatar,
                            isCurrentSelection: isCurrent,
                            focusNode: _avatarFocusNodes[index],
                            autofocus: index == _focusedIndex && isCurrent,
                            onSelect: () => _onAvatarSelected(index),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte avatar agrandie avec effet focus D-PAD
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