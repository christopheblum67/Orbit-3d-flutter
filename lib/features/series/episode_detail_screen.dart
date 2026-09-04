import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

/// Page intermédiaire d'un épisode de série : infos + boutons « Démarrer »
/// et « Reprendre » (si une progression de lecture existe pour l'épisode).
class EpisodeDetailScreen extends ConsumerWidget {
  const EpisodeDetailScreen({
    super.key,
    required this.series,
    required this.episode,
  });

  final Series series;
  final Episode episode;

  String get _progressId => 'episode-${episode.id}';

  String get _label {
    final number = 'S${episode.season.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';
    var title = episode.title.trim();
    if (title.startsWith(series.title)) {
      title = title
          .substring(series.title.length)
          .replaceFirst(RegExp(r'^\s*[-–—]\s*'), '');
    }
    if (title.isEmpty) return 'Épisode $number';
    return '$number — $title';
  }

  void _openPlayer(BuildContext context, WidgetRef ref, {int? positionMs}) {
    if (episode.streamUrl.isEmpty) return;
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: episode.streamUrl,
        title: _label,
        progressId: _progressId,
        initialPositionMs: positionMs,
        contentType: PlaybackContentType.series,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playbackProgressProvider(_progressId));
    final hasProgress = progress?.hasProgress ?? false;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Épisode')),
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
                    child: series.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: series.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Icon(Icons.tv, color: scheme.primary),
                            errorWidget: (_, __, ___) =>
                                Icon(Icons.tv, color: scheme.primary),
                          )
                        : Icon(Icons.tv, color: scheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (series.year > 0) '${series.year}',
                          if (series.genre.isNotEmpty) series.genre,
                          if (series.rating > 0)
                            '★ ${series.rating.toStringAsFixed(1)}',
                        ].join('  •  '),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
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
                    onPressed: () => _openPlayer(context, ref),
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
                    onPressed: hasProgress && episode.streamUrl.isNotEmpty
                        ? () => _openPlayer(context, ref,
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
            if (hasProgress &&
                progress != null &&
                progress.durationMs > 0) ...[
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
            if (series.description.isNotEmpty) ...[
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
                series.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
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
