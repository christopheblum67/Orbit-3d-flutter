import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';

/// Carte média (film / série) : poster, badge d'âge, note, méta.
class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.rating,
    required this.ageLabel,
    required this.fallbackIcon,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String posterUrl;
  final int year;
  final String genre;
  final double rating;
  final String? ageLabel;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _PosterFallback(scheme: scheme, icon: fallbackIcon),
                        errorWidget: (context, url, error) =>
                            _PosterFallback(scheme: scheme, icon: fallbackIcon),
                      )
                    : _PosterFallback(scheme: scheme, icon: fallbackIcon),
                if (ageLabel != null && ageLabel!.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ageLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (year > 0 || genre.isNotEmpty)
                  Text(
                    [
                      if (year > 0) '$year',
                      if (genre.isNotEmpty) genre,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
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

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.scheme, required this.icon});

  final ColorScheme scheme;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, size: 44, color: scheme.primary),
    );
  }
}
