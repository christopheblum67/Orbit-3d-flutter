import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';

/// Badge du type de profil (Enfant / Expert / Adulte).
class ProfileTypeBadge extends StatelessWidget {
  const ProfileTypeBadge({super.key, required this.profileType});

  final ProfileType profileType;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (profileType) {
      ProfileType.child => (
          'Enfant',
          Icons.child_care,
          const Color(0xFF00CFE8)
        ),
      ProfileType.expert => (
          'Expert',
          Icons.psychology_rounded,
          const Color(0xFF8A72FF)
        ),
      ProfileType.adult => (
          'Adulte',
          Icons.sentiment_satisfied_alt,
          const Color(0xFFFF4D8D),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}