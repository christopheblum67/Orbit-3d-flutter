# EPG â€” grille : 8. annexe â€” orbite 3D

> **Partie 2/5**

> Fiche gÃ©nÃ©rÃ©e depuis le code source â€” extraction fidÃ¨le, commentaires compris. Chaque bloc est limitÃ© Ã  200 lignes pour rester copiable sans saturer le presse-papier.


> ⚠️ **ARCHIVÉ** : les 5 widgets 3D documentés ici (constellation_dual_screen, avorites_orbit_system_3d, gravity_focus_node, 
ebula_search_space, orbit_planet_node) ont été **supprimés** par le commit 4458d6d (« chore(cleanup): code mort, identite visuelle cyan/navy, jetifier desactive »). Ce document est conservé pour référence historique uniquement.
Sources : `lib/features/epg/widgets/constellation_dual_screen.dart`, `lib/features/epg/widgets/favorites_orbit_system_3d.dart`, `lib/features/epg/widgets/gravity_focus_node.dart`, `lib/features/epg/widgets/nebula_search_space.dart`, `lib/features/epg/widgets/orbit_planet_node.dart`

### 8.2 `favorites_orbit_system_3d`

`lib/features/epg/widgets/favorites_orbit_system_3d.dart` Â· lignes 1â€“315

#### `lib/features/epg/widgets/favorites_orbit_system_3d.dart` Â· lignes 1â€“200 Â· partie 1/2

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/epg_models.dart';

/// SystÃ¨me solaire des favoris : Soleil (Top Favori) + planÃ¨tes orbitantes
class FavoritesOrbitSystem3D extends StatefulWidget {
  final List<FavoriteChannelNode> favorites;
  final VoidCallback onZoomOutToCategories;
  final Function(FavoriteChannelNode) onSelectChannel;

  const FavoritesOrbitSystem3D({
    super.key,
    required this.favorites,
    required this.onZoomOutToCategories,
    required this.onSelectChannel,
  });

  @override
  State<FavoritesOrbitSystem3D> createState() => _FavoritesOrbitSystem3DState();
}

class _FavoritesOrbitSystem3DState extends State<FavoritesOrbitSystem3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (widget.favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'Aucun favori enregistrÃ©',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez longuement sur une chaÃ®ne pour l\'ajouter',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final topFavorite = widget.favorites.firstWhere(
      (f) => f.isTopFavorite,
      orElse: () => widget.favorites.first,
    );
    final orbitFavorites =
        widget.favorites.where((f) => f.id != topFavorite.id).toList();

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(
              () => _focusedIndex = (_focusedIndex + 1) % orbitFavorites.length,
            );
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(
              () => _focusedIndex =
                  (_focusedIndex - 1 + orbitFavorites.length) %
                      orbitFavorites.length,
            );
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onZoomOutToCategories();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            if (orbitFavorites.isNotEmpty) {
              widget.onSelectChannel(orbitFavorites[_focusedIndex]);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onSelectChannel(topFavorite);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        color: const Color(0xFF0B0C10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbite principale
            Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

            // Soleil (Top Favori) au centre
            GestureDetector(
              onTap: () => widget.onSelectChannel(topFavorite),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16181E),
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        topFavorite.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Text(
                      'Top Favori',
                      style: TextStyle(color: Colors.amber, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),

            // PlanÃ¨tes orbitantes
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                if (orbitFavorites.isEmpty) return const SizedBox.shrink();
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(orbitFavorites.length, (index) {
                    final item = orbitFavorites[index];
                    final isFocused = index == _focusedIndex;
                    final angleStep = (2 * math.pi) / orbitFavorites.length;
                    final currentAngle = (angleStep * index) +
                        (_rotationController.value * 2 * math.pi);

                    const radius = 190.0;
                    final x = radius * math.cos(currentAngle);
                    final y = radius * math.sin(currentAngle);

```

#### `lib/features/epg/widgets/favorites_orbit_system_3d.dart` Â· lignes 201â€“315 Â· partie 2/2

```dart
                    return Transform.translate(
                      offset: Offset(x, y),
                      child: AnimatedScale(
                        scale: isFocused ? 1.35 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1C1F26),
                            border: Border.all(
                              color: isFocused
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white24,
                              width: isFocused ? 3 : 1,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color:
                                    isFocused ? Colors.white : Colors.white70,
                                fontSize: 10,
                                fontWeight: isFocused
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            // Indicateur de navigation
            Positioned(
              bottom: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.select,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.keyboard_arrow_left,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Naviguer',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.categories,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```



