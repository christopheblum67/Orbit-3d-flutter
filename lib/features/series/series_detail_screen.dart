import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/edge_locked_focus_group.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_scroll_to_top.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/widgets/cast_carousel.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:orbit_3d_flutter/services/stream_audio_tracks.dart';
import 'package:orbit_3d_flutter/services/stream_subtitle_tracks.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/features/widgets/translated_synopsis_view.dart';

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
    final l = AppLocalizations.of(context);
    // Garde-fou : si l'identifiant est vide (navigation via `extra` au lieu
    // de query parameters), on affiche un message clair au lieu de laisser
    // l'API planter sur un ID vide.
    if (seriesId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: context.canPop()
              ? TvFocus(
                  onActivate: () => context.pop(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: l.profileBack,
                    onPressed: () => context.pop(),
                  ),
                )
              : null,
          title: Text(l.detailUnavailable),
        ),
        body: ErrorState(
          icon: Icons.tv,
          title: l.detailUnavailable,
          message: l.seriesMissingId,
          onRetry: () => context.pop(),
        ),
      );
    }

    // D'abord charger la série de base depuis Xtream
    final baseSeriesAsync = ref.watch(seriesInfoProvider(seriesId));

    return baseSeriesAsync.when(
      data: (baseSeries) {
        // Puis enrichir avec les métadonnées externes
        final detailAsync = ref.watch(seriesDetailProvider(baseSeries));

        return Scaffold(
          appBar: AppBar(
            leading: context.canPop()
                ? TvFocus(
                    onActivate: () => context.pop(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: l.profileBack,
                      onPressed: () => context.pop(),
                    ),
                  )
                : null,
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
            data: (detail) => TvScrollToTop(
              child: _SeriesDetailContent(
                detail: detail,
                baseSeries: baseSeries,
              ),
            ),
            loading: () => LoadingState(message: l.seriesEnriching),
            error: (err, _) => ErrorState(
              icon: Icons.tv,
              title: l.detailUnavailable,
              message: userFriendlyError(err),
              onRetry: () => ref.invalidate(seriesDetailProvider(baseSeries)),
            ),
          ),
        );
      },
      loading: () => LoadingState(message: l.seriesLoading),
      error: (err, _) => ErrorState(
        icon: Icons.tv,
        title: l.seriesNotFound,
        message: userFriendlyError(err),
        onRetry: () => ref.invalidate(seriesInfoProvider(seriesId)),
      ),
    );
  }
}

class _SeriesDetailContent extends ConsumerStatefulWidget {
  const _SeriesDetailContent({
    required this.detail,
    required this.baseSeries,
  });

  final SeriesDetail detail;
  final Series baseSeries;

  @override
  ConsumerState<_SeriesDetailContent> createState() =>
      _SeriesDetailContentState();
}

class _SeriesDetailContentState extends ConsumerState<_SeriesDetailContent> {
  int? _selectedSeason;

  SeriesDetail get detail => widget.detail;
  Series get baseSeries => widget.baseSeries;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final episodesBySeason = <int, List<Episode>>{};
    for (final episode in baseSeries.episodes) {
      episodesBySeason.putIfAbsent(episode.season, () => []).add(episode);
    }
    final seasons = episodesBySeason.keys.toList()..sort();
    final seenBySeason = <int, int>{
      if (seasons.length > 1)
        for (final season in seasons)
          season: _seenCountFor(ref, episodesBySeason[season]!),
    };

    final header = SliverToBoxAdapter(
      child: _SeriesHeader(series: detail, baseSeries: baseSeries, l: l),
    );

