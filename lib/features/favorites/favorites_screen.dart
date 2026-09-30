import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Écran Favoris v2 : 4 sections (Live, Films, Séries, Replay).
///
/// La liste est pilotée par [favoritesProvider] (réactif). Les cartes sont
/// résolues depuis les catalogues quand ils sont chargés, sinon les données
/// mémorisées dans l'entrée favorite suffisent à l'affichage et à la lecture.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    int count(ContentType type) =>
        favorites.values.where((e) => e.type == type).length;
    String label(String base, int n) => n > 0 ? '$base ($n)' : base;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          // Toujours afficher le retour : Favoris est accessible en route racine
          // (menu latéral), où `canPop()` est false et l'icône disparaissait.
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Retour',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: const Text('Favoris'),
          actions: [
            if (favorites.isNotEmpty)
              IconButton(
                tooltip: l.deleteAll,
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _confirmClearAll(
                  context,
                  ref,
                  favorites.length,
                ),
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: const Icon(Icons.live_tv),
                text: label('Live', count(ContentType.live)),
              ),
              Tab(
                icon: const Icon(Icons.movie),
                text: label('Films', count(ContentType.vod)),
              ),
              Tab(
                icon: const Icon(Icons.tv),
                text: label('Séries', count(ContentType.series)),
              ),
              Tab(
                icon: const Icon(Icons.replay),
                text: label('Replay', count(ContentType.replay)),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LiveFavoritesTab(),
            _VodFavoritesTab(),
            _SeriesFavoritesTab(),
            _ReplayFavoritesTab(),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmClearAll(
  BuildContext context,
  WidgetRef ref,
  int total,
) async {
  final l = AppLocalizations.of(context);
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
      title: Text(l.deleteAllConfirm),
      content: Text(
        'Retirer les $total favoris enregistrés ? '
        'La liste des favoris sera vidée.',
      ),
      actions: [
        Focus(
          focusNode: cancelFocus,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
              Navigator.pop(dialogContext, false);
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
            onPressed: () => Navigator.pop(dialogContext, false),
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
              Navigator.pop(dialogContext, true);
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
          child: FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.deleteAll),
          ),
        ),
      ],
    ),
  );
  cancelFocus.dispose();
  confirmFocus.dispose();
  if (confirmed == true && context.mounted) {
    await ref.read(favoritesProvider.notifier).clearAll();
  }
}

