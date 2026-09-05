import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/cast_grid.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/crew_section.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Page intermédiaire d'un film VOD : toutes les infos disponibles + un
/// bouton « Démarrer » et un bouton « Reprendre » (si une progression existe).
class MovieDetailScreen extends ConsumerStatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  late Movie _movie;
  bool _loadingDetail = false;
  bool _loadingCredits = false;
  MovieCredits? _credits;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _loadDetail();
    _loadCredits();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final api = ref.read(apiServiceProvider);
      final enriched = await api.fetchMovieDetail(_movie);
      if (mounted) setState(() => _movie = enriched);
    } catch (_) {
      // Garder les données de la liste en cas d'échec du détail.
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _loadCredits() async {
    if (_movie.id.isEmpty) return;
    setState(() => _loadingCredits = true);
    try {
      final api = ref.read(apiServiceProvider);
      final credits = await api.fetchMovieCredits(_movie.id);
      if (mounted) setState(() => _credits = credits);
    } catch (_) {
      // Ignorer les erreurs de crédits
    } finally {
      if (mounted) setState(() => _loadingCredits = false);
    }
  }

  String get _progressId => 'movie-${_movie.id}';

  void _openPlayer(BuildContext context, {int? positionMs}) {
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: _movie.streamUrl,
        title: _movie.title,
        progressId: _progressId,
        initialPositionMs: positionMs,
        contentType: PlaybackContentType.vod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = _movie;
    final progress = ref.watch(playbackProgressProvider(_progressId));
    final hasProgress = progress?.hasProgress ?? false;
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (movie.year > 0) '${movie.year}',
      if (movie.genre.isNotEmpty) movie.genre,
      if (movie.rating > 0) '★ ${movie.rating.toStringAsFixed(1)}',
    ].join('  •  ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
        actions: [
          if (_loadingDetail || _loadingCredits)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 140,
                    height: 210,
                    child: movie.posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(Icons.movie_outlined,
                                color: scheme.primary,),
                            errorWidget: (_, __, ___) =>
                                Icon(Icons.movie_outlined,
                                    color: scheme.primary,),
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
                        movie.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          meta,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (movie.director.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          movie.director,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (movie.pegiLabel != null) ...[
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
                            movie.pegiLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                        ? () => _openPlayer(context,
                            positionMs: progress!.positionMs,)
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
            if (hasProgress && progress != null && progress.durationMs > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress.fraction),
              const SizedBox(height: 8),
              Text(
                'Repris à ${_formatDuration(progress.positionMs)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (movie.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Synopsis',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                movie.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
            // Distribution (Cast)
            if (_credits != null && _credits!.cast.isNotEmpty) ...[
              const SizedBox(height: 24),
              CastGrid(
                cast: _credits!.cast,
                maxVisible: 15,
                onActorTap: (actor) {
                  // TODO: Naviguer vers la page de l'acteur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${actor.name} - ${actor.character}')),
                  );
                },
              ),
            ],
            // Équipe technique (Crew)
            if (_credits != null && _credits!.crew.isNotEmpty) ...[
              const SizedBox(height: 24),
              CrewSection(crew: _credits!.crew),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int ms) {
    final total = Duration(milliseconds: ms);
    final h = total.inHours;
    final m = total.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}';
    return '$m min';
  }
}