    // Section « Reprendre » : épisodes avec une progression en cours
    // (0 < % regardé < 80 %), affichée au-dessus des saisons.
    final resumeEpisodes = _resumeEpisodesFor(ref);
    final season = seasons.contains(_selectedSeason)
        ? _selectedSeason
        : seasons.firstOrNull;
    final guests =
        season == null ? null : detail.getGuestStarsForSeason(season);
    final theme = Theme.of(context);
    final seasonFontSize = (theme.tabBarTheme.labelStyle?.fontSize ??
            theme.textTheme.titleSmall?.fontSize ??
            14) *
        1.4;
    final seasonTabHeight = math.max(
      46.0 * 1.4,
      MediaQuery.textScalerOf(context).scale(seasonFontSize) * 1.3 + 16,
    );
    final seasonLabelStyle = TextStyle(
      fontSize: seasonFontSize,
      fontWeight: FontWeight.w700,
    );
    Tab seasonTab(int number) {
      final episodes = episodesBySeason[number]!;
      final seen = seenBySeason[number]!;
      final complete = episodes.isNotEmpty && seen == episodes.length;
      final label = l.seasonNumber(number);
      return Tab(
        height: seasonTabHeight,
        child: Semantics(
          label: complete
              ? '$label, ${l.episodesWatchedCount(seen, episodes.length)}'
              : label,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (complete) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle,
                    key: ValueKey('season-complete-$number'),
                    color: _watchedGreen,
                    size: seasonFontSize,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final scrollView = CustomScrollView(
      cacheExtent: 1500,
      slivers: [
        header,
        if (resumeEpisodes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  icon: Icons.replay_rounded,
                  title: l.resumeAction,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l.episodesInProgress(resumeEpisodes.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                _episodeActionsHint(context),
              ],
            ),
          ),
          _episodeCarousel(resumeEpisodes, resume: true),
        ],
        if (season == null)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.video_library_outlined,
              title: l.noEpisodes,
              message: l.seriesNoEpisodesHint,
            ),
          )
        else ...[
          if (seasons.length > 1)
            SliverToBoxAdapter(
              child: Material(
                color: scheme.surface,
                child: EdgeLockedFocusGroup(
                  axis: Axis.horizontal,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: seasonLabelStyle,
                    unselectedLabelStyle: seasonLabelStyle,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 16 * 1.4),
                    onTap: (index) =>
                        setState(() => _selectedSeason = seasons[index]),
                    tabs: [
                      for (final number in seasons) seasonTab(number),
                    ],
                  ),
                ),
              ),
            ),
          ..._seasonSlivers(
            context,
            ref: ref,
            season: season,
            episodes: episodesBySeason[season]!,
            total: episodesBySeason[season]!.length,
            compact: seasons.length > 1,
            l: l,
          ),
        ],
        SliverToBoxAdapter(
          child: _SeriesTrackPreferences(seriesId: baseSeries.id),
        ),
        if (guests != null && guests.isNotEmpty)
          SliverToBoxAdapter(
            child: CastCarousel(
              actors: guests,
              title: l.specialGuestsSeason(season!),
              maxVisible: 10,
              showCharacter: true,
              itemWidth: 120,
              imageSize: 80,
              onActorTap: (actor) =>
                  context.push('/actor/detail', extra: actor),
            ),
          ),
      ],
    );
    if (seasons.length < 2) return scrollView;
    return DefaultTabController(
      key: ValueKey(seasons.join(',')),
      length: seasons.length,
      initialIndex: seasons.indexOf(season!),
      child: scrollView,
    );
  }

  /// Épisodes « à reprendre » : une progression de lecture existe et est
  /// inférieure au seuil de 80 % (au-delà, l'épisode est considéré « vu »).
  List<Episode> _resumeEpisodesFor(WidgetRef ref) {
    final result = <Episode>[];
    final progressService = ref.watch(playbackProgressServiceProvider);
    final profileId = ref.watch(currentProfileProvider)?.id ?? '';
    for (final episode in baseSeries.episodes) {
      final progress = progressService.get(
        PlaybackProgressService.idForProfile(
          profileId,
          'episode-${episode.id}',
        ),
      );
      if (progress != null &&
          progress.hasProgress &&
          progress.fraction > 0 &&
          progress.fraction < _autoWatchedThreshold) {
        result.add(episode);
      }
    }
    return result;
  }

  int _seenCountFor(WidgetRef ref, List<Episode> episodes) {
    final profile = ref.watch(currentProfileProvider);
    if (episodes.isEmpty) return 0;
    final progressService = ref.watch(playbackProgressServiceProvider);
    final watchedEpisodes = ref.watch(watchedEpisodesProvider);
    var seen = 0;
    for (final episode in episodes) {
      final isVu = watchedEpisodes.containsKey(
        WatchedEpisodeEntry.keyFor(
          profileId: profile?.id ?? '',
          seriesId: baseSeries.id,
          season: episode.season,
          episodeNumber: episode.episodeNumber,
          episodeId: episode.id,
        ),
      );
      if (isVu) {
        seen++;
        continue;
      }
      final progress = progressService.get(
        PlaybackProgressService.idForProfile(
          profile?.id ?? '',
          'episode-${episode.id}',
        ),
      );
      if (progress != null && progress.fraction >= _autoWatchedThreshold) {
        seen++;
      }
    }
    return seen;
  }

  /// Slivers d'une saison :
  ///  - `compact` (mode onglets) : simple rappel « X/Y vus », pas de gros
  ///    titre de section redondant avec l'onglet ;
  ///  - sinon : en-tête de section classique « Saison N ».
  List<Widget> _seasonSlivers(
    BuildContext context, {
    required WidgetRef ref,
    required int season,
    required List<Episode> episodes,
    required int total,
    required bool compact,
    required AppLocalizations l,
  }) {
    final seen = _seenCountFor(ref, episodes);
    return [
      if (compact)
        seen > 0
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Text(
                    l.episodesWatchedCount(seen, total),
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
            title: l.seasonNumber(season),
            subtitle: _seasonSubtitle(total: total, seen: seen),
          ),
        ),
      SliverToBoxAdapter(child: _episodeActionsHint(context)),
      _episodeCarousel(episodes, season: season),
    ];
  }

  Widget _episodeActionsHint(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Text(
          AppLocalizations.of(context).episodeActionsHelp,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );

  Widget _episodeCarousel(List<Episode> episodes,
      {bool resume = false, int? season}) {
    return SliverToBoxAdapter(
      child: _EpisodeCarousel(
        key: ValueKey(resume ? 'resume-carousel' : 'season-carousel-$season'),
        series: baseSeries,
        episodes: episodes,
        resume: resume,
      ),
    );
  }

  String _seasonSubtitle({required int total, required int seen}) {
    final l = AppLocalizations.of(context);
    if (seen == 0) return l.episodesCount(total);
    return l.episodesWatchedCount(seen, total);
  }
}

