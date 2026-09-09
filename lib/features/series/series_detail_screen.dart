import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/widgets/cast_carousel.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

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
    // D'abord charger la série de base depuis Xtream
    final baseSeriesAsync = ref.watch(seriesInfoProvider(seriesId));

    return baseSeriesAsync.when(
      data: (baseSeries) {
        // Puis enrichir avec les métadonnées externes
        final detailAsync = ref.watch(seriesDetailProvider(baseSeries));

        return Scaffold(
          appBar: AppBar(
            title: Text(title.isEmpty ? baseSeries.title : title),
            actions: [
              FavoriteToggle(
                entry: FavoriteEntry(
                  type: ContentType.series,
                  id: baseSeries.id,
                  title: baseSeries.title,
                  posterUrl: baseSeries.coverUrl,
                  subtitle: baseSeries.genre,
                  streamUrl: baseSeries.episodes.isNotEmpty
                      ? baseSeries.episodes.first.streamUrl
                      : '',
                ),
              ),
            ],
          ),
          body: detailAsync.when(
            data: (detail) => _SeriesDetailContent(
              detail: detail,
              baseSeries: baseSeries,
            ),
            loading: () =>
                const LoadingState(message: 'Enrichissement des métadonnées…'),
            error: (err, _) => ErrorState(
              icon: Icons.tv,
              title: 'Détail indisponible',
              message: userFriendlyError(err),
              onRetry: () => ref.invalidate(seriesDetailProvider(baseSeries)),
            ),
          ),
        );
      },
      loading: () => const LoadingState(message: 'Chargement de la série…'),
      error: (err, _) => ErrorState(
        icon: Icons.tv,
        title: 'Série introuvable',
        message: userFriendlyError(err),
        onRetry: () => ref.invalidate(seriesInfoProvider(seriesId)),
      ),
    );
  }
}

class _SeriesDetailContent extends ConsumerWidget {
  const _SeriesDetailContent({
    required this.detail,
    required this.baseSeries,
  });

  final SeriesDetail detail;
  final Series baseSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final watched = ref.watch(watchedEpisodesProvider).values;
    final episodesBySeason = <int, List<Episode>>{};
    for (final episode in baseSeries.episodes) {
      episodesBySeason.putIfAbsent(episode.season, () => []).add(episode);
    }
    final seasons = episodesBySeason.keys.toList()..sort();

    final header = SliverToBoxAdapter(
      child: _SeriesHeader(series: detail, baseSeries: baseSeries),
    );

    if (seasons.isEmpty) {
      return CustomScrollView(
        slivers: [
          header,
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.video_library_outlined,
              title: 'Aucun épisode',
              message: 'Cette série ne propose pas encore d\'épisodes.',
            ),
          ),
        ],
      );
    }

    if (seasons.length == 1) {
      final season = seasons.first;
      return CustomScrollView(
        slivers: [
          header,
          ..._seasonSlivers(
            context,
            season: season,
            episodes: episodesBySeason[season]!,
            total: episodesBySeason[season]!.length,
            seen: _seenCountFor(watched, season),
            compact: false,
          ),
        ],
      );
    }

    // Plusieurs saisons : TabBar horizontale pour alléger la liste, une seule
    // saison visible à la fois (au lieu de les empiler verticalement).
    return DefaultTabController(
      length: seasons.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: scheme.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final season in seasons) Tab(text: 'Saison $season'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final season in seasons)
                  CustomScrollView(
                    slivers: [
                      header,
                      ..._seasonSlivers(
                        context,
                        season: season,
                        episodes: episodesBySeason[season]!,
                        total: episodesBySeason[season]!.length,
                        seen: _seenCountFor(watched, season),
                        compact: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _seenCountFor(Iterable<WatchedEpisodeEntry> watched, int season) {
    return watched
        .where((e) => e.seriesId == baseSeries.id && e.season == season)
        .length;
  }

  /// Slivers d'une saison :
  ///  - `compact` (mode onglets) : simple rappel « X/Y vus », pas de gros
  ///    titre de section redondant avec l'onglet ;
  ///  - sinon : en-tête de section classique « Saison N ».
  List<Widget> _seasonSlivers(
    BuildContext context, {
    required int season,
    required List<Episode> episodes,
    required int total,
    required int seen,
    required bool compact,
  }) {
    final guests = detail.getGuestStarsForSeason(season);
    return [
      if (compact)
        seen > 0
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Text(
                    '$seen/$total vus',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: _watchedGreen),
                  ),
                ),
              )
            : const SliverToBoxAdapter(child: SizedBox.shrink())
      else
        SliverToBoxAdapter(
          child: SectionHeader(
            icon: Icons.play_circle_outline,
            title: 'Saison $season',
            subtitle: _seasonSubtitle(total: total, seen: seen),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        sliver: SliverList.builder(
          itemCount: episodes.length,
          itemBuilder: (context, index) => _EpisodeTile(
            series: baseSeries,
            episode: episodes[index],
          ),
        ),
      ),
      //Invités spéciaux pour cette saison
      if (guests.isNotEmpty)
        SliverToBoxAdapter(
          child: CastCarousel(
            actors: guests,
            title: 'Invités spéciaux - Saison $season',
            maxVisible: 10,
            showCharacter: true,
            itemWidth: 120,
            imageSize: 80,
          ),
        ),
    ];
  }

  String _seasonSubtitle({required int total, required int seen}) {
    if (seen == 0) return '$total épisodes';
    return '$seen/$total vus';
  }
}

