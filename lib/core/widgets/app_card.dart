import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';

/// Carte arrondie moderne, réutilisable sur tous les écrans.
///
/// Par défaut : fond noir charbon (0xFF12141C) pour harmoniser
/// toutes les cartes (chaînes, films, séries).
/// Titre en texte blanc doux (white70) pour lisibilité.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
    this.focusable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius? borderRadius;

  /// Faux quand la carte contient elle-même des boutons : un nœud de focus
  /// parent dont le rectangle englobe ses enfants les rend inatteignables au
  /// D-pad (le parcours directionnel ne les voit pas « au-delà » du parent).
  final bool focusable;

  // Couleur de fond par défaut : rouge sombre désaturé. Assez sombre pour ne
  // pas éblouir ni concurrencer les logos, assez rouge pour être perceptible.
  static const Color _defaultCardColor = Color(0xFF33181C);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppConstants.radiusLg);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: color ?? _defaultCardColor,
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          canRequestFocus: focusable,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
