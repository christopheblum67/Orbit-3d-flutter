import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

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

/// Thème d'avatar : groupe d'avatars partageant une palette de couleurs
class AvatarTheme {
  const AvatarTheme({
    required this.id,
    required this.name,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.avatarIds,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final List<String> avatarIds;

  /// Crée un dégradé pour l'aperçu du thème
  LinearGradient get previewGradient => LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Couleur principale du thème (pour bordures, focus, etc.)
  Color get primaryColor => startColor;
}

/// Thèmes d'avatars prédéfinis (groupés par palette de couleurs)
const List<AvatarTheme> avatarThemes = [
  AvatarTheme(
    id: 'cyan',
    name: 'Cyan',
    icon: Icons.water_drop,
    startColor: Color(0xFF00B8D4),
    endColor: Color(0xFF00E5FF),
    avatarIds: ['face', 'music', 'account'],
  ),
  AvatarTheme(
    id: 'violet',
    name: 'Violet',
    icon: Icons.auto_awesome,
    startColor: Color(0xFF7C4DFF),
    endColor: Color(0xFFB388FF),
    avatarIds: ['film', 'smart_toy', 'movie_filter'],
  ),
  AvatarTheme(
    id: 'rose',
    name: 'Rose',
    icon: Icons.favorite,
    startColor: Color(0xFFFF4D8D),
    endColor: Color(0xFFFF6FA8),
    avatarIds: ['heart'],
  ),
  AvatarTheme(
    id: 'orange',
    name: 'Orange',
    icon: Icons.local_fire_department,
    startColor: Color(0xFFFFAB00),
    endColor: Color(0xFFFF9A56),
    avatarIds: ['rocket', 'sport'],
  ),
  AvatarTheme(
    id: 'green',
    name: 'Vert',
    icon: Icons.eco,
    startColor: Color(0xFF00E676),
    endColor: Color(0xFF34D399),
    avatarIds: ['esports', 'psychology'],
  ),
];

/// Sélecteur d'avatar par thème (TV-friendly)
///
/// Affiche une barre horizontale de thèmes en haut, chacun avec :
/// - Icône + nom du thème
/// - Aperçu du dégradé du thème
/// - Navigation D-pad (flèches G/D pour changer de thème)
/// En dessous : grille des avatars du thème sélectionné
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
  int _selectedThemeIndex = 0;
  late FocusNode _themeFocusNode;
  late List<FocusNode> _avatarFocusNodes;

  @override
  void initState() {
    super.initState();
    _themeFocusNode = FocusNode();

    // Trouve le thème correspondant à l'avatar actuellement sélectionné
    final selectedAvatar = widget.avatars.firstWhere(
      (a) => a.id == widget.selectedAvatarId,
      orElse: () => widget.avatars.first,
    );
    final themeIndex = avatarThemes.indexWhere(
      (t) => t.avatarIds.contains(selectedAvatar.id),
    );
    _selectedThemeIndex = themeIndex >= 0 ? themeIndex : 0;

    _avatarFocusNodes = List.generate(
      widget.avatars.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    _themeFocusNode.dispose();
    for (final node in _avatarFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  AvatarTheme get _currentTheme => avatarThemes[_selectedThemeIndex];

  List<AvatarItem> get _currentThemeAvatars {
    return widget.avatars
        .where((a) => _currentTheme.avatarIds.contains(a.id))
        .toList();
  }

  void _onThemeChanged(int index) {
    setState(() => _selectedThemeIndex = index);
    // Reset focus to first avatar of new theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _avatarFocusNodes.isNotEmpty) {
        _avatarFocusNodes[0].requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentThemeAvatars = _currentThemeAvatars;

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
          const SizedBox(height: 20),

          // Barre de thèmes horizontale (TV-friendly)
          TvFocus(
            focusNode: _themeFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (_selectedThemeIndex < avatarThemes.length - 1) {
                  _onThemeChanged(_selectedThemeIndex + 1);
                }
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (_selectedThemeIndex > 0) {
                  _onThemeChanged(_selectedThemeIndex - 1);
                }
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                // Descendre vers la grille d'avatars
                if (_avatarFocusNodes.isNotEmpty) {
                  _avatarFocusNodes[0].requestFocus();
                }
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème de couleur',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatarThemes.length,
                    itemBuilder: (context, index) {
                      final theme = avatarThemes[index];
                      final isSelected = index == _selectedThemeIndex;
                      return _ThemeChipTV(
                        theme: theme,
                        isSelected: isSelected,
                        autofocus: index == 0,
                        onPressed: () => _onThemeChanged(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Aperçu du thème sélectionné (dégradé + infos)
          _ThemePreviewCard(theme: _currentTheme),
          const SizedBox(height: 24),

          // Grille des Avatars du thème sélectionné
          Expanded(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: currentThemeAvatars.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun avatar dans ce thème',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: currentThemeAvatars.length,
                      itemBuilder: (context, index) {
                        final avatar = currentThemeAvatars[index];
                        final globalIndex = widget.avatars
                            .indexWhere((a) => a.id == avatar.id);
                        final isCurrent = avatar.id == widget.selectedAvatarId;

                        return AvatarTileLarge(
                          avatar: avatar,
                          isCurrentSelection: isCurrent,
                          focusNode: _avatarFocusNodes[globalIndex],
                          autofocus: index == 0 && isCurrent,
                          onSelect: () => widget.onAvatarSelected(avatar),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'aperçu du thème sélectionné (dégradé + nom + icône)
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({required this.theme});

  final AvatarTheme theme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: theme.previewGradient,
        boxShadow: [
          BoxShadow(
            color: theme.startColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              theme.icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème ${theme.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${theme.avatarIds.length} avatars disponibles',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce de thème focusable TV (horizontal)
class _ThemeChipTV extends StatefulWidget {
  const _ThemeChipTV({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onPressed,
    this.autofocus = false,
  });

  final AvatarTheme theme;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_ThemeChipTV> createState() => _ThemeChipTVState();
}

class _ThemeChipTVState extends State<_ThemeChipTV> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isSelected || _isFocused
                  ? theme.previewGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? Colors.white
                    : (widget.isSelected
                        ? theme.primaryColor
                        : Colors.transparent),
                width: _isFocused ? 3 : (widget.isSelected ? 2 : 1),
              ),
              boxShadow: (_isFocused || widget.isSelected)
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  theme.icon,
                  size: 28,
                  color: widget.isSelected || _isFocused
                      ? Colors.white
                      : theme.primaryColor,
                ),
                const SizedBox(height: 6),
                Text(
                  theme.name,
                  style: TextStyle(
                    color: widget.isSelected || _isFocused
                        ? Colors.white
                        : Colors.white70,
                    fontWeight:
                        widget.isSelected || _isFocused
                            ? FontWeight.bold
                            : FontWeight.normal,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
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
  });

  final AvatarItem avatar;
  final bool isCurrentSelection;
  final VoidCallback onSelect;
  final FocusNode? focusNode;
  final bool autofocus;

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
    final scheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
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