class _SeriesHeader extends ConsumerWidget {
  const _SeriesHeader({
    required this.series,
    required this.baseSeries,
    required this.l,
  });

  final SeriesDetail series;
  final Series baseSeries;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final metaParts = <String>[
      if (series.year > 0) '${series.year}',
      if (series.runtime > 0) l.seriesRuntimePerEpisode(series.runtime),
      if (series.genre.isNotEmpty) series.genre,
      if (series.rating > 0) '★ ${series.rating.toStringAsFixed(1)}',
    ];
    final meta = metaParts.join('  •  ');

    final extraMetaParts = <String>[
      if (series.status.isNotEmpty) series.status,
      if (series.networks.isNotEmpty)
        l.seriesNetwork(series.networks.join(', ')),
      if (series.firstAirDate.isNotEmpty)
        l.seriesFirstAired(_formatDate(context, series.firstAirDate)),
      if (series.numberOfSeasons > 0)
        l.seriesSeasonsCount(series.numberOfSeasons),
      if (series.numberOfEpisodes > 0) l.episodesCount(series.numberOfEpisodes),
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
                        ? OrbitCachedImage(
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
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getSourceColor(series.dataSource)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getSourceColor(series.dataSource)
                                .withValues(alpha: 0.3),
                          ),
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
                                  ? l.detailAiData
                                  : l.detailSourceData(
                                      series.dataSource.toUpperCase()),
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
          if (series.description.isNotEmpty)
            // Synopsis traduit si la source n'est pas en français. `isSeries`
            // aiguille la résolution TMDB vers `/search/tv` + `/tv/{id}` : le
            // chemin film ne trouvait rien et les synopsis restaient en anglais.
            TranslatedSynopsisView(
              title: series.title,
              rawSynopsis: series.description,
              isSeries: true,
              originalLanguageCode: series.originalLanguage,
            ),
          // Cast principal (compact)
          const SizedBox(height: 12),
          if (series.cast.isNotEmpty)
            CompactCastCarousel(
              actors: series.cast,
              title: l.mainCast,
              maxVisible: 8,
              onActorTap: (actor) =>
                  context.push('/actor/detail', extra: actor),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(
                    l.mainCast,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l.detailUnavailableValue,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmResetSeries(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final seen = ref
        .read(watchedEpisodesProvider.notifier)
        .countForSeries(baseSeries.id);
    if (seen == 0) return;

    final cancelFocus = FocusNode();
    final confirmFocus = FocusNode();

    void requestFocus(FocusNode focus) {
      if (context.mounted) {
        FocusScope.of(context).requestFocus(focus);
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.removeFromWatchedConfirm),
        content: Text(
          l.seriesResetWatchedBody(seen, baseSeries.title),
        ),
        actions: [
          Focus(
            focusNode: cancelFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.of(dialogContext).pop(false);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(confirmFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
          ),
          Focus(
            focusNode: confirmFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.of(dialogContext).pop(true);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(cancelFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.removeAll),
            ),
          ),
        ],
      ),
    );
    cancelFocus.dispose();
    confirmFocus.dispose();

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
            l.seriesResetWatchedDone(baseSeries.title),
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );
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

  String _formatDate(BuildContext context, String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    final result = safeSync(
      () {
        final date = DateTime.parse(dateStr);
        return MaterialLocalizations.of(context).formatShortDate(date);
      },
      context: '_formatDate',
      fallbackValue: dateStr,
    );
    return result.getOrElse(dateStr);
  }
}

const Color _watchedGreen = Color(0xFF66BB6A);

/// Seuil au-delà duquel un épisode est considéré « vu » (80 % regardés),
/// tout en restant reprenable.
const double _autoWatchedThreshold = 0.8;

class _EpisodeCarousel extends StatefulWidget {
  const _EpisodeCarousel({
    super.key,
    required this.series,
    required this.episodes,
    required this.resume,
  });

  final Series series;
  final List<Episode> episodes;
  final bool resume;

  @override
  State<_EpisodeCarousel> createState() => _EpisodeCarouselState();
}

class _EpisodeCarouselState extends State<_EpisodeCarousel> {
  int? _focusedIndex;
  ({
    List<Episode> episodes,
    String seriesTitle,
    TextStyle seriesStyle,
    TextStyle episodeStyle,
    TextStyle statusStyle,
    TextScaler scaler,
    TextDirection direction,
    Locale? locale,
  })? _heightInputs;
  double _height = 0;

  double _carouselHeight(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final inherited = DefaultTextStyle.of(context).style;
    final inputs = (
      episodes: widget.episodes,
      seriesTitle: widget.series.title,
      seriesStyle: inherited.merge(theme.labelMedium),
      episodeStyle: inherited
          .merge(theme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      statusStyle: inherited
          .merge(theme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      scaler: MediaQuery.textScalerOf(context),
      direction: Directionality.of(context),
      locale: Localizations.maybeLocaleOf(context),
    );
    if (_heightInputs == inputs) return _height;

    double textHeight(String text, TextStyle style, int? maxLines) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: inputs.direction,
        textScaler: inputs.scaler,
        locale: inputs.locale,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: 190);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    var titleHeight = 0.0;
    for (final episode in widget.episodes) {
      final title = _episodeTitleBelow(widget.series, episode);
      titleHeight = math.max(
        titleHeight,
        textHeight(title.isEmpty ? l.episode : title, inputs.episodeStyle, 3),
      );
    }
    _heightInputs = inputs;
    _height = 112 +
        8 +
        textHeight(inputs.seriesTitle, inputs.seriesStyle, 2) +
        3 +
        titleHeight +
        9 +
        4 +
        math.max(
          textHeight(l.resumeAction, inputs.statusStyle, null),
          textHeight('${l.episodeWatched} · ${l.resumeAction}',
              inputs.statusStyle, null),
        ) +
        24 +
        8;
    return _height;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Text(
            _focusedIndex == null || _focusedIndex! >= widget.episodes.length
                ? l.episodesCount(widget.episodes.length)
                : '${_focusedIndex! + 1} / ${widget.episodes.length}',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        SizedBox(
          height: _carouselHeight(context),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _EpisodeOrbitPainter(scheme.primary),
                  ),
                ),
              ),
              ListView.builder(
                scrollDirection: Axis.horizontal,
                cacheExtent: 500,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: widget.episodes.length,
                itemExtent: 190,
                itemBuilder: (context, index) => _EpisodeTile(
                  key: ValueKey(
                      '${widget.resume ? 'resume' : 'season'}-episode-$index'),
                  series: widget.series,
                  episode: widget.episodes[index],
                  onFocus: () {
                    if (_focusedIndex != index) {
                      setState(() => _focusedIndex = index);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EpisodeOrbitPainter extends CustomPainter {
  const _EpisodeOrbitPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromCenter(
      center: Offset(size.width / 2, 68),
      width: size.width * 1.05,
      height: 120,
    );
    canvas.drawOval(
      bounds,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_EpisodeOrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ResetEpisodeDialog extends StatefulWidget {
  const _ResetEpisodeDialog({
    required this.title,
    required this.message,
    required this.resetLabel,
  });

  final String title;
  final String message;
  final String resetLabel;

  @override
  State<_ResetEpisodeDialog> createState() => _ResetEpisodeDialogState();
}

class _ResetEpisodeDialogState extends State<_ResetEpisodeDialog> {
  final _cancelFocus = FocusNode();
  final _resetFocus = FocusNode();
  late final Set<LogicalKeyboardKey> _openingKeys;

  @override
  void initState() {
    super.initState();
    _openingKeys = HardwareKeyboard.instance.logicalKeysPressed
        .where(_isSelectKey)
        .toSet();
  }

  static bool _isSelectKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.gameButtonA;

  @override
  void dispose() {
    _cancelFocus.dispose();
    _resetFocus.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_openingKeys.contains(event.logicalKey)) {
      if (event is KeyUpEvent) _openingKeys.remove(event.logicalKey);
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final towardReset = Directionality.of(context) == TextDirection.ltr
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final towardCancel = Directionality.of(context) == TextDirection.ltr
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    if (key == towardReset && _cancelFocus.hasFocus) {
      _resetFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == towardCancel && _resetFocus.hasFocus) {
      _cancelFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA) {
      if (_cancelFocus.hasFocus || _resetFocus.hasFocus) {
        Navigator.of(context).pop(_resetFocus.hasFocus);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _handleKey,
      child: AlertDialog(
        title: Text(widget.title),
        content: Text(widget.message),
        actions: [
          TextButton(
            autofocus: true,
            focusNode: _cancelFocus,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            focusNode: _resetFocus,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.resetLabel),
          ),
        ],
      ),
    );
  }
}

String _episodeCleanTitle(Series series, Episode episode) {
  var title = episode.title.trim();
  if (title.startsWith(series.title)) {
    title = title
        .substring(series.title.length)
        .replaceFirst(RegExp(r'^\s*[-–—]\s*'), '');
  }
  return title;
}

bool _episodeHasNumber(String title) =>
    RegExp(r'^S\d+E\d+([\s\-–—]|$)', caseSensitive: false).hasMatch(title);

String _episodeTitleBelow(Series series, Episode episode) {
  final title = _episodeCleanTitle(series, episode);
  return _episodeHasNumber(title)
      ? title
          .replaceFirst(
            RegExp(r'^S\d+E\d+\s*[-–—]?\s*', caseSensitive: false),
            '',
          )
          .trim()
      : title;
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({
    super.key,
    required this.series,
    required this.episode,
    required this.onFocus,
  });

  final Series series;
  final Episode episode;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final number = 'S${episode.season.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';
    final episodeTitle = _episodeCleanTitle(series, episode);
    final hasNumber = _episodeHasNumber(episodeTitle);
    final label = episodeTitle.isNotEmpty
        ? (hasNumber ? episodeTitle : '$number — $episodeTitle')
        : '${l.episode} $number';
    final titleBelow = _episodeTitleBelow(series, episode);
    final canPlay = episode.streamUrl.isNotEmpty;
    final profileId = ref.watch(currentProfileProvider)?.id ?? '';
    final watched = ref.watch(watchedEpisodesProvider).containsKey(
          WatchedEpisodeEntry.keyFor(
            profileId: profileId,
            seriesId: series.id,
            season: episode.season,
            episodeNumber: episode.episodeNumber,
            episodeId: episode.id,
          ),
        );
    final progressId = PlaybackProgressService.idForProfile(
      profileId,
      'episode-${episode.id}',
    );
    final progress = ref.watch(playbackProgressServiceProvider).get(progressId);
    final progressFraction = progress?.fraction ?? 0;
    // Épisode auto-vu (>= 80 % regardés) : « Vu », mais toujours reprenable.
    final autoWatched = progress?.hasProgress == true &&
        progressFraction >= _autoWatchedThreshold;
    final isVu = watched || autoWatched;
    // En cours : progression existante, sous le seuil de 80 %.
    final inProgress =
        progress?.hasProgress == true && progressFraction > 0 && !autoWatched;

    void onOpen() {
      if (!canPlay) return;
      context.push('/episode/detail', extra: (series, episode));
    }

    Future<void> setWatched(bool value) async {
      if (profileId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.episodeSelectProfile)),
        );
        return;
      }
      if (ref.read(currentProfileProvider)?.id != profileId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.episodeProfileChanged)),
        );
        return;
      }
      try {
        final watchedNotifier = ref.read(watchedEpisodesProvider.notifier);
        final progressService = ref.read(playbackProgressServiceProvider);
        if (value) {
          await watchedNotifier.record(series, episode);
        } else {
          if (watched) {
            await watchedNotifier.toggle(series, episode);
          }
          if (progress?.hasProgress == true) {
            await progressService.clear(progressId);
          }
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.episodeStatusFailed)),
          );
        }
      }
    }

    Future<void> onLongPress() async {
      final hasProgress = progress?.hasProgress == true;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _ResetEpisodeDialog(
          title: isVu ? l.episodeResetQuestion : l.episodeMarkWatchedQuestion,
          message: isVu && hasProgress
              ? l.episodeResetProgressMessage(label)
              : isVu
                  ? l.episodeMarkUnwatchedMessage(label)
                  : l.episodeMarkWatchedMessage(label),
          resetLabel: isVu ? l.reset : l.episodeMarkWatched,
        ),
      );

      if (confirmed != true) return;
      if (!context.mounted) return;
      await setWatched(!isVu);
    }

