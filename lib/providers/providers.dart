import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/services/epg_data_cache.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/content_filter_provider.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

export 'package:orbit_3d_flutter/services/epg_data_cache.dart';
export 'package:orbit_3d_flutter/services/replay_cache.dart';
export 'package:orbit_3d_flutter/services/epg_resolver_service.dart'
    show epgResolverServiceProvider;
export 'metadata_providers.dart';
export 'subtitle_providers.dart';
export 'epg_fallback_budget_provider.dart';
export 'refresh_state_providers.dart';
export 'search_providers.dart';
export 'replay_providers.dart';
export 'download_providers.dart';
export 'enrichment_providers.dart';
export 'catchup_providers.dart';
export 'epg_providers.dart';
export 'catalog_providers.dart';
export 'core_providers.dart' hide sourceTypeProvider;
export 'profile_type_provider.dart';
export 'content_filter_provider.dart';
export 'subscription_provider.dart';

final cloudflareSessionProvider =
    Provider<CloudflareSessionManager>((ref) => CloudflareSessionManager());

final sourceTypeProvider = FutureProvider<String?>((ref) async {
  final subscription = ref.watch(activeSubscriptionProvider);
  return subscription?.type.name;
});

final localSimilarMoviesProvider = FutureProvider.autoDispose
    .family<List<Movie>, ({String excludeId, String genre})>((ref, args) async {
  final genres = args.genre
      .toLowerCase()
      .split(RegExp(r'[,|/]'))
      .map((genre) => genre.trim())
      .where((genre) => genre.isNotEmpty)
      .toSet();
  if (genres.isEmpty) return const <Movie>[];
  final movies = await ref.watch(moviesProvider.future);
  final matches = <Movie>[];
  for (final movie in movies) {
    if (movie.id == args.excludeId) continue;
    final genre = movie.genre.toLowerCase();
    if (genres.any(genre.contains)) matches.add(movie);
    if (matches.length == 60) break;
  }
  return matches;
});

final m3uMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final sub = ref.watch(activeSubscriptionProvider);
  if (sub == null || sub.type != SubscriptionType.m3u) return const <Movie>[];
  return ref.watch(moviesProvider.future);
});

final m3uSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final sub = ref.watch(activeSubscriptionProvider);
  if (sub == null || sub.type != SubscriptionType.m3u) return const <Series>[];
  final filter = ref.watch(contentFilterProvider);
  final series = await ref.watch(seriesProvider.future);
  if (filter.isPermissive) return series;
  final visible = <Series>[];
  for (final show in series) {
    final episodes = [
      for (final episode in show.episodes)
        if (!filter.isHiddenChannel(_m3uEpisodeChannel(show, episode))) episode,
    ];
    if (show.episodes.isNotEmpty && episodes.isEmpty) continue;
    visible.add(
      Series(
        id: show.id,
        title: show.title,
        description: show.description,
        coverUrl: show.coverUrl,
        year: show.year,
        genre: show.genre,
        director: show.director,
        rating: show.rating,
        pegi: show.pegi,
        episodes: episodes,
        categoryId: show.categoryId,
        addedDate: show.addedDate,
        lastModifiedDate: show.lastModifiedDate,
      ),
    );
  }
  return visible;
});

Channel _m3uEpisodeChannel(Series show, Episode episode) => Channel(
      id: episode.id,
      name: episode.title,
      logoUrl: show.coverUrl,
      streamUrl: episode.streamUrl,
      group: show.genre,
      categoryId: show.categoryId,
    );

final movieChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final filter = ref.watch(contentFilterProvider);
  final movies = await ref.watch(m3uMoviesProvider.future);
  return filter.visibleList([
    for (final movie in movies)
      Channel(
        id: movie.id,
        name: movie.title,
        logoUrl: movie.posterUrl,
        streamUrl: movie.streamUrl,
        group: movie.genre,
        categoryId: movie.categoryId,
      ),
  ]);
});

final seriesChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final filter = ref.watch(contentFilterProvider);
  final series = await ref.watch(m3uSeriesProvider.future);
  return filter.visibleList([
    for (final show in series)
      for (final episode in show.episodes)
        _m3uEpisodeChannel(show, episode),
  ]);
});

final vodChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final movies = await ref.watch(movieChannelsProvider.future);
  final series = await ref.watch(seriesChannelsProvider.future);
  return [...movies, ...series];
});

final refreshM3uCategoriesProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(m3uPlaylistProvider);
    ref.invalidate(liveCategoriesFromM3UProvider);
    ref.invalidate(vodCategoriesProvider);
    ref.invalidate(seriesCategoriesProvider);
  };
});

extension EpgDataCacheForcedRefresh on EPGDataCache {
  Future<List<EPGProgram>> forceRefresh(ApiService api) =>
      loadFull(api, forceRefresh: true);
}

class StreamAiException implements Exception {
  const StreamAiException(this.message);

  final String message;

  @override
  String toString() => message;
}
