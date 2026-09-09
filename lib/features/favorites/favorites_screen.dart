import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Écran Favoris v2 : 4 sections (Live, Films, Séries, Replay).
///
/// La liste est pilotée par [favoritesProvider] (réactif). Les cartes sont
/// résolues depuis les catalogues quand ils sont chargés, sinon les données
/// mémorisées dans l'entrée favorite suffisent à l'affichage et à la lecture.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    int count(ContentType type) =>
        favorites.values.where((e) => e.type == type).length;
    String label(String base, int n) => n > 0 ? '$base ($n)' : base;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favoris'),
          actions: [
            if (favorites.isNotEmpty)
              IconButton(
                tooltip: 'Tout supprimer',
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
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tout supprimer ?'),
      content: Text(
        'Retirer les $total favoris enregistrés ? '
        'La liste des favoris sera vidée.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tout supprimer'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(favoritesProvider.notifier).clearAll();
  }
}

class _LiveFavoritesTab extends ConsumerWidget {
  const _LiveFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.live)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucune chaîne favorite',
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
                    posterUrl: entry.posterUrl.isNotEmpty
                        ? entry.posterUrl
                        : null,
                    subtitle: entry.subtitle.isNotEmpty
                        ? entry.subtitle
                        : null,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.vod)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun film favori',
        message:
            'Appuie sur le cœur d\'un film dans la section Films pour le retrouver ici.',
      );
    }

    final moviesAsync = ref.watch(moviesProvider);
    final byId = <String, Movie>{
      for (final m in moviesAsync.value ?? const <Movie>[])
        if (m.id.isNotEmpty) m.id: m,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final movie = byId[entry.id];
        return TvFocus(
          onActivate: () => _openMovie(context, entry, movie),
          child: MediaCard(
            title: movie?.title ?? entry.title,
            posterUrl: movie?.posterUrl ?? entry.posterUrl,
            year: movie?.year ?? 0,
            genre: movie?.genre ?? '',
            rating: movie?.rating ?? 0,
            ageLabel: movie?.pegiLabel,
            fallbackIcon: Icons.movie_outlined,
            favoriteOverlay: FavoriteToggle.overlay(entry: entry),
            onTap: () => _openMovie(context, entry, movie),
            isNew: movie?.isNew ?? false,
          ),
        );
      },
    );
  }

  void _openMovie(BuildContext context, FavoriteEntry entry, Movie? movie) {
    if (movie != null) {
      context.push('/vod/detail', extra: movie);
      return;
    }
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

class _SeriesFavoritesTab extends ConsumerWidget {
  const _SeriesFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.series)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucune série favorite',
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Série indisponible pour le moment.'),
            duration: Duration(milliseconds: 1200),
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
    final entries = ref
        .watch(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.replay)
        .toList()
        .reversed
        .toList();
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun replay favori',
        message: 'Appuie sur le cœur d\'un replay pour le retrouver ici.',
      );
    }

    final replaysAsync = ref.watch(replaysProvider);
    final byId = <String, ReplayItem>{
      for (final r in replaysAsync.value ?? const <ReplayItem>[])
        if (r.id.isNotEmpty) r.id: r,
    };

    return ListView.builder(
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
