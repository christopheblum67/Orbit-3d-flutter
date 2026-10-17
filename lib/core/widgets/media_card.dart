import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

/// Carte média (film / série) : poster, badge d'âge, note, méta.
class MediaCard extends ConsumerWidget {
  const MediaCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.rating,
    required this.ageLabel,
    required this.fallbackIcon,
    this.favoriteOverlay,
    this.onTap,
    this.onLongPress,
    this.isNew = false,
    this.topBadge,
    this.matchPercent, // % d'affinité matchmaking (affiché sur la ligne méta)
    this.voteCount, // Nombre de votes (ex: TMDB) - affiché sur la ligne méta
    this.overview, // Synopsis (aperçu 2 lignes sous la méta, si fourni)
    this.posterFit = BoxFit.cover,
    this.posterPadding = EdgeInsets.zero,
  });

  /// Ajustement de l'image dans la tuile.
  ///
  /// `cover` convient aux affiches (films, séries) qui doivent remplir la
  /// tuile. Les logos de chaînes sont des wordmarks très larges : en `cover`
  /// dans une tuile haute, ils sont zoomés jusqu'à deborder puis rognés, ce
  /// qui les rend « trop gros ». Passer `contain` avec une petite marge laisse
  /// le logo entier visible à sa taille naturelle.
  final BoxFit posterFit;

  /// Marge intérieure autour de l'image (utile avec [posterFit] = contain).
  final EdgeInsets posterPadding;

  final String title;
  final String posterUrl;
  final int year;
  final String genre;
  final double rating;
  final String? ageLabel;
  final IconData fallbackIcon;

  /// Widget superposé en bas-droit du poster (ex. cœur favori permanent).
  final Widget? favoriteOverlay;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Affiche le badge "NOUVEAU" si true.
  final bool isNew;

  /// Widget superposé en haut-gauche du poster (ex. numéro de rang FlixPatrol).
  final Widget? topBadge;

  /// % d'affinité matchmaking (ex: 87%). Si fourni, affiché sur la ligne méta.
  final int? matchPercent;

  /// Nombre de votes (ex. TMDB). Affiché formaté sur la ligne méta.
  final int? voteCount;

  /// Synopsis / aperçu affiché en 2 lignes sous la ligne méta.
  final String? overview;

  String? get _voteCountLabel {
    final votes = voteCount ?? 0;
    if (votes <= 0) return null;
    if (votes >= 1000) {
      final k = votes / 1000;
      return k >= 100
          ? '${k.round()}K votes'
          : '${k.toStringAsFixed(1)}K votes';
    }
    return '$votes votes';
  }

  /// Description sémantique complète de la carte pour les lecteurs d'écran
  /// (TalkBack / VoiceOver). Regroupe titre, année, genre, note, âge, statut
  /// et synopsis afin qu'une carte soit annoncée en une seule lecture.
  String get _accessibilityLabel {
    final parts = <String>[
      title,
      if (year > 0) '$year',
      if (genre.isNotEmpty) genre,
      if (rating > 0) 'Note ${rating.toStringAsFixed(1)} sur 10',
      if (ageLabel != null && ageLabel!.isNotEmpty) 'Classé $ageLabel',
      if (isNew) 'Nouveau',
      if (matchPercent != null) 'Compatibilité $matchPercent%',
      if (_voteCountLabel != null) _voteCountLabel!,
      if (overview != null && overview!.isNotEmpty) overview!,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // `select` sur le seul champ consommé, et non sur l'objet entier.
    //
    // `MediaCard` est instancié des milliers de fois dans les grilles. Sans
    // `select`, *toute* écriture dans `preferencesProvider` — thème, langue,
    // notifications, contrôle parental… — invalidait le provider et
    // reconstruisait toutes les tuiles visibles de toutes les grilles, pour
    // un unique `double`.
    final fontScale = ref.watch(preferencesProvider.select((p) => p.fontScale));
    // Largeur de decode en pixels physiques, arrondie à un multiple de 64 pour
    // éviter un redimensionnement par contrainte non entière.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final posterDecodeWidth = (200 * dpr / 64).ceil() * 64;
    final metaStyle = TextStyle(
      color: scheme.onSurfaceVariant,
      fontSize: 12 * fontScale,
    );
    return Semantics(
      container: true,
      label: _accessibilityLabel,
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: posterPadding,
                    child: posterUrl.isNotEmpty
                        ? OrbitCachedImage(
                            imageUrl: posterUrl,
                            fit: posterFit,
                            // Décodage mémoire borné à la taille réelle.
                            //
                            // `maxWidthDiskCache: 800` ne limitait que le
                            // FICHIER disque ; sans `memCacheWidth`, Flutter
                            // décodait l'affiche en pleine résolution. Une
                            // image TMDB `original` (2000×3000) = ~24 Mo en
                            // cache mémoire, et quelques dizaines de tuiles
                            // visibles suffisaient à dépasser les centaines
                            // de Mo sur TV.
                            memCacheWidth: posterDecodeWidth,
                            placeholder: (context, url) => _PosterFallback(
                              scheme: scheme,
                              icon: fallbackIcon,
                            ),
                            errorWidget: (context, url, error) =>
                                _PosterFallback(
                              scheme: scheme,
                              icon: fallbackIcon,
                            ),
                          )
                        : _PosterFallback(scheme: scheme, icon: fallbackIcon),
                  ),
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
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ),
                  if (isNew)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NOUVEAU',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                    ),
                  if (topBadge != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: topBadge!,
                    ),
                  if (matchPercent != null && matchPercent! > 0)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _AffinityBadge(percent: matchPercent!),
                    ),
                  if (rating > 0)
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (favoriteOverlay != null)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: favoriteOverlay!,
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
                  if (year > 0 || genre.isNotEmpty || _voteCountLabel != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (year > 0) Text('$year', style: metaStyle),
                        if (genre.isNotEmpty) Text(genre, style: metaStyle),
                        if (_voteCountLabel != null)
                          Text(_voteCountLabel!, style: metaStyle),
                      ],
                    ),
                  if (overview != null && overview!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      overview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11 * fontScale,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge d'affinité personnelle (matchmaking), ancré en bas à gauche du poster.
///
/// L'ancrage haut-droit porte déjà la note et le haut-gauche l'âge / NOUVEAU /
/// rang ; le bas-droit est réservé au cœur favori. Le bas-gauche était donc le
/// seul emplacement libre, et il laisse la ligne de méta (année, genre) nette.
class _AffinityBadge extends StatelessWidget {
  const _AffinityBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 11, color: scheme.primary),
          const SizedBox(width: 3),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
