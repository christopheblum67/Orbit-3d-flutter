import 'package:flutter/material.dart';

/// Badge compteur « X / max » (nombre de profils).
class ProfilesCountBadge extends StatelessWidget {
  const ProfilesCountBadge({super.key, required this.current, required this.max});

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            '$current / $max',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}