class _LiveFavoritesTab extends ConsumerWidget {
  const _LiveFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.live)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: l.noFavoriteChannels,
        message:
            'Appuie sur le cœur d\'une chaîne dans le Live pour la retrouver ici.',
      );
    }

    final channelsAsync = ref.watch(liveChannelsProvider);
    final byId = <String, Channel>{
      for (final c in channelsAsync.value ?? const <Channel>[])
        if (c.id.isNotEmpty) c.id: c,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final channel = byId[entry.id];
        return Dismissible(
          key: ValueKey('fav-live-${entry.key}'),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          onDismissed: (_) {
            ref
                .read(favoritesProvider.notifier)
                .removeEntry(ContentType.live, entry.id);
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChannelTile(
              title: entry.title,
              icon: Icons.live_tv,
              subtitle: channel?.groupLabel ?? entry.subtitle,
              imageUrl: (channel?.logoUrl.isNotEmpty ?? false)
                  ? channel!.logoUrl
                  : null,
              trailing: FavoriteToggle(
                entry: entry,
                showMessage: false,
              ),
              onTap: () {
                context.push(
                  '/player',
                  extra: PlayerRouteData(
                    streamUrl: (channel?.streamUrl.isNotEmpty ?? false)
                        ? channel!.streamUrl
                        : entry.streamUrl,
                    title: entry.title,
                    channels: channel != null ? [channel] : const [],
                    contentType: PlaybackContentType.live,
                    posterUrl:
                        entry.posterUrl.isNotEmpty ? entry.posterUrl : null,
                    subtitle: entry.subtitle.isNotEmpty ? entry.subtitle : null,
                    favorite: entry,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Fond visible pendant un geste « glisser pour retirer ».
class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _VodFavoritesTab extends ConsumerWidget {
  const _VodFavoritesTab();

  /// Films téléchargés et lisibles hors-ligne, les plus récents d'abord.
  ///
  /// Ce sont des favoris **virtuels** : rien n'est écrit dans les favoris
  /// manuels, la liste dérive du gestionnaire de téléchargements.
  static List<DownloadTask> _downloaded(WidgetRef ref) {
    // `const []` donnerait un LUB `List<dynamic>` et le `sort`échouerait
    // (« (dynamic, dynamic) => dynamic is not a subtype of
    // (DownloadTask, DownloadTask) => int ») : on type explicitement.
    final tasks =
        ref.watch(downloadTasksStreamProvider).value ?? const <DownloadTask>[];
    final completed = tasks
        .where((t) => t.contentType == 'vod' && t.isCompleted && t.isFileExists)
        .toList();
    completed.sort((a, b) => b.id.compareTo(a.id));
    return completed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final manual = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.vod)
        .toList()
        .reversed
        .toList();
    final downloads = _downloaded(ref);

    if (manual.isEmpty && downloads.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: l.noFavoriteMovies,
        message:
            'Appuie sur le cœur d\'un film dans la section Films pour le retrouver ici.',
      );
    }

    final moviesAsync = ref.watch(moviesProvider);
    final byId = <String, Movie>{
      for (final m in moviesAsync.value ?? const <Movie>[])
        if (m.id.isNotEmpty) m.id: m,
    };

    // Les téléchargements sans fiche en catalogue (hors-ligne) passent en
    // premier : c'est ce que l'utilisateur cherche quand il n'a plus réseau.
    final items = <_VodFavoriteItem>[
      for (final t in downloads)
        _VodFavoriteItem.downloaded(
          task: t,
          movie: byId[t.mediaItemId],
        ),
      for (final e in manual)
        _VodFavoriteItem.manual(entry: e, movie: byId[e.id]),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TvFocus(
          onActivate: () => _open(context, item),
          child: MediaCard(
            title: item.title,
            posterUrl: item.posterUrl,
            year: item.year,
            genre: item.genre,
            rating: item.rating,
            ageLabel: item.ageLabel,
            fallbackIcon: Icons.movie_outlined,
            favoriteOverlay: item.entry == null
                ? null
                : FavoriteToggle.overlay(entry: item.entry!),
            onTap: () => _open(context, item),
            isNew: item.isNew,
            topBadge: item.isDownloaded ? _downloadedBadge(context) : null,          ),
        );
      },
    );
  }

  static Widget _downloadedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Hors ligne',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, _VodFavoriteItem item) {
    final movie = item.movie;
    // Un téléchargementCompleted est prioritaire : on lit le fichier local.
    if (item.task != null && item.task!.isFileExists) {
      context.push(
        '/player',
        extra: PlayerRouteData(
          streamUrl: item.task!.fullLocalPath,
          title: item.title,
          contentType: PlaybackContentType.vod,
          posterUrl: item.posterUrl.isNotEmpty ? item.posterUrl : null,
          subtitle: 'Hors ligne',
        ),
      );
      return;
    }
    if (movie != null) {
      context.push('/vod/detail', extra: movie);
      return;
    }
    final entry = item.entry;
    if (entry == null) return;
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: entry.streamUrl,
        title: entry.title,
        contentType: PlaybackContentType.vod,
        posterUrl: entry.posterUrl.isNotEmpty ? entry.posterUrl : null,
        subtitle: entry.subtitle.isNotEmpty ? entry.subtitle : null,
        favorite: entry,
      ),
    );
  }
}

/// Entrée de la grille VOD : favori manuel ou téléchargement hors-ligne.
class _VodFavoriteItem {
  _VodFavoriteItem.manual({required this.entry, required this.movie})
      : task = null;

  _VodFavoriteItem.downloaded({required this.task, required this.movie})
      : entry = null;

  final FavoriteEntry? entry;
  final DownloadTask? task;
  final Movie? movie;

  bool get isDownloaded => task != null;

  String get title =>
      movie?.title ?? (task?.title ?? entry?.title ?? '');

  String get posterUrl {
    final fromMovie = movie?.posterUrl;
    if (fromMovie != null && fromMovie.isNotEmpty) return fromMovie;
    final fromTask = task?.posterUrl;
    if (fromTask != null && fromTask.isNotEmpty) return fromTask;
    return entry?.posterUrl ?? '';
  }

  int get year => movie?.year ?? 0;
  String get genre => movie?.genre ?? '';
  double get rating => movie?.rating ?? 0;
  String? get ageLabel => movie?.pegiLabel;
  bool get isNew => movie?.isNew ?? false;
}

class _SeriesFavoritesTab extends ConsumerWidget {
  const _SeriesFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.series)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: l.noFavoriteSeries,
        message: 'Appuie sur le cœur d\'une série pour la retrouver ici.',
      );
    }

    final seriesAsync = ref.watch(seriesProvider);
    final byId = <String, Series>{
      for (final s in seriesAsync.value ?? const <Series>[])
        if (s.id.isNotEmpty) s.id: s,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final series = byId[entry.id];
        return TvFocus(
          onActivate: () => _openSeries(context, entry, series),
          child: MediaCard(
            title: series?.title ?? entry.title,
            posterUrl: series?.coverUrl ?? entry.posterUrl,
            year: series?.year ?? 0,
            genre: series?.genre ?? '',
            rating: series?.rating ?? 0,
            ageLabel: series?.pegiLabel,
            fallbackIcon: Icons.tv,
            favoriteOverlay: FavoriteToggle.overlay(entry: entry),
            onTap: () => _openSeries(context, entry, series),
            isNew: series?.isNew ?? false,
          ),
        );
      },
    );
  }

  void _openSeries(BuildContext context, FavoriteEntry entry, Series? series) {
    if (series == null) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.seriesUnavailableTemporarily),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      return;
    }
    context.push(
      '/series/detail?id=${Uri.encodeComponent(series.id)}'
      '&title=${Uri.encodeComponent(series.title)}',
    );
  }
}

