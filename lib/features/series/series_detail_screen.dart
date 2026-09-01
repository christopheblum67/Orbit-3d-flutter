import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/series.dart';
import '../../providers/providers.dart';
import '../../core/widgets/tv_focus.dart';
import '../../core/widgets/widgets.dart';
import '../../services/user_friendly_error.dart';

class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({
    super.key,
    required this.seriesId,
    this.title = '',
  });

  final String seriesId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(seriesInfoProvider(seriesId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: infoAsync.when(
        data: (series) {
          final episodesBySeason = <int, List<Episode>>{};
          for (final episode in series.episodes) {
            episodesBySeason
                .putIfAbsent(episode.season, () => [])
                .add(episode);
          }
          final seasons = episodesBySeason.keys.toList()..sort();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SeriesHeader(series: series),
              ),
              if (seasons.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.video_library_outlined,
                    title: 'Aucun épisode',
                    message: 'Cette série ne propose pas encore d\'épisodes.',
                  ),
                )
              else
                for (final season in seasons) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      icon: Icons.play_circle_outline,
                      title: 'Saison $season',
                      subtitle: '${episodesBySeason[season]!.length} épisodes',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverList.builder(
                      itemCount: episodesBySeason[season]!.length,
                      itemBuilder: (context, index) {
                        final episode = episodesBySeason[season]![index];
                        return _EpisodeTile(
                          seriesTitle: series.title,
                          episode: episode,
                        );
                      },
                    ),
                  ),
                ],
            ],
          );
        },
        loading: () => const LoadingState(message: 'Chargement des épisodes…'),
        error: (err, _) => ErrorState(
          icon: Icons.tv,
          title: 'Détail indisponible',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(seriesInfoProvider(seriesId)),
        ),
      ),
    );
  }
}

class _SeriesHeader extends StatelessWidget {
  const _SeriesHeader({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      if (series.year > 0) '${series.year}',
      if (series.genre.isNotEmpty) series.genre,
      if (series.rating > 0) '★ ${series.rating.toStringAsFixed(1)}',
    ].join('  •  ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 112,
                  height: 168,
                  child: series.coverUrl.isNotEmpty
                      ? Image.network(
                          series.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.tv,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(Icons.tv, color: scheme.primary),
                ),
              ),
              const SizedBox(width: 14),
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
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (series.pegiLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          series.pegiLabel!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          if (series.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              series.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.seriesTitle, required this.episode});

  final String seriesTitle;
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final number = 'S${episode.season.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';
    var episodeTitle = episode.title.trim();
    if (episodeTitle.startsWith(seriesTitle)) {
      episodeTitle = episodeTitle
          .substring(seriesTitle.length)
          .replaceFirst(RegExp(r'^\s*[-–—]\s*'), '');
    }
    final hasNumber = RegExp(r'^S\d+E\d+([\s\-–—]|$)').hasMatch(episodeTitle);
    final label = episodeTitle.isNotEmpty
        ? (hasNumber ? episodeTitle : '$number — $episodeTitle')
        : 'Épisode $number';
    final canPlay = episode.streamUrl.isNotEmpty;
    void onOpen() {
      if (!canPlay) return;
      context.push(
        '/player?url=${Uri.encodeComponent(episode.streamUrl)}'
        '&title=${Uri.encodeComponent(label)}',
      );
    }

    return TvFocus(
      onActivate: onOpen,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          onTap: canPlay ? onOpen : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
          children: [
            Icon(
              canPlay ? Icons.play_circle_outline : Icons.play_circle,
              color: canPlay ? scheme.primary : scheme.outline,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (canPlay)
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
        ),
      ),
    );
  }
}