import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_models.dart';

/// Nœud planétaire individuel pour l'orbite 3D
class OrbitPlanetNode extends StatelessWidget {
  final OrbitChannelPlanet planet;
  final double angleRadians;
  final double baseRadius;
  final bool isFocused;
  final VoidCallback onTap;

  const OrbitPlanetNode({
    Key? key,
    required this.planet,
    required this.angleRadians,
    required this.baseRadius,
    this.isFocused = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = planet.getOrbitRadius(baseRadius);
    final x = radius * math.cos(angleRadians);
    final y = radius * math.sin(angleRadians);

    return Transform.translate(
      offset: Offset(x, y),
      child: AnimatedScale(
        scale: isFocused ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Anneau de progression du programme actuel
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: planet.currentProgramProgress.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFocused ? Colors.amber : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  // Avatar de la chaîne
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF16181E),
                    backgroundImage: planet.logoUrl.isNotEmpty
                        ? NetworkImage(planet.logoUrl)
                        : null,
                    child: planet.logoUrl.isEmpty
                        ? Text(
                            planet.name.substring(0, math.min(3, planet.name.length)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Label avec nom + programme actuel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isFocused ? Colors.amber : Colors.white12,
                    width: isFocused ? 2 : 1,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                      planet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      planet.currentProgramTitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}