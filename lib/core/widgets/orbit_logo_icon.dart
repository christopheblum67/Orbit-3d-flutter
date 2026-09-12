import 'package:flutter/material.dart';

/// Logo « Orbit 3D » affiché en interne (splash, menus, drawer).
///
/// Affiche `assets/icons/logo_icon.png` avec des coins arrondis et une lueur
/// cyan (`0xFF00F2FE`) lorsqu'[glow] est activé.
class OrbitLogoIcon extends StatelessWidget {
  const OrbitLogoIcon({super.key, this.size = 48, this.glow = true});

  /// Taille (largeur/hauteur) du logo.
  final double size;

  /// Active la lueur cyan autour du logo.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/icons/logo_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}