    return Semantics(
      container: true,
      label:
          '${series.title}, $label${isVu ? ', ${l.episodeWatched}' : ''}${inProgress ? ', ${l.resumeAction}' : ''}',
      child: GestureDetector(
        onTap: canPlay ? onOpen : null,
        onLongPress: onLongPress,
        child: Column(
          children: [
            TvFocus(
              circular: true,
              onActivate: onOpen,
              onLongPress: onLongPress,
              onFocusChange: (focused) {
                if (!focused) return;
                onFocus();
                Scrollable.ensureVisible(
                  context,
                  alignment: 0.4,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.surfaceContainerHighest,
                    ],
                  ),
                  border: Border.all(
                    color: isVu
                        ? _watchedGreen
                        : scheme.primary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (series.coverUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              OrbitCachedImage(
                                imageUrl: series.coverUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const SizedBox.shrink(),
                                errorWidget: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                              ColoredBox(
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          canPlay
                              ? Icons.play_circle_outline
                              : Icons.play_circle,
                          color: series.coverUrl.isNotEmpty
                              ? Colors.white
                              : canPlay
                                  ? scheme.primary
                                  : scheme.outline,
                          size: 30,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              number,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: series.coverUrl.isNotEmpty
                                        ? Colors.white
                                        : null,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: ExcludeFocus(
                        child: GestureDetector(
                          onLongPress: onLongPress,
                          child: TooltipTheme(
                            data: const TooltipThemeData(
                                triggerMode: TooltipTriggerMode.manual),
                            child: IconButton(
                              tooltip: isVu
                                  ? l.episodeMarkUnwatched
                                  : l.episodeMarkWatched,
                              onPressed: () => setWatched(!isVu),
                              icon: Icon(
                                isVu
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: isVu
                                    ? _watchedGreen
                                    : series.coverUrl.isNotEmpty
                                        ? Colors.white
                                        : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Tooltip(
              message: series.title,
              child: Text(
                series.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 3),
            Tooltip(
              message: label,
              child: Text(
                titleBelow.isEmpty
                    ? AppLocalizations.of(context).episode
                    : titleBelow,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isVu ? scheme.onSurfaceVariant : null,
                    ),
              ),
            ),
            if (inProgress && progress != null && progress.durationMs > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 3,
                    backgroundColor:
                        scheme.onSurfaceVariant.withValues(alpha: 0.15),
                  ),
                ),
              ),
            if (inProgress || isVu)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  inProgress && isVu
                      ? '${l.episodeWatched} · ${l.resumeAction}'
                      : inProgress
                          ? l.resumeAction
                          : l.episodeWatched,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: inProgress ? scheme.primary : _watchedGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeriesTrackPreferences extends ConsumerWidget {
  const _SeriesTrackPreferences({required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final external =
        ref.watch(advancedSettingsProvider).playerSeries.primary.isExternal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (external)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l.seriesExternalTracksHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final audio = SeriesAudioLanguageSelector(seriesId: seriesId);
                  final subtitles =
                      SeriesSubtitleLanguageSelector(seriesId: seriesId);
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  if (constraints.maxWidth < 640 * scale) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [audio, const SizedBox(height: 16), subtitles],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: audio),
                      const SizedBox(width: 24),
                      Expanded(child: subtitles),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de langue audio par défaut pour une série.
/// Permet de choisir une langue (ex: FR) et de l'appliquer à tous les épisodes.
class SeriesAudioLanguageSelector extends ConsumerStatefulWidget {
  const SeriesAudioLanguageSelector(
      {super.key, required this.seriesId, this.fetchTracks});
  final String seriesId;
  final Future<List<(String, String)>> Function()? fetchTracks;

  @override
  ConsumerState<SeriesAudioLanguageSelector> createState() =>
      _SeriesAudioLanguageSelectorState();
}

class _SeriesAudioLanguageSelectorState
    extends ConsumerState<SeriesAudioLanguageSelector> {
  String? _selectedLanguage;
  bool _forced = false;
  bool _loading = true;
  bool _preferencesLoaded = false;
  List<(String, String)> _availableLanguages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 1. Charger préférences sauvegardées
    final lang = await PlayerTrackPrefs.seriesAudioLanguageFor(widget.seriesId);
    final forced = await PlayerTrackPrefs.isSeriesAudioForced(widget.seriesId);
    if (!mounted) return;
    setState(() {
      _selectedLanguage = lang;
      _forced = forced;
      _preferencesLoaded = true;
    });

    // 2. Récupérer les langues réelles depuis le premier épisode jouable
    final languages =
        await (widget.fetchTracks?.call() ?? _fetchRealAudioLanguages());

    if (mounted) {
      setState(() {
        _availableLanguages = languages;
        _loading = false;
      });
    }
  }

  /// Récupère les langues audio réelles depuis le premier épisode jouable de la série.
  Future<List<(String, String)>> _fetchRealAudioLanguages() async {
    // On a besoin de la série de base pour accéder aux épisodes
    // Le widget parent a déjà chargé la série via baseSeriesAsync
    // On utilise le provider seriesInfoProvider
    final seriesAsync = ref.read(seriesInfoProvider(widget.seriesId));
    final series = seriesAsync.value;
    if (series == null) return const [];

    // Trouver le premier épisode avec une URL de stream valide
    Episode? firstPlayableEpisode;
    for (final ep in series.episodes) {
      if (ep.streamUrl.isNotEmpty) {
        firstPlayableEpisode = ep;
        break;
      }
    }
    if (firstPlayableEpisode == null) return const [];

    // Récupérer les tracks audio réels depuis le flux
    return StreamAudioTracksService.fetchAudioTracks(
      firstPlayableEpisode.streamUrl,
    );
  }

  Future<void> _onLanguageChanged(String? lang) async {
    if (lang == null) return;
    await PlayerTrackPrefs.setSeriesAudioLanguage(widget.seriesId, lang);
    if (mounted) {
      setState(() => _selectedLanguage = lang);
    }
  }

  Future<void> _onForcedChanged(bool value) async {
    await PlayerTrackPrefs.setSeriesAudioForced(widget.seriesId, value);
    if (mounted) setState(() => _forced = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.audiotrack_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.seriesDefaultAudioLanguage,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SeriesTrackPreferenceRow(
          dropdown: DropdownButtonFormField<String>(
            key: ValueKey(_selectedLanguage),
            initialValue: _selectedLanguage,
            isExpanded: true,
            style: textTheme.titleMedium?.copyWith(fontSize: 12),
            decoration: InputDecoration(
              labelText: l.language,
              labelStyle: const TextStyle(fontSize: 12),
              hintText: l.seriesSelectLanguage,
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.language_outlined),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text(l.seriesStreamDefault),
              ),
              ..._availableLanguages.map(
                (l) => DropdownMenuItem<String>(
                  value: l.$1,
                  child: Text(l.$2),
                ),
              ),
              if (_selectedLanguage != null &&
                  _selectedLanguage!.isNotEmpty &&
                  !_availableLanguages.any((l) => l.$1 == _selectedLanguage))
                DropdownMenuItem<String>(
                  value: _selectedLanguage,
                  child: Text(_selectedLanguage!),
                ),
            ],
            onChanged: _preferencesLoaded ? _onLanguageChanged : null,
          ),
          forced: _forced,
          onForcedChanged: _selectedLanguage == null ? null : _onForcedChanged,
          description: _selectedLanguage == null
              ? l.seriesChooseLanguageFirst
              : _selectedLanguage!.isEmpty
                  ? (_forced
                      ? l.seriesDefaultAllEpisodes
                      : l.seriesDefaultUnlessEpisodeChoice)
                  : _forced
                      ? l.seriesForceLanguageAllEpisodes
                      : l.seriesApplyIfAvailable,
        ),
        if (_loading) Text(l.seriesSearchingAudio),
      ],
    );
  }
}

/// Sélecteur de langue de sous-titres par défaut pour une série.
/// Permet de choisir une langue (ex: FR) et de l'appliquer à tous les épisodes.
///
/// Même principe que [SeriesAudioLanguageSelector] : la préférence est
/// mémorisée par série ([PlayerTrackPrefs]) et le lecteur la ré-applique à
/// chaque épisode. Les entrées reproduisent les pistes **intégrées** réellement
/// présentes dans le premier épisode jouable — **une par piste**, comme la
/// feuille du lecteur, variantes `(CC)`/`(SDH)` comprises. Dédupliquer par
/// langue faisait disparaître ces variantes et n'affichait que deux entrées là
/// où le lecteur en offrait cinq.
class SeriesSubtitleLanguageSelector extends ConsumerStatefulWidget {
  const SeriesSubtitleLanguageSelector({
    super.key,
    required this.seriesId,
    this.fetchTracks,
  });
  final String seriesId;
  final Future<List<(String, String)>> Function()? fetchTracks;

  @override
  ConsumerState<SeriesSubtitleLanguageSelector> createState() =>
      _SeriesSubtitleLanguageSelectorState();
}

class _SeriesSubtitleLanguageSelectorState
    extends ConsumerState<SeriesSubtitleLanguageSelector> {
  String? _selectedLanguage;
  bool _forced = false;
  bool _loading = true;
  bool _preferencesLoaded = false;
  List<(String, String)> _availableLanguages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 1. Charger préférences sauvegardées
    final lang = await PlayerTrackPrefs.seriesSubtitleLanguageFor(
      widget.seriesId,
    );
    final forced = await PlayerTrackPrefs.isSeriesSubtitleForced(
      widget.seriesId,
    );
    if (!mounted) return;
    setState(() {
      _selectedLanguage = lang;
      _forced = forced;
      _preferencesLoaded = true;
    });

    // 2. Récupérer les langues réelles depuis le premier épisode jouable
    final languages =
        await (widget.fetchTracks?.call() ?? _fetchRealSubtitleLanguages());

    if (mounted) {
      setState(() {
        _availableLanguages = languages;
        _loading = false;
      });
    }
  }

  /// Récupère les langues de sous-titres intégrées du premier épisode jouable.
  Future<List<(String, String)>> _fetchRealSubtitleLanguages() async {
    final seriesAsync = ref.read(seriesInfoProvider(widget.seriesId));
    final series = seriesAsync.value;
    if (series == null) return const [];

    Episode? firstPlayableEpisode;
    for (final ep in series.episodes) {
      if (ep.streamUrl.isNotEmpty) {
        firstPlayableEpisode = ep;
        break;
      }
    }
    if (firstPlayableEpisode == null) return const [];

    return StreamSubtitleTracksService.fetchSubtitleTracks(
      firstPlayableEpisode.streamUrl,
    );
  }

  Future<void> _onLanguageChanged(String? lang) async {
    if (lang == null) return;
    await PlayerTrackPrefs.setSeriesSubtitleLanguage(widget.seriesId, lang);
    if (mounted) {
      setState(() => _selectedLanguage = lang);
    }
  }

  Future<void> _onForcedChanged(bool value) async {
    await PlayerTrackPrefs.setSeriesSubtitleForced(widget.seriesId, value);
    if (mounted) setState(() => _forced = value);
  }

  /// Items du menu (hors « (Désactivés) », ajouté en tête).
  ///
  /// La préférence mémorisée peut ne pas figurer dans la sonde courante
  /// (l'épisode sondé n'a pas exactement les mêmes pistes, ou media3 n'a pas
  /// encore publié toutes les variantes) : on l'ajoute alors telle quelle.
  /// Sans ça, `DropdownButtonFormField` lèverait une assertion — « value » doit
  /// exister parmi les items — et l'écran série planterait à l'ouverture.
  List<DropdownMenuItem<String>> _dropdownItems(AppLocalizations l) {
    final fallbackLanguages = <(String, String)>[
      ('fr', l.seriesLanguageFrench),
      ('en', l.seriesLanguageEnglish),
      ('es', l.seriesLanguageSpanish),
      ('de', l.seriesLanguageGerman),
      ('it', l.seriesLanguageItalian),
      ('ar', l.seriesLanguageArabic),
    ];
    final languages =
        _availableLanguages.isEmpty ? fallbackLanguages : _availableLanguages;
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: '',
        child: Text(l.seriesSubtitlesDisabled),
      ),
      ...languages.map(
        (l) => DropdownMenuItem<String>(
          value: l.$1,
          child: Text(l.$2),
        ),
      ),
    ];
    final saved = _selectedLanguage;
    if (saved != null &&
        saved.isNotEmpty &&
        !items.any((item) => item.value == saved)) {
      items.add(DropdownMenuItem<String>(value: saved, child: Text(saved)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.subtitles_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.seriesDefaultSubtitleLanguage,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SeriesTrackPreferenceRow(
          dropdown: DropdownButtonFormField<String>(
            key: ValueKey(_selectedLanguage),
            initialValue: _selectedLanguage,
            isExpanded: true,
            style: textTheme.titleMedium?.copyWith(fontSize: 12),
            decoration: InputDecoration(
              labelText: l.language,
              labelStyle: const TextStyle(fontSize: 12),
              hintText: l.seriesSelectLanguage,
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.subtitles_outlined),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: _dropdownItems(l),
            onChanged: _preferencesLoaded ? _onLanguageChanged : null,
          ),
          forced: _forced,
          onForcedChanged: _selectedLanguage == null ? null : _onForcedChanged,
          description: _selectedLanguage == null
              ? l.seriesChooseLanguageFirst
              : _selectedLanguage!.isEmpty
                  ? (_forced
                      ? l.seriesDisableSubtitlesAll
                      : l.seriesDisableSubtitlesDefault)
                  : _forced
                      ? l.seriesForceLanguageAllEpisodes
                      : l.seriesApplyIfAvailable,
        ),
        if (_loading) Text(l.seriesSearchingSubtitles),
        if (!_loading && _availableLanguages.isEmpty)
          Text(l.seriesNoSubtitleTracks),
      ],
    );
  }
}

class _SeriesTrackPreferenceRow extends StatelessWidget {
  const _SeriesTrackPreferenceRow({
    required this.dropdown,
    required this.forced,
    required this.onForcedChanged,
    required this.description,
  });

  final Widget dropdown;
  final bool forced;
  final ValueChanged<bool>? onForcedChanged;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checkbox = Row(
      children: [
        Checkbox(
          value: forced,
          onChanged: onForcedChanged == null
              ? null
              : (value) => onForcedChanged!(value ?? false),
        ),
        Expanded(
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: forced && onForcedChanged != null
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: forced ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(children: [dropdown, checkbox]);
        }
        return Row(
          children: [
            Expanded(child: dropdown),
            const SizedBox(width: 12),
            Expanded(child: checkbox),
          ],
        );
      },
    );
  }
}
