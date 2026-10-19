# EPG â€” grille : 8. annexe â€” orbite 3D

> **Partie 3/5**

> Fiche gÃ©nÃ©rÃ©e depuis le code source â€” extraction fidÃ¨le, commentaires compris. Chaque bloc est limitÃ© Ã  200 lignes pour rester copiable sans saturer le presse-papier.


> ⚠️ **ARCHIVÉ** : les 5 widgets 3D documentés ici (constellation_dual_screen, avorites_orbit_system_3d, gravity_focus_node, 
ebula_search_space, orbit_planet_node) ont été **supprimés** par le commit 4458d6d (« chore(cleanup): code mort, identite visuelle cyan/navy, jetifier desactive »). Ce document est conservé pour référence historique uniquement.
Sources : `lib/features/epg/widgets/constellation_dual_screen.dart`, `lib/features/epg/widgets/favorites_orbit_system_3d.dart`, `lib/features/epg/widgets/gravity_focus_node.dart`, `lib/features/epg/widgets/nebula_search_space.dart`, `lib/features/epg/widgets/orbit_planet_node.dart`

### 8.3 `gravity_focus_node`

`lib/features/epg/widgets/gravity_focus_node.dart` Â· lignes 1â€“139

#### `lib/features/epg/widgets/gravity_focus_node.dart` Â· lignes 1â€“139 Â· partie 1/1

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// Focus gravitationnel : grossissement + aura lumineuse au focus tÃ©lÃ©commande
class GravityFocusNode extends StatelessWidget {
  final bool isFocused;
  final Widget child;
  final double scaleFactor;
  final Duration duration;
  final Color auraColor;
  final double auraBlurRadius;
  final double auraSpreadRadius;

  const GravityFocusNode({
    super.key,
    required this.isFocused,
    required this.child,
    this.scaleFactor = 1.25,
    this.duration = const Duration(milliseconds: 200),
    this.auraColor = const Color(0xFF8B5CF6),
    this.auraBlurRadius = 25,
    this.auraSpreadRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      transform: isFocused
          ? (Matrix4.identity()
            ..scaleByVector3(vm.Vector3(scaleFactor, scaleFactor, scaleFactor)))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isFocused)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: auraColor.withValues(alpha: 0.6),
                    blurRadius: auraBlurRadius,
                    spreadRadius: auraSpreadRadius,
                  ),
                  BoxShadow(
                    color: auraColor.withValues(alpha: 0.3),
                    blurRadius: auraBlurRadius * 1.5,
                    spreadRadius: auraSpreadRadius * 2,
                  ),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Wrapper pour Focus + GravityFocusNode combinÃ©s
class FocusableGravityNode extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final GravityFocusNodeConfig config;

  const FocusableGravityNode({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.config = const GravityFocusNodeConfig(),
  });

  @override
  State<FocusableGravityNode> createState() => _FocusableGravityNodeState();
}

class _FocusableGravityNodeState extends State<FocusableGravityNode> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: GravityFocusNode(
          isFocused: _isFocused,
          scaleFactor: widget.config.scaleFactor,
          duration: widget.config.duration,
          auraColor: widget.config.auraColor,
          auraBlurRadius: widget.config.auraBlurRadius,
          auraSpreadRadius: widget.config.auraSpreadRadius,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Configuration pour GravityFocusNode
class GravityFocusNodeConfig {
  final double scaleFactor;
  final Duration duration;
  final Color auraColor;
  final double auraBlurRadius;
  final double auraSpreadRadius;

  const GravityFocusNodeConfig({
    this.scaleFactor = 1.25,
    this.duration = const Duration(milliseconds: 200),
    this.auraColor = const Color(0xFF8B5CF6),
    this.auraBlurRadius = 25,
    this.auraSpreadRadius = 8,
  });
}
```



