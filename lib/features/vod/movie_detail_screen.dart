import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/cast_carousel.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/crew_section.dart';

/// Page intermédiaire d'un film VOD : toutes les infos enrichies (TMDB/TVmaze/OMDB/IA)
/// + bouton « Démarrer » et bouton « Reprendre » (si progression existe).
class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(movie));

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title.isEmpty ? 'Détail' : movie.title),
        actions: [
          FavoriteToggle(
            entry: FavoriteEntry(
              type: ContentType.vod,
              id: movie.id,
              title: movie.title,
              posterUrl: movie.posterUrl,
              subtitle: movie.year > 0 ? '${movie.year}' : '',
              streamUrl: movie.streamUrl,
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => _MovieDetailContent(detail: detail, movie: movie),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur de chargement: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(movieDetailProvider(movie)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieDetailContent extends ConsumerWidget {
  const _MovieDetailContent({required this.detail, required this.movie});

  final MovieDetail detail;
  final Movie movie;

  String get _progressId => 'movie-${movie.id}';

  void _openPlayer(BuildContext context, {int? positionMs}) {
    final rating = detail.rating > 0 ? detail.rating : movie.rating;
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: movie.streamUrl,
        title: movie.title,
        progressId: _progressId,
        initialPositionMs: positionMs,
        contentType: PlaybackContentType.vod,
        posterUrl:
            detail.posterUrl.isNotEmpty ? detail.posterUrl : movie.posterUrl,
        subtitle: movie.year > 0 ? '${movie.year}' : '',
        rating: rating > 0 ? rating : null,
        genre: detail.genre.isNotEmpty
            ? detail.genre
            : (movie.genre.isNotEmpty ? movie.genre : null),
        year: detail.year > 0 ? detail.year : movie.year,
        favorite: FavoriteEntry(
          type: ContentType.vod,
          id: movie.id,
          title: movie.title,
          posterUrl: movie.posterUrl,
          subtitle: movie.year > 0 ? '${movie.year}' : '',
          streamUrl: movie.streamUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playbackProgressProvider(_progressId));
    final hasProgress = progress?.hasProgress ?? false;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // TMDB Similar / Recommendations
    final similarAsync = detail.tmdbId > 0
        ? ref.watch(tmdbSimilarMoviesProvider(detail.tmdbId))
        : null;
    final recommendationsAsync = detail.tmdbId > 0
        ? ref.watch(tmdbMovieRecommendationsProvider(detail.tmdbId))
        : null;

    final metaParts = <String>[
      if (detail.year > 0) '${detail.year}',
      if (detail.runtime > 0) '${detail.runtime} min',
      if (detail.genre.isNotEmpty) detail.genre,
      if (detail.rating > 0) '★ ${detail.rating.toStringAsFixed(1)}',
      if (detail.voteCount > 0) '${detail.voteCount} votes',
    ];
    final meta = metaParts.join('  •  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Backdrop (si dispo)
          if (detail.backdropUrl != null && detail.backdropUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: detail.backdropUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: scheme.primaryContainer,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Header: Poster + Titre + Métadonnées
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 140,
                  height: 210,
                  child: detail.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: detail.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Icon(
                            Icons.movie_outlined,
                            color: scheme.primary,
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.movie_outlined,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(Icons.movie_outlined, color: scheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (detail.tagline != null &&
                        detail.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail.tagline!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meta,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (detail.director.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              detail.director,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Pays / Langues
                    if (detail.originCountry.isNotEmpty ||
                        detail.spokenLanguages.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.public_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                if (detail.originCountry.isNotEmpty)
                                  detail.originCountry.join(', '),
                                if (detail.spokenLanguages.isNotEmpty)
                                  detail.spokenLanguages.join(', '),
                              ].join('  •  '),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Budget/Revenue si disponibles
                    if (detail.budget > 0 ||
                        detail.revenue > 0 ||
                        detail.productionCompanies.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                if (detail.budget > 0)
                                  'Budget: ${_formatCurrency(detail.budget)}',
                                if (detail.revenue > 0)
                                  'Recettes: ${_formatCurrency(detail.revenue)}',
                                if (detail.productionCompanies.isNotEmpty)
                                  'Production: ${_companiesSummary(detail.productionCompanies)}',
                              ].join('  •  '),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (detail.pegiLabel != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          detail.pegiLabel!,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (detail.pegiLabel == null &&
                        detail.certification != null &&
                        detail.certification!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          detail.certification!,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    // Badge source de données
                    if (detail.dataSource != 'xtream') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getSourceColor(detail.dataSource)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getSourceColor(detail.dataSource)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              detail.aiGenerated
                                  ? Icons.psychology_outlined
                                  : Icons.data_usage_outlined,
                              size: 12,
                              color: _getSourceColor(detail.dataSource),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              detail.aiGenerated
                                  ? 'Données générées par IA'
                                  : 'Données ${detail.dataSource.toUpperCase()}',
                              style: textTheme.labelSmall?.copyWith(
                                color: _getSourceColor(detail.dataSource),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Boutons Lecture
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openPlayer(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Démarrer'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasProgress
                      ? () =>
                          _openPlayer(context, positionMs: progress!.positionMs)
                      : null,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reprendre'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          // Bande-annonce
          if (detail.trailerUrl != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _launchTrailer(context, detail.trailerUrl!),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Bande-annonce'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
          if (hasProgress && progress != null && progress.durationMs > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 8),
            Text(
              'Repris à ${_formatDuration(progress.positionMs)}',
              style:
                  textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          // Synopsis
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Synopsis',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              detail.description,
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ],
          // Mots-clés
          if (detail.keywords.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Mots-clés',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detail.keywords
                  .take(15)
                  .map(
                    (kw) => Chip(
                      label: Text(kw),
                      labelStyle: textTheme.labelSmall,
                      backgroundColor: scheme.surfaceContainerHighest,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
          // Distribution (Cast) - Carrousel horizontal
          if (detail.cast.isNotEmpty) ...[
            const SizedBox(height: 24),
            CastCarousel(
              actors: detail.cast,
              title: 'Distribution',
              maxVisible: 12,
              onActorTap: (actor) {
                context.push('/actor/detail', extra: actor);
              },
            ),
          ],
          // Équipe technique (Crew)
          if (detail.crew.isNotEmpty) ...[
            const SizedBox(height: 24),
            CrewSection(crew: detail.crew),
          ],
          // Films similaires TMDB
          if (similarAsync != null) ...[
            const SizedBox(height: 24),
            _SimilarSection(
              title: 'Films similaires',
              async: similarAsync,
              onTap: (entry) => _openSimilarMovie(context, ref, entry),
            ),
          ],
          // Recommandations TMDB
          if (recommendationsAsync != null) ...[
            const SizedBox(height: 24),
            _SimilarSection(
              title: 'Recommandations',
              async: recommendationsAsync,
              onTap: (entry) => _openSimilarMovie(context, ref, entry),
            ),
          ],
        ],
      ),
    );
  }

  void _openSimilarMovie(
      BuildContext context, WidgetRef ref, TmdbRankEntry entry,) {
    final normalized = entry.title.trim().toLowerCase();
    final movies = ref.read(moviesProvider).value ?? const <Movie>[];
    Movie? match;
    for (final m in movies) {
      if (m.title.trim().toLowerCase() == normalized) {
        match = m;
        break;
      }
    }
    if (match != null) {
      context.push('/vod/detail', extra: match);
      return;
    }
    // Pas dans le catalogue : on affiche une fiche d'info TMDB légère.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (_) => _SimilarEntrySheet(entry: entry),
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'tmdb':
        return Colors.green;
      case 'tvmaze':
        return Colors.blue;
      case 'omdb':
        return Colors.orange;
      case 'ai':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$$amount';
  }

  static String _companiesSummary(List<String> companies) {
    if (companies.length <= 3) return companies.join(', ');
    return '${companies.take(3).join(', ')} et ${companies.length - 3} autres';
  }

  static String _formatDuration(int ms) {
    final total = Duration(milliseconds: ms);
    final h = total.inHours;
    final m = total.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}';
    return '$m min';
  }

  Future<void> _launchTrailer(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible d\'ouvrir la bande-annonce'),),
        );
      }
    }
  }
}

/// Section réutilisable pour afficher films similaires / recommandations TMDB
class _SimilarSection extends ConsumerWidget {
  const _SimilarSection({
    required this.title,
    required this.async,
    required this.onTap,
  });

  final String title;
  final AsyncValue<List<TmdbRankEntry>> async;
  final void Function(TmdbRankEntry) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final shown = list.take(12).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: shown.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entry = shown[index];
                  return _SimilarCard(entry: entry, onTap: () => onTap(entry));
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({required this.entry, required this.onTap});

  final TmdbRankEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: entry.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: entry.posterUrl,
                      width: 130,
                      height: 195,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(scheme),
                      errorWidget: (_, __, ___) => _placeholder(scheme),
                    )
                  : _placeholder(scheme),
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                  entry.rating > 0 ? entry.rating.toStringAsFixed(1) : '—',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (entry.year > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${entry.year}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
        width: 130,
        height: 195,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.movie_outlined, color: scheme.primary, size: 44),
      );
}

/// Bottom sheet d'infos TMDB pour une entrée similaire/recommandation
/// non trouvée dans le catalogue local.
class _SimilarEntrySheet extends StatelessWidget {
  const _SimilarEntrySheet({required this.entry});

  final TmdbRankEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (entry.posterUrl.isNotEmpty) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: entry.posterUrl,
                      width: 180,
                      height: 270,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                entry.title,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (entry.year > 0) Text('${entry.year}'),
                  if (entry.year > 0 && entry.genreIds.isNotEmpty)
                    const Text(' • '),
                  if (entry.genreIds.isNotEmpty)
                    Text(
                      entry.genreIds.take(3).map(_genreName).join(', '),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    entry.rating > 0 ? entry.rating.toStringAsFixed(1) : '—',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 16),
                  if (entry.voteCount > 0)
                    Text(
                      '${entry.voteCount} votes',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
              if (entry.overview.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Synopsis',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),),
                const SizedBox(height: 8),
                Text(
                  entry.overview,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Non disponible dans le catalogue',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _genreName(int id) {
    const map = {
      28: 'Action',
      12: 'Aventure',
      16: 'Animation',
      35: 'Comédie',
      80: 'Crime',
      99: 'Documentaire',
      18: 'Drame',
      10751: 'Familial',
      14: 'Fantastique',
      36: 'Histoire',
      27: 'Horreur',
      10402: 'Musique',
      9648: 'Mystère',
      10749: 'Romance',
      878: 'Science-Fiction',
      10770: 'Téléfilm',
      53: 'Thriller',
      10752: 'Guerre',
      37: 'Western',
    };
    return map[id] ?? 'Genre $id';
  }
}
