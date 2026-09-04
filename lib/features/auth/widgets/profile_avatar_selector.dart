import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class ProfileAvatarSelector extends StatefulWidget {
  final List<AvatarItem> avatars;
  final String selectedAvatarId;
  final Function(AvatarItem) onAvatarSelected;

  const ProfileAvatarSelector({
    super.key,
    required this.avatars,
    required this.selectedAvatarId,
    required this.onAvatarSelected,
  });

  @override
  State<ProfileAvatarSelector> createState() => _ProfileAvatarSelectorState();
}

class _ProfileAvatarSelectorState extends State<ProfileAvatarSelector> {
  String _selectedCategory = 'Tous';
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    final cats = widget.avatars.map((e) => e.category).toSet().toList();
    _categories = ['Tous', ...cats];
  }

  List<AvatarItem> get _filteredAvatars {
    if (_selectedCategory == 'Tous') return widget.avatars;
    return widget.avatars.where((a) => a.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0E12),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          const Text(
            'Choisir un Avatar de Profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Barre de Filtres / Catégories (Adaptée D-Pad)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return CategoryChipTV(
                  label: cat,
                  isSelected: isSelected,
                  onPressed: () => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Grille des Avatars — 6 colonnes max, icônes agrandies
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, // 6 profils max → 6 colonnes
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredAvatars.length,
              itemBuilder: (context, index) {
                final avatar = _filteredAvatars[index];
                final isCurrent = avatar.id == widget.selectedAvatarId;

                return AvatarTileLarge(
                  avatar: avatar,
                  isCurrentSelection: isCurrent,
                  onSelect: () => widget.onAvatarSelected(avatar),
                );
              },
            ),
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
                  event.logicalKey == LogicalKeyboardKey.enter)) {
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
                color: (widget.isSelected || _isFocused) ? Colors.white : Colors.white54,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
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
  final AvatarItem avatar;
  final bool isCurrentSelection;
  final VoidCallback onSelect;

  const AvatarTileLarge({
    super.key,
    required this.avatar,
    required this.isCurrentSelection,
    required this.onSelect,
  });

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

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _isFocused ? 1.12 : 1.0, // Légère mise à l'échelle au focus
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: const Color(0xFF16181E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF8B5CF6)
                    : (widget.isCurrentSelection ? Colors.amber : Colors.white10),
                width: _isFocused ? 3 : (widget.isCurrentSelection ? 2 : 1),
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                        offset: const Offset(0, 8),
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
                    padding: const EdgeInsets.all(20.0), // Plus d'espace pour l'image
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