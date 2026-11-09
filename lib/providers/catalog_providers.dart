import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_compact.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_compact.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/catalog_retry_policy.dart';
import 'package:orbit_3d_flutter/providers/content_filter_provider.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';

final m3uPlaylistProvider = FutureProvider<M3uPlaylist>(
  (ref) async {
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null || sub.type != SubscriptionType.m3u) {
      return const M3uPlaylist(
        channels: <Channel>[],
        radios: <Channel>[],
        movies: <Movie>[],
        series: <Series>[],
      );
    }
    final url = sub.m3uUrl;
    if (url == null || url.isEmpty) {
      throw StateError('L’URL de la playlist M3U est manquante.');
    }
    return ref.watch(apiServiceProvider).fetchM3uPlaylist(url);
  },
  retry: catalogRetryUnlessRateLimited,
);

/// Clé de masquage d'une chaîne live : l'identifiant de catégorie du panel, ou
/// à défaut le libellé de groupe (playlists M3U sans identifiant).
String liveCategoryKey(Channel c) =>
    c.categoryId.isNotEmpty ? c.categoryId : c.groupLabel;

/// Chaînes live NON filtrées par le masquage de catégories (sert aux réglages).
final liveChannelsAllProvider = FutureProvider<List<Channel>>(
  (ref) async {
    final filter = ref.watch(contentFilterProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Channel>[];
    if (sub.type == SubscriptionType.m3u) {
      final playlist = await ref.watch(m3uPlaylistProvider.future);
      return filter.visibleList(playlist.channels);
    }
    final api = ref.watch(apiServiceProvider);
    return filter.visibleList(await api.fetchLiveChannels());
  },
  retry: catalogRetryUnlessRateLimited,
);

final liveChannelsProvider = FutureProvider<List<Channel>>(
  (ref) async {
    final all = await ref.watch(liveChannelsAllProvider.future);
    final hidden = ref.watch(
      vodCategoryFilterProvider.select((f) => f.hiddenLiveCategoryIds),
    );
    if (hidden.isEmpty) return all;
    return all
        .where((c) => !hidden.contains(liveCategoryKey(c)))
        .toList(growable: false);
  },
);

final moviesProvider = FutureProvider<List<Movie>>(
  (ref) async {
    final filter = ref.watch(contentFilterProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Movie>[];
    if (sub.type == SubscriptionType.m3u) {
      return traceCatalogStep('vod', 'playlist', () async {
        final playlist = await ref.watch(m3uPlaylistProvider.future);
        return filter.visibleList(playlist.movies);
      });
    }
    final api = ref.watch(apiServiceProvider);
    // Journalisation explicite des deux étapes : « erreur de chargement » dans
    // la section Films pouvait venir soit du réseau, soit du parsing
    // (`filter.visibleList`), et rien ne le distinguait. On trace donc chacune.
    final result = await safeAsync<List<Movie>>(
      () => traceCatalogStep('vod', 'provider_fetch', api.fetchMovies),
      context: 'moviesProvider.fetch',
    );
    if (result.isFailure) {
      LoggerService.instance.error(
        'moviesProvider: échec réseau '
        '(${result.valueOrNull?.length ?? 0} films) : ${result.errorOrNull}',
        tag: 'vod',
        error: result.errorOrNull,
      );
      throw result.errorOrNull!;
    }
    final hiddenVod = ref.watch(
      vodCategoryFilterProvider.select((f) => f.hiddenVodCategoryIds),
    );
    final fetched = result.valueOrNull ?? const <Movie>[];
    // Les catégories masquées ne sont pas gardées en mémoire (TV 2 Go).
    final movies = hiddenVod.isEmpty
        ? fetched
        : fetched
            .where((m) => !hiddenVod.contains(m.categoryId))
            .toList(growable: false);
    try {
      return filter.visibleList(movies);
    } catch (e, st) {
      LoggerService.instance.error(
        'moviesProvider: échec du filtrage sur ${movies.length} films',
        tag: 'vod',
      );
      LoggerService.instance.error('$st', tag: 'vod');
      rethrow;
    }
  },
  retry: catalogRetryUnlessRateLimited,
);

/// Catégories Live TV extraites des group-titres M3U (pour playlists M3U)
final liveCategoriesFromM3UProvider =
    FutureProvider<List<MediaCategory>>((ref) async {
  final sub = ref.watch(activeSubscriptionProvider);
  if (sub == null || sub.type != SubscriptionType.m3u) return const [];
  final playlist = await ref.watch(m3uPlaylistProvider.future);
  return _m3uCategories(playlist.channels.map((item) => item.categoryId));
});

final vodCategoriesProvider = FutureProvider<List<MediaCategory>>(
  (ref) async {
    final api = ref.watch(apiServiceProvider);
    // Dépend de l'abonnement actif pour recharger les catégories VOD
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const [];
    if (sub.type == SubscriptionType.m3u) {
      final playlist = await ref.watch(m3uPlaylistProvider.future);
      return _m3uCategories(playlist.movies.map((item) => item.categoryId));
    }
    return api.fetchVodCategories();
  },
  retry: catalogRetryUnlessRateLimited,
);

final seriesCategoriesProvider = FutureProvider<List<MediaCategory>>(
  (ref) async {
    final api = ref.watch(apiServiceProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const [];
    if (sub.type == SubscriptionType.m3u) {
      final playlist = await ref.watch(m3uPlaylistProvider.future);
      return _m3uCategories(playlist.series.map((item) => item.categoryId));
    }
    return api.fetchSeriesCategories();
  },
  retry: catalogRetryUnlessRateLimited,
);

final seriesProvider = FutureProvider<List<Series>>(
  (ref) async {
    final filter = ref.watch(contentFilterProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Series>[];
    if (sub.type == SubscriptionType.m3u) {
      return traceCatalogStep('series', 'playlist', () async {
        final playlist = await ref.watch(m3uPlaylistProvider.future);
        return filter.visibleList(playlist.series);
      });
    }
    final api = ref.watch(apiServiceProvider);
    final hiddenSeries = ref.watch(
      vodCategoryFilterProvider.select((f) => f.hiddenSeriesCategoryIds),
    );
    final fetched = await traceCatalogStep('series', 'provider_fetch', api.fetchSeries);
    return filter.visibleList(
      hiddenSeries.isEmpty
          ? fetched
          : fetched
              .where((s) => !hiddenSeries.contains(s.categoryId))
              .toList(growable: false),
    );
  },
  retry: catalogRetryUnlessRateLimited,
);

final seriesInfoProvider =
    FutureProvider.autoDispose.family<Series, String>((ref, seriesId) async {
  final sub = ref.watch(activeSubscriptionProvider);
  if (sub?.type == SubscriptionType.m3u) {
    final playlist = await ref.watch(m3uPlaylistProvider.future);
    final series = playlist.series;
    for (final item in series) {
      if (item.id == seriesId) return item;
    }
    throw StateError('Série M3U introuvable dans la playlist.');
  }
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeriesInfo(seriesId);
});

// ==================== CATALOGUES COMPACTS (économie RAM) ====================
//
// `moviesProvider` / `seriesProvider` exposent les modèles complets (URL de
// stream, description, cast) : ~13 Mo d'URL pour 100k films. Les écrans de
// navigation n'ont besoin que du poster, du titre, de l'année, de la note et
// de la catégorie, on projection donc d'abord en [MovieCompact] /
// [SeriesCompact] avant de rendre la liste au widget.

/// Films projetés en modèle compact pour la navigation.
final moviesCompactProvider = FutureProvider<List<MovieCompact>>((ref) async {
  final movies = await ref.watch(moviesProvider.future);
  return movies.map(MovieCompact.fromMovie).toList(growable: false);
});

/// Séries projetées en modèle compact pour la navigation.
final seriesCompactProvider = FutureProvider<List<SeriesCompact>>((ref) async {
  final series = await ref.watch(seriesProvider.future);
  return series.map(SeriesCompact.fromSeries).toList(growable: false);
});

List<MediaCategory> _m3uCategories(Iterable<String> categoryIds) {
  final counts = <String, int>{};
  for (final id in categoryIds) {
    if (id.isNotEmpty) {
      counts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  return counts.entries
      .map(
        (entry) => MediaCategory(
          id: entry.key,
          name: entry.key,
          count: entry.value,
        ),
      )
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

final radioChannelsProvider = FutureProvider<List<Channel>>(
  (ref) async {
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Channel>[];
    if (sub.type == SubscriptionType.m3u) {
      final playlist = await ref.watch(m3uPlaylistProvider.future);
      return playlist.radios;
    }
    final api = ref.watch(apiServiceProvider);
    return api.fetchRadioChannels();
  },
  retry: catalogRetryUnlessRateLimited,
);
