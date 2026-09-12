import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/models/cast.dart';

/// Carrousel horizontal d'acteurs réutilisable (Film + Série guests)
/// Style Allociné : photo circulaire + nom + rôle, navigation D-pad TV
class CastCarousel extends StatelessWidget {
  final List<Actor> actors;
  final String? title;
  final bool showCharacter;
  final int? maxVisible;
  final Function(Actor)? onActorTap;
  final double itemWidth;
  final double imageSize;

  const CastCarousel({
    super.key,
    required this.actors,
    this.title,
    this.showCharacter = true,
    this.maxVisible,
    this.onActorTap,
    this.itemWidth = 130,
    this.imageSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (actors.isEmpty) return const SizedBox.shrink();

    final visibleActors =
        maxVisible != null ? actors.take(maxVisible!).toList() : actors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  title!,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${actors.length} acteur${actors.length > 1 ? 's' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: imageSize + (showCharacter ? 56 : 36),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: visibleActors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final actor = visibleActors[index];
              return _ActorCard(
                actor: actor,
                showCharacter: showCharacter,
                imageSize: imageSize,
                itemWidth: itemWidth,
                onTap: () => onActorTap?.call(actor),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActorCard extends StatelessWidget {
  final Actor actor;
  final bool showCharacter;
  final double imageSize;
  final double itemWidth;
  final VoidCallback? onTap;

  const _ActorCard({
    required this.actor,
    required this.showCharacter,
    required this.imageSize,
    required this.itemWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocus(
      onActivate: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: itemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo circulaire avec Hero pour transitions
              Hero(
                tag: 'actor-${actor.id}-${actor.source.name}',
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: actor.hasProfile
                        ? CachedNetworkImage(
                            imageUrl: actor.profileUrl,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Nom de l'acteur
              Text(
                actor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showCharacter && actor.character.isNotEmpty) ...[
                const SizedBox(height: 2),
                // Rôle/personnage
                Text(
                  actor.character,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Badge source (debug/dev)
              if (actor.isGuestStar) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Invité',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(
        Icons.person_outline,
        size: 40,
        color: Colors.white54,
      ),
    );
  }
}

/// Variante compacte pour les petits espaces (ex: header série)
class CompactCastCarousel extends StatelessWidget {
  final List<Actor> actors;
  final String? title;
  final int maxVisible;
  final Function(Actor)? onActorTap;

  const CompactCastCarousel({
    super.key,
    required this.actors,
    this.title,
    this.maxVisible = 8,
    this.onActorTap,
  });

  @override
  Widget build(BuildContext context) {
    if (actors.isEmpty) return const SizedBox.shrink();

    final visibleActors = actors.take(maxVisible).toList();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              title!,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: visibleActors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final actor = visibleActors[index];
              return _CompactActorCard(
                actor: actor,
                onTap: () => onActorTap?.call(actor),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactActorCard extends StatelessWidget {
  final Actor actor;
  final VoidCallback? onTap;

  const _CompactActorCard({required this.actor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TvFocus(
      onActivate: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'actor-${actor.id}-compact',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: ClipOval(
                    child: actor.hasProfile
                        ? CachedNetworkImage(
                            imageUrl: actor.profileUrl,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5,),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.person_outline,
                                  size: 24, color: Colors.white54,),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.person_outline,
                                size: 24, color: Colors.white54,),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                actor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (actor.character.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  actor.character,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
