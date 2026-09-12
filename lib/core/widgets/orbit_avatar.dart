import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';

/// Anneau orbital tournant autour de l'avatar (sélecteurs de profils).
class OrbitAvatar extends StatefulWidget {
  const OrbitAvatar({super.key, required this.profile, required this.enlarged});

  final UserProfile profile;
  final bool enlarged;

  @override
  State<OrbitAvatar> createState() => _OrbitAvatarState();
}

class _OrbitAvatarState extends State<OrbitAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const base = 108.0;
    final diameter = widget.enlarged ? base + 10 : base;
    final disc = diameter - 8;
    final avatarSize = disc - 12;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _spin,
          builder: (context, _) => Transform.rotate(
            angle: _spin.value * 2 * math.pi,
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    scheme.tertiary,
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: disc,
          height: disc,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerLow,
          ),
          alignment: Alignment.center,
          child: ProfileAvatar(
            profile: widget.profile,
            size: avatarSize,
          ),
        ),
      ],
    );
  }
}