class _ReplayFavoritesTab extends ConsumerWidget {
  const _ReplayFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.replay)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: l.noFavoriteReplays,
        message: 'Appuie sur le cœur d\'un replay pour le retrouver ici.',
      );
    }

    final replaysAsync = ref.watch(replaysProvider);
    final byId = <String, ReplayItem>{
      for (final r in replaysAsync.value ?? const <ReplayItem>[])
        if (r.id.isNotEmpty) r.id: r,
    };

    return ListView.builder(
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final replay = byId[entry.id];
        final streamUrl = (replay?.streamUrl.isNotEmpty ?? false)
            ? replay!.streamUrl
            : entry.streamUrl;
        return Dismissible(
          key: ValueKey('fav-replay-${entry.key}'),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          onDismissed: (_) {
            ref
                .read(favoritesProvider.notifier)
                .removeEntry(ContentType.replay, entry.id);
          },
          child: ListTile(
            leading: const Icon(Icons.replay),
            title: Text(replay?.title ?? entry.title),
            subtitle: Text(
              replay != null
                  ? '${replay.startTime} - ${replay.endTime}'
                  : (entry.subtitle.isNotEmpty ? entry.subtitle : 'Replay'),
            ),
            trailing: FavoriteToggle(
              entry: entry,
              showMessage: false,
            ),
            onTap: () {
              context.push(
                '/player',
                extra: PlayerRouteData(
                  streamUrl: streamUrl,
                  title: replay?.title ?? entry.title,
                  contentType: PlaybackContentType.replay,
                  posterUrl:
                      entry.posterUrl.isNotEmpty ? entry.posterUrl : null,
                  subtitle: (replay != null
                              ? '${replay.startTime} - ${replay.endTime}'
                              : entry.subtitle)
                          .isNotEmpty
                      ? (replay != null
                          ? '${replay.startTime} - ${replay.endTime}'
                          : entry.subtitle)
                      : null,
                  favorite: entry,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