class _SeriesHeader extends ConsumerWidget {
  const _SeriesHeader({required this.series, required this.baseSeries});

  final SeriesDetail series;
  final Series baseSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final metaParts = <String>[
      if (series.year > 0) '${series.year}',
      if (series.runtime > 0) '${series.runtime} min/ép',
      if (series.genre.isNotEmpty) series.genre,
      if (series.rating > 0) '★ ${series.rating.toStringAsFixed(1)}',
    ];
    final meta = metaParts.join('  •  ');

    final extraMetaParts = <String>[
      if (series.status.isNotEmpty) series.status,
      if (series.networks.isNotEmpty) 'Réseau: ${series.networks.join(', ')}',
      if (series.firstAirDate.isNotEmpty)
        '1ʳᵉ diffusion: ${_formatDate(series.firstAirDate)}',
      if (series.numberOfSeasons > 0) '${series.numberOfSeasons} saisons',
      if (series.numberOfEpisodes > 0) '${series.numberOfEpisodes} épisodes',
    ];
    final extraMeta = extraMetaParts.join('  •  ');

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
                child: GestureDetector(
                  // Pression longue sur la série = « retour en arrière » :
                  // propose de tout retirer des déjà vus.
                  onLongPress: () => _confirmResetSeries(context, ref),
                  child: SizedBox(
                    width: 112,
                    height: 168,
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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (extraMeta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        extraMeta,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (series.pegiLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          series.pegiLabel!,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    // Badge source de données
                    if (series.dataSource != 'xtream') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getSourceColor(series.dataSource)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _getSourceColor(series.dataSource)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              series.aiGenerated
                                  ? Icons.psychology_outlined
                                  : Icons.data_usage_outlined,
                              size: 12,
                              color: _getSourceColor(series.dataSource),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              series.aiGenerated
                                  ? 'Données générées par IA'
                                  : 'Données ${series.dataSource.toUpperCase()}',
                              style: textTheme.labelSmall?.copyWith(
                                color: _getSourceColor(series.dataSource),
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
          if (series.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              series.description,
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          // Cast principal (compact)
          if (series.cast.isNotEmpty) ...[
            const SizedBox(height: 12),
            CompactCastCarousel(
              actors: series.cast,
              title: 'Distribution principale',
              maxVisible: 8,
            ),
          ],
        ],
      ),
    );
  }

  void _confirmResetSeries(BuildContext context, WidgetRef ref) {
    final seen = ref.read(watchedEpisodesProvider.notifier).countForSeries(baseSeries.id);
    if (seen == 0) return;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout retirer des déjà vus ?'),
        content: Text(
          'Les $seen épisodes vus de « ${baseSeries.title} » seront marqués '
          'comme non vus pour ce profil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tout retirer'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      await ref
          .read(watchedEpisodesProvider.notifier)
          .clearForSeries(baseSeries.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '« ${baseSeries.title} » retiré des déjà vus.',
            ),
            duration: const Duration(milliseconds: 1200),
          ),
        );
    });
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'tvmaze':
        return Colors.blue;
      case 'tmdb':
        return Colors.green;
      case 'omdb':
        return Colors.orange;
      case 'ai':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

const Color _watchedGreen = Color(0xFF66BB6A);

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({required this.series, required this.episode});

  final Series series;
  final Episode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final number = 'S${episode.season.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';
    var episodeTitle = episode.title.trim();
    if (episodeTitle.startsWith(series.title)) {
      episodeTitle = episodeTitle
          .substring(series.title.length)
          .replaceFirst(RegExp(r'^\s*[-–—]\s*'), '');
    }
    final hasNumber = RegExp(r'^S\d+E\d+([\s\-–—]|$)').hasMatch(episodeTitle);
    final label = episodeTitle.isNotEmpty
        ? (hasNumber ? episodeTitle : '$number — $episodeTitle')
        : 'Épisode $number';
    final canPlay = episode.streamUrl.isNotEmpty;
    final profileId = ref.read(currentProfileProvider)?.id ?? '';
    final watched = ref.watch(watchedEpisodesProvider).containsKey(
          WatchedEpisodeEntry.keyFor(
            profileId: profileId,
            seriesId: series.id,
            season: episode.season,
            episodeNumber: episode.episodeNumber,
            episodeId: episode.id,
          ),
        );
    void onOpen() {
      if (!canPlay) return;
      context.push('/episode/detail', extra: (series, episode));
    }

    // Pression longue = « retour en arrière » : retire l'épisode des déjà vus
    // (après confirmation). Si l'épisode n'est pas « vu », rien à retirer.
    void onLongPress() {
      if (!watched) return;
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Retirer des déjà vus ?'),
          content: Text(
            '« $label » sera marqué comme non vu pour ce profil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retirer'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) {
          ref
              .read(watchedEpisodesProvider.notifier)
              .toggle(series, episode);
        }
      });
    }

    return TvFocus(
      onActivate: onOpen,
      onLongPress: onLongPress,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: watched ? scheme.onSurfaceVariant : null,
                      ),
                ),
              ),
              if (watched) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _watchedGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Vu',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _watchedGreen,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                tooltip: watched
                    ? 'Marquer comme non vu'
                    : 'Marquer comme vu',
                onPressed: () => ref
                    .read(watchedEpisodesProvider.notifier)
                    .toggle(series, episode),
                icon: Icon(
                  watched ? Icons.check_circle : Icons.check_circle_outline,
                  color: watched ? _watchedGreen : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
