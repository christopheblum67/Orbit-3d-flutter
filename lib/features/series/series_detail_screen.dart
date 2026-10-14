import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
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
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Retour',
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(l.detailUnavailable),
        ),
        body: ErrorState(
          icon: Icons.tv,
          title: l.detailUnavailable,
          message: 'Identifiant de série manquant (navigation incorrecte). '
              'Retournez Ã  la liste et réessayez.',
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
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
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
            data: (detail) => _SeriesDetailContent(
              detail: detail,
              baseSeries: baseSeries,
            ),
            loading: () =>
                const LoadingState(message: 'Enrichissement des métadonnéesâ€¦'),
            error: (err, _) => ErrorState(
              icon: Icons.tv,
              title: l.detailUnavailable,
              message: userFriendlyError(err),
              onRetry: () => ref.invalidate(seriesDetailProvider(baseSeries)),
            ),
          ),
        );
      },
      loading: () => const LoadingState(message: 'Chargement de la sérieâ€¦'),
      error: (err, _) => ErrorState(
        icon: Icons.tv,
        title: l.seriesNotFound,
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
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final episodesBySeason = <int, List<Episode>>{};
    for (final episode in baseSeries.episodes) {
      episodesBySeason.putIfAbsent(episode.season, () => []).add(episode);
    }
    final seasons = episodesBySeason.keys.toList()..sort();

    final header = SliverToBoxAdapter(
      child: _SeriesHeader(series: detail, baseSeries: baseSeries, l: l),
    );

    // Section Â« Reprendre Â» : épisodes avec une progression en cours
    // (0 < % regardé < 80 %), affichée au-dessus des saisons.
    final resumeEpisodes = _resumeEpisodesFor(ref);
    final resumeSliver = resumeEpisodes.isEmpty
        ? const SliverToBoxAdapter(child: SizedBox.shrink())
        : SliverToBoxAdapter(
            child: _ResumeSection(
              series: baseSeries,
              episodes: resumeEpisodes,
            ),
          );

    if (seasons.isEmpty) {
      return CustomScrollView(
        slivers: [
          header,
          resumeSliver,
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.video_library_outlined,
              title: l.noEpisodes,
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
          resumeSliver,
          ..._seasonSlivers(
            context,
            ref: ref,
            season: season,
            episodes: episodesBySeason[season]!,
            total: episodesBySeason[season]!.length,
            compact: false,
            l: l,
          ),
        ],
      );
    }

    // Plusieurs saisons : TabBar horizontale pour alléger la liste, une seule
    // saison visible Ã  la fois (au lieu de les empiler verticalement).
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
                      resumeSliver,
                      ..._seasonSlivers(
                        context,
                        ref: ref,
                        season: season,
                        episodes: episodesBySeason[season]!,
                        total: episodesBySeason[season]!.length,
                        compact: true,
                        l: l,
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

  /// Ã‰pisodes Â« Ã  reprendre Â» : une progression de lecture existe et est
  /// inférieure au seuil de 80 % (au-delÃ , l'épisode est considéré Â« vu Â»).
  List<Episode> _resumeEpisodesFor(WidgetRef ref) {
    final result = <Episode>[];
    for (final episode in baseSeries.episodes) {
      final progress = ref.watch(
        playbackProgressProvider('episode-${episode.id}'),
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
    final profile = ref.read(currentProfileProvider);
    if (episodes.isEmpty) return 0;
    var seen = 0;
    for (final episode in episodes) {
      final isVu = ref.read(watchedEpisodesProvider).containsKey(
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
      final progress = ref.watch(
        playbackProgressProvider('episode-${episode.id}'),
      );
      if (progress != null && progress.fraction >= _autoWatchedThreshold) {
        seen++;
      }
    }
    return seen;
  }

  /// Slivers d'une saison :
  ///  - `compact` (mode onglets) : simple rappel Â« X/Y vus Â», pas de gros
  ///    titre de section redondant avec l'onglet ;
  ///  - sinon : en-tÃªte de section classique Â« Saison N Â».
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
            title: l.seasonNumber(season),
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
            title: l.specialGuestsSeason(season),
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
      if (series.runtime > 0) '${series.runtime} min/ép',
      if (series.genre.isNotEmpty) series.genre,
      if (series.rating > 0) 'â˜… ${series.rating.toStringAsFixed(1)}',
    ];
    final meta = metaParts.join('  â€¢  ');

    final extraMetaParts = <String>[
      if (series.status.isNotEmpty) series.status,
      if (series.networks.isNotEmpty) 'Réseau: ${series.networks.join(', ')}',
      if (series.firstAirDate.isNotEmpty)
        '1Ê³áµ‰ diffusion: ${_formatDate(series.firstAirDate)}',
      if (series.numberOfSeasons > 0) '${series.numberOfSeasons} saisons',
      if (series.numberOfEpisodes > 0) '${series.numberOfEpisodes} épisodes',
    ];
    final extraMeta = extraMetaParts.join('  â€¢  ');

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
                  // Pression longue sur la série = Â« retour en arrière Â» :
                  // propose de tout retirer des déjÃ  vus.
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
          if (series.description.isNotEmpty)
            // Synopsis traduit si la source n'est pas en français. `isSeries`
            // aiguille la résolution TMDB vers `/search/tv` + `/tv/{id}` : le
            // chemin film ne trouvait rien et les synopsis restaient en anglais.
            TranslatedSynopsisView(
              title: series.title,
              rawSynopsis: series.description,
              isSeries: true,
            ),
          // Cast principal (compact)
          const SizedBox(height: 12),
          if (series.cast.isNotEmpty)
            CompactCastCarousel(
              actors: series.cast,
              title: l.mainCast,
              maxVisible: 8,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l.mainCast,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Non disponible',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Sélecteur de langue audio par défaut pour la série
          _SeriesAudioLanguageSelector(seriesId: baseSeries.id),
          const SizedBox(height: 16),
          // Sélecteur de langue de sous-titres par défaut pour la série
          _SeriesSubtitleLanguageSelector(seriesId: baseSeries.id),
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
          'Les $seen épisodes vus de Â« ${baseSeries.title} Â» seront marqués '
          'comme non vus pour ce profil.',
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
              child: const Text('Annuler'),
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
            'Â« ${baseSeries.title} Â» retiré des déjÃ  vus.',
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    final result = safeSync(
      () {
        final date = DateTime.parse(dateStr);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      },
      context: '_formatDate',
      fallbackValue: dateStr,
    );
    return result.getOrElse(dateStr);
  }
}

const Color _watchedGreen = Color(0xFF66BB6A);

/// Seuil au-delÃ  duquel un épisode est considéré Â« vu Â» (80 % regardés),
/// tout en restant reprenable.
const double _autoWatchedThreshold = 0.8;

/// Section Â« Reprendre Â» : liste les épisodes de la série dont la lecture est
/// en cours (0 % < regardés < 80 %), pour relancer facilement.
class _ResumeSection extends ConsumerWidget {
  const _ResumeSection({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.replay_rounded,
          title: 'Reprendre',
          subtitle: '${episodes.length} '
              '${episodes.length > 1 ? 'épisodes en cours' : 'épisode en cours'}',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              for (final episode in episodes)
                _EpisodeTile(series: series, episode: episode),
            ],
          ),
        ),
      ],
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({required this.series, required this.episode});

  final Series series;
  final Episode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final number = 'S${episode.season.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';
    var episodeTitle = episode.title.trim();
    if (episodeTitle.startsWith(series.title)) {
      episodeTitle = episodeTitle
          .substring(series.title.length)
          .replaceFirst(RegExp(r'^\s*[-â€“â€”]\s*'), '');
    }
    final hasNumber = RegExp(r'^S\d+E\d+([\s\-â€“â€”]|$)').hasMatch(episodeTitle);
    final label = episodeTitle.isNotEmpty
        ? (hasNumber ? episodeTitle : '$number â€” $episodeTitle')
        : 'Ã‰pisode $number';
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
    final progress =
        ref.watch(playbackProgressProvider('episode-${episode.id}'));
    final progressFraction = progress?.fraction ?? 0;
    // Ã‰pisode auto-vu (>= 80 % regardés) : Â« Vu Â», mais toujours reprenable.
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

    // Pression longue = Â« réinitialiser Â» : efface la progression de lecture
    // en cours et/ou retire le statut Â« vu Â» (après confirmation).
    Future<void> onLongPress() async {
      final hasProgress = progress?.hasProgress == true;
      if (!isVu && !hasProgress) return;

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
          title: const Text('Réinitialiser l\'épisode ?'),
          content: Text(
            isVu && hasProgress
                ? 'Â« $label Â» sera marqué comme non vu et sa progression '
                    'de lecture sera effacée.'
                : isVu
                    ? 'Â« $label Â» sera marqué comme non vu pour ce profil.'
                    : 'La progression de lecture de Â« $label Â» sera effacée.',
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
                child: const Text('Annuler'),
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
                child: Text(l.reset),
              ),
            ),
          ],
        ),
      );
      cancelFocus.dispose();
      confirmFocus.dispose();

      if (confirmed != true) return;
      // Le dialogue est modal, mais l'utilisateur peut encore avoir quitté
      // l'écran de la série avec la télécommande pendant qu'il était ouvert.
      // Trois lectures de `ref` suivaient, sans aucune garde.
      if (!context.mounted) return;
      if (isVu) {
        ref.read(watchedEpisodesProvider.notifier).toggle(series, episode);
      }
      if (hasProgress) {
        final progressId = 'episode-${episode.id}';
        ref.read(playbackProgressServiceProvider).clear(progressId);
        ref.invalidate(playbackProgressProvider(progressId));
      }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isVu ? scheme.onSurfaceVariant : null,
                          ),
                    ),
                    if (inProgress &&
                        progress != null &&
                        progress.durationMs > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
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
                  ],
                ),
              ),
              if (inProgress) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Reprendre',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ] else if (isVu) ...[
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
                tooltip: isVu ? 'Marquer comme non vu' : 'Marquer comme vu',
                onPressed: () => ref
                    .read(watchedEpisodesProvider.notifier)
                    .toggle(series, episode),
                icon: Icon(
                  isVu ? Icons.check_circle : Icons.check_circle_outline,
                  color: isVu ? _watchedGreen : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de langue audio par défaut pour une série.
/// Permet de choisir une langue (ex: FR) et de l'appliquer Ã  tous les épisodes.
class _SeriesAudioLanguageSelector extends ConsumerStatefulWidget {
  const _SeriesAudioLanguageSelector({required this.seriesId});
  final String seriesId;

  @override
  ConsumerState<_SeriesAudioLanguageSelector> createState() =>
      _SeriesAudioLanguageSelectorState();
}

class _SeriesAudioLanguageSelectorState
    extends ConsumerState<_SeriesAudioLanguageSelector> {
  String? _selectedLanguage;
  bool _forced = false;
  bool _loading = true;
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

    // 2. Récupérer les langues réelles depuis le premier épisode jouable
    final languages = await _fetchRealAudioLanguages();

    if (mounted) {
      setState(() {
        _selectedLanguage = lang;
        _forced = forced;
        _availableLanguages = languages;
        _loading = false;
      });
    }
  }

  /// Récupère les langues audio réelles depuis le premier épisode jouable de la série.
  Future<List<(String, String)>> _fetchRealAudioLanguages() async {
    // On a besoin de la série de base pour accéder aux épisodes
    // Le widget parent a déjÃ  chargé la série via baseSeriesAsync
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
    if (lang == null || lang.isEmpty) {
      await PlayerTrackPrefs.clearSeriesAudioPreference(widget.seriesId);
      if (mounted) {
        setState(() {
          _selectedLanguage = null;
          _forced = false;
        });
      }
    } else {
      await PlayerTrackPrefs.setSeriesAudioLanguage(widget.seriesId, lang);
      if (mounted) {
        setState(() => _selectedLanguage = lang);
      }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.audiotrack_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Langue audio par défaut',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Langue',
                      hintText: 'Sélectionner une langue',
                      prefixIcon: Icon(Icons.language_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('(Défaut du flux)'),
                      ),
                      ..._availableLanguages.map(
                        (l) => DropdownMenuItem<String>(
                          value: l.$1,
                          child: Text(l.$2),
                        ),
                      ),
                    ],
                    onChanged: _onLanguageChanged,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _forced,
                        onChanged: _selectedLanguage == null
                            ? null
                            : (v) => _onForcedChanged(v ?? false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_selectedLanguage == null)
                              ? 'Choisissez d\'abord une langue'
                              : _forced
                                  ? 'Forcer cette langue pour TOUS les épisodes de la série'
                                  : 'Appliquer seulement si disponible (sinon langue du flux)',
                          style: textTheme.bodySmall?.copyWith(
                            color: (_selectedLanguage == null || !_forced)
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                            fontWeight: _forced && _selectedLanguage != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }
}

/// Sélecteur de langue de sous-titres par défaut pour une série.
/// Permet de choisir une langue (ex: FR) et de l'appliquer Ã  tous les épisodes.
///
/// MÃªme principe que [_SeriesAudioLanguageSelector] : la préférence est
/// mémorisée par série ([PlayerTrackPrefs]) et le lecteur la ré-applique Ã 
/// chaque épisode. Les entrées reproduisent les pistes **intégrées** réellement
/// présentes dans le premier épisode jouable â€” **une par piste**, comme la
/// feuille du lecteur, variantes `(CC)`/`(SDH)` comprises. Dédupliquer par
/// langue faisait disparaÃ®tre ces variantes et n'affichait que deux entrées lÃ 
/// où le lecteur en offrait cinq.
class _SeriesSubtitleLanguageSelector extends ConsumerStatefulWidget {
  const _SeriesSubtitleLanguageSelector({required this.seriesId});
  final String seriesId;

  @override
  ConsumerState<_SeriesSubtitleLanguageSelector> createState() =>
      _SeriesSubtitleLanguageSelectorState();
}

class _SeriesSubtitleLanguageSelectorState
    extends ConsumerState<_SeriesSubtitleLanguageSelector> {
  String? _selectedLanguage;
  bool _forced = false;
  bool _loading = true;
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

    // 2. Récupérer les langues réelles depuis le premier épisode jouable
    final languages = await _fetchRealSubtitleLanguages();

    if (mounted) {
      setState(() {
        _selectedLanguage = lang;
        _forced = forced;
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
    if (lang == null || lang.isEmpty) {
      await PlayerTrackPrefs.clearSeriesSubtitlePreference(widget.seriesId);
      if (mounted) {
        setState(() {
          _selectedLanguage = null;
          _forced = false;
        });
      }
    } else {
      await PlayerTrackPrefs.setSeriesSubtitleLanguage(widget.seriesId, lang);
      if (mounted) {
        setState(() => _selectedLanguage = lang);
      }
    }
  }

  Future<void> _onForcedChanged(bool value) async {
    await PlayerTrackPrefs.setSeriesSubtitleForced(widget.seriesId, value);
    if (mounted) setState(() => _forced = value);
  }

  /// Items du menu (hors Â« (Désactivés) Â», ajouté en tÃªte).
  ///
  /// La préférence mémorisée peut ne pas figurer dans la sonde courante
  /// (l'épisode sondé n'a pas exactement les mÃªmes pistes, ou media3 n'a pas
  /// encore publié toutes les variantes) : on l'ajoute alors telle quelle.
  /// Sans ça, `DropdownButtonFormField` lèverait une assertion â€” Â« value Â» doit
  /// exister parmi les items â€” et l'écran série planterait Ã  l'ouverture.
  List<DropdownMenuItem<String>> _dropdownItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('(Désactivés)'),
      ),
      ..._availableLanguages.map(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.subtitles_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Langue des sous-titres par défaut',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Langue des sous-titres',
                      hintText: 'Sélectionner une langue',
                      prefixIcon: Icon(Icons.subtitles_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _dropdownItems(),
                    onChanged: _onLanguageChanged,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _forced,
                        onChanged: _selectedLanguage == null
                            ? null
                            : (v) => _onForcedChanged(v ?? false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_selectedLanguage == null)
                              ? 'Choisissez d\'abord une langue'
                              : _forced
                                  ? 'Forcer cette langue pour TOUS les épisodes de la série'
                                  : 'Appliquer seulement si disponible (sinon langue du flux)',
                          style: textTheme.bodySmall?.copyWith(
                            color: (_selectedLanguage == null || !_forced)
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                            fontWeight: _forced && _selectedLanguage != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }
}









