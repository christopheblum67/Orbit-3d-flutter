import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/vpn_service.dart';
import 'package:orbit_3d_flutter/services/subscription_manager.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';
import 'package:orbit_3d_flutter/services/radio_service.dart';
import 'package:orbit_3d_flutter/services/notification_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';
import 'package:orbit_3d_flutter/services/rust_proxy_manager.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';
import 'package:orbit_3d_flutter/services/omdb_service.dart';
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';
import 'package:orbit_3d_flutter/services/search_service.dart';
import 'package:orbit_3d_flutter/services/search_index_service.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';
import 'package:orbit_3d_flutter/services/host_circuit_breaker.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';
import 'package:orbit_3d_flutter/services/analytics_service.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_compact.dart';
import 'package:orbit_3d_flutter/models/series_compact.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/models/person.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/content_filter_provider.dart';
export 'profile_type_provider.dart';
export 'content_filter_provider.dart';
export 'subscription_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final service = AnalyticsService();
  ref.onDispose(service.init);
  return service;
});

// Certificate Pinning - applique la config des réglages avancés au service API
final certificatePinningInitializerProvider = Provider<void>((ref) {
  final settings = ref.watch(advancedSettingsProvider);
  if (settings.certificatePinningEnabled &&
      settings.certificatePinningFingerprints.isNotEmpty) {
    ApiService.setCertificateFingerprints(
      settings.certificatePinningFingerprints.toSet(),
    );
  } else {
    ApiService.setCertificateFingerprints(null);
  }
});

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final vpnServiceProvider = Provider<VpnService>((ref) => VpnService());
final subscriptionManagerProvider =
    Provider<SubscriptionManager>((ref) => SubscriptionManager());
final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());
final recentlyWatchedServiceProvider =
    Provider<RecentlyWatchedService>((ref) => RecentlyWatchedService());
final watchedEpisodesServiceProvider =
    Provider<WatchedEpisodesService>((ref) => WatchedEpisodesService());
final radioServiceProvider = Provider<RadioService>((ref) => RadioService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
final playbackProgressServiceProvider =
    Provider<PlaybackProgressService>((ref) => PlaybackProgressService());
final mediaLibraryManagerProvider =
    Provider<MediaLibraryManager>((ref) => MediaLibraryManager());

final subtitleControllerProvider = Provider<SubtitleController>((ref) {
  final controller = SubtitleController();
  ref.onDispose(controller.dispose);
  return controller;
});

// ==================== MÉTADONNÉES EXTERNES (TMDB, TVmaze, OMDB) ====================

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  final service = TmdbService();
  ref.onDispose(service.dispose);
  return service;
});

final tvmazeServiceProvider = Provider<TvmazeService>((ref) {
  final service = TvmazeService();
  ref.onDispose(service.dispose);
  return service;
});

/// Classements populaires TMDB (onglet FlixPatrol de Parcourir).
/// Changement de clé API (Réglages → override) ⇒ invalidation automatique.
/// Un provider par couple (mode, film/série) pour stockage indépendant.
final flixPatrolMoviesProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/popular', isTv: false);
  },
);

final flixPatrolTvProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/popular', isTv: true);
  },
);

final flixPatrolTrendingMoviesProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/trending/movie/week', isTv: false);
  },
);

final flixPatrolTrendingTvProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/trending/tv/week', isTv: true);
  },
);

final flixPatrolTopRatedMoviesProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/top_rated', isTv: false);
  },
);

final flixPatrolTopRatedTvProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/top_rated', isTv: true);
  },
);

final flixPatrolNowPlayingMoviesProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/now_playing', isTv: false);
  },
);

final flixPatrolUpcomingMoviesProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/upcoming', isTv: false);
  },
);

final flixPatrolOnTheAirTvProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/on_the_air', isTv: true);
  },
);

final flixPatrolAiringTodayTvProvider = FutureProvider<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/airing_today', isTv: true);
  },
);

/// Enrichissement TMDB de la grille VOD : pour chaque film "pauvre" en
/// données Xtream (pas d'affiche ou note nulle), on demande un poster, une
/// note, un genre et un synopsis TMDB via UNE seule requête (`searchMovieLight`,
/// mise en cache Hive 24h). Quota borné pour respecter le rate-limit TMDB :
/// à chaque invalidation on avance d'une tranche, les films déjà enrichis
/// (ou introuvables) étant mémorisés dans le cache Hive.
final vodGridEnrichmentsProvider =
    FutureProvider<Map<String, TmdbRankEntry>>((ref) async {
  ref.watch(tmdbApiKeyOverrideProvider);
  final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
  if (movies.isEmpty) return const <String, TmdbRankEntry>{};

  const maxEnrichmentsPerPass = 30;
  final tmdb = ref.watch(tmdbServiceProvider);
  if (!tmdb.hasApiKey) return const <String, TmdbRankEntry>{};

  final result = <String, TmdbRankEntry>{};
  var enriched = 0;
  for (final movie in movies) {
    // On n'enrichit que les films vraiment dépourvus de données visuelles :
    // les autres gardent la fiche Xtream (déjà bonne).
    final needsEnrichment = movie.posterUrl.isEmpty || movie.rating <= 0;
    if (!needsEnrichment) continue;
    if (enriched >= maxEnrichmentsPerPass) break;

    final entry = await tmdb.searchMovieLight(
      movie.title,
      year: movie.year > 0 ? movie.year : null,
    );
    enriched++;
    if (entry == null) continue;
    result[movie.id] = entry;
  }
  return result;
});

/// Films similaires TMDB (pour page détail film)
final tmdbSimilarMoviesProvider =
    FutureProvider.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getSimilarMovies(tmdbId);
  },
);

/// Séries similaires TMDB (pour page détail série)
final tmdbSimilarTvProvider = FutureProvider.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getSimilarTv(tmdbId);
  },
);

/// Recommandations films TMDB
final tmdbMovieRecommendationsProvider =
    FutureProvider.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getMovieRecommendations(tmdbId);
  },
);

/// Recommandations séries TMDB
final tmdbTvRecommendationsProvider =
    FutureProvider.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getTvRecommendations(tmdbId);
  },
);

/// Détail d'une personne TMDB (bio + filmographie) pour l'écran acteur
final tmdbPersonDetailProvider =
    FutureProvider.family<PersonDetail?, int>((ref, personId) {
  ref.watch(tmdbApiKeyOverrideProvider);
  return ref.watch(tmdbServiceProvider).getPersonDetail(personId);
});

/// Recherche TMDB d'une personne par nom (acteurs hors TMDB) → ID (0 si absent)
final tmdbPersonSearchProvider = FutureProvider.family<int, String>(
  (ref, name) async {
    ref.watch(tmdbApiKeyOverrideProvider);
    final id = await ref.watch(tmdbServiceProvider).searchPerson(name);
    return id ?? 0;
  },
);

final omdbServiceProvider = Provider<OmdbService>((ref) {
  final service = OmdbService();
  ref.onDispose(service.dispose);
  return service;
});

final enrichmentServiceProvider = Provider<MetadataEnrichmentService>((ref) {
  return MetadataEnrichmentService(
    api: ref.watch(apiServiceProvider),
    tmdb: ref.watch(tmdbServiceProvider),
    tvmaze: ref.watch(tvmazeServiceProvider),
    omdb: ref.watch(omdbServiceProvider),
  );
});

// ==================== RECHERCHE UNIFIÉE ====================

/// Index plein-texte local du catalogue (VOD + Séries + Live), re-indexé
/// à chaque chargement complet des providers correspondants.
final searchIndexServiceProvider = Provider<SearchIndexService>(
  (ref) => SearchIndexService(),
);

final searchServiceProvider = Provider<SearchService>((ref) {
  final service = SearchService(
    api: ref.watch(apiServiceProvider),
    tmdb: ref.watch(tmdbServiceProvider),
    tvmaze: ref.watch(tvmazeServiceProvider),
    // Recherche locale : favoris + récemment regardé (profil courant).
    loadFavorites: () async {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return <FavoriteEntry>[];
      return ref.read(favoritesServiceProvider).loadForProfile(profile.id);
    },
    loadRecentlyWatched: () async {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return <RecentEntry>[];
      return ref
          .read(recentlyWatchedServiceProvider)
          .loadForProfile(profile.id);
    },
    // Plein-texte local : alimente l'index FTS5 (VOD + Séries + Live).
    loadCatalogue: () async {
      final movies = ref.read(moviesProvider).value ?? const <Movie>[];
      final series = ref.read(seriesProvider).value ?? const <Series>[];
      final channels =
          ref.read(liveChannelsProvider).value ?? const <Channel>[];
      return SearchCatalogue(
        movies: movies,
        series: series,
        channels: channels,
      );
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Clé de recherche normalisée : évite une entrée de cache par frappe.
///
/// Sans cela, taper « matrix » créait une entrée par fragment (« m », « ma »,
/// « mat »…), chacune déclenchant FTS + TMDB + TVmaze + Xtream. Le cache
/// gonflait indéfiniment et le réseau était martelé : la recherche paraissait
/// ne pas fonctionner.
String searchQueryKey(String query) =>
    query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final searchProvider = FutureProvider.autoDispose
    .family<UnifiedSearchResult, String>((ref, query) async {
  final normalized = searchQueryKey(query);
  if (normalized.length < 2) return UnifiedSearchResult.empty();
  // Le masquage de catégories doit aussi s'appliquer à la recherche : sans
  // cela, un contenu d'une catégorie masquée réapparaît dans les résultats de
  // recherche alors qu'il a été retiré des grilles.
  final filter = ref.watch(vodCategoryFilterProvider);
  return ref.watch(searchServiceProvider).search(
        normalized,
        hiddenVodCategoryIds: filter.hiddenVodCategoryIds.toList(),
        hiddenSeriesCategoryIds: filter.hiddenSeriesCategoryIds.toList(),
      );
});

final searchFilteredProvider = FutureProvider.autoDispose.family<
    UnifiedSearchResult,
    ({
      String query,
      SearchType? filterType,
      String? categoryId
    })>((ref, params) async {
  final normalized = searchQueryKey(params.query);
  if (normalized.length < 2) return UnifiedSearchResult.empty();
  final filter = ref.watch(vodCategoryFilterProvider);
  return ref.watch(searchServiceProvider).search(normalized,
      filterType: params.filterType,
      categoryId: params.categoryId,
      hiddenVodCategoryIds: filter.hiddenVodCategoryIds.toList(),
      hiddenSeriesCategoryIds: filter.hiddenSeriesCategoryIds.toList());
});

final searchSuggestionsProvider = StreamProvider.autoDispose
    .family<List<SearchSuggestion>, String>((ref, query) async* {
  if (query.trim().length < 2) {
    yield [];
    return;
  }
  yield* ref.watch(searchServiceProvider).suggestions(query);
});

/// Pilote le process proxy Rust local (détection du binaire, démarrage,
/// watchdog, ping `/api/proxy-status`). Singleton partagé : l'app lit
/// `manager.isReady` avant de rebaser une URL via `stream_relay`.
final rustProxyManagerProvider = Provider<RustProxyManager>((ref) {
  final manager = RustProxyManager.instance;
  ref.onDispose(manager.dispose);
  return manager;
});

/// Gestionnaire de session Cloudflare global (cookies + User-Agent) pour le zapping IPTV.
/// Initialisé au démarrage (StartupSplashScreen) et injecté dans les headers du lecteur vidéo.
final cloudflareSessionProvider = Provider<CloudflareSessionManager>((ref) {
  final manager = CloudflareSessionManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final playbackProgressProvider =
    Provider.family<PlaybackProgress?, String>((ref, id) {
  return ref.watch(playbackProgressServiceProvider).get(id);
});

final currentProfileProvider =
    NotifierProvider<CurrentProfileNotifier, UserProfile?>(
  CurrentProfileNotifier.new,
);

class CurrentProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  void setUserProfile(UserProfile? profile) => state = profile;
}

final sourceTypeProvider = FutureProvider<String?>((ref) async {
  final sub =
      await ref.watch(subscriptionManagerProvider).getActiveSubscription();
  return sub['type'];
});

final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfiles();
});

final liveChannelsProvider = FutureProvider<List<Channel>>(
  (ref) async {
    final filter = ref.watch(contentFilterProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Channel>[];
    final api = ref.watch(apiServiceProvider);
    return filter.visibleList(await api.fetchLiveChannels());
  },
  retry: _retryUnlessRateLimited,
);

/// Contexte de découverte des sous-titres pour le contenu en cours de lecture.
///
/// Renseigné par la fiche film / l'épisode avant d'ouvrir le lecteur, et lu
/// par la feuille des sous-titres pour interroger `get_vod_info` ou
/// `get_series_info`. `null` pour un flux live : les panels ne publient pas de
/// sous-titres par chaîne, et la feuille retombe alors sur la saisie manuelle.
class SubtitleContext {
  const SubtitleContext({
    required this.contentId,
    required this.isSeries,
    this.streamId = '',
  });

  final String contentId;
  final bool isSeries;

  /// Stream id brut du média lu.
  ///
  /// Pour un film, [contentId] EST le stream id. Pour une série, `series_id`
  /// ne l'est pas : la convention de nommage des sous-titres attend le stream id
  /// de l'ÉPISODE. Sans ce champ, la découverte d'une série ne peut rien
  /// synthétiser et l'écran affiche « aucune piste disponible » — un chemin
  /// mort, alors que la donnée était disponible dans l'écran de lecture.
  final String streamId;
}

/// Contexte de découverte des sous-titres, alimenté par la fiche film ou
/// l'épisode avant ouverture du lecteur.
class ActiveSubtitleContextNotifier extends Notifier<SubtitleContext?> {
  @override
  SubtitleContext? build() => null;

  void set(SubtitleContext? ctx) => state = ctx;
}

final activeSubtitleContextProvider =
    NotifierProvider<ActiveSubtitleContextNotifier, SubtitleContext?>(
  ActiveSubtitleContextNotifier.new,
);

final moviesProvider = FutureProvider<List<Movie>>(
  (ref) async {
    final filter = ref.watch(contentFilterProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Movie>[];
    final api = ref.watch(apiServiceProvider);
    // Journalisation explicite des deux étapes : « erreur de chargement » dans
    // la section Films pouvait venir soit du réseau, soit du parsing
    // (`filter.visibleList`), et rien ne le distinguait. On trace donc chacune.
    final result = await safeAsync<List<Movie>>(
      () => api.fetchMovies(),
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
    final movies = result.valueOrNull ?? const <Movie>[];
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
  retry: _retryUnlessRateLimited,
);

/// Catégories Live TV extraites des group-titres M3U (pour playlists M3U)
final liveCategoriesFromM3UProvider =
    FutureProvider<List<MediaCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final sub = ref.watch(activeSubscriptionProvider);
  if (sub == null || sub.type != SubscriptionType.m3u) return const [];
  final channels = await api.fetchLiveChannels();
  final groups = <String>{};
  for (final c in channels) {
    if (c.group.isNotEmpty) groups.add(c.group);
  }
  return groups.map((g) => MediaCategory(id: g, name: g)).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

/// Politique de relance automatique après l'échec d'un provider.
///
/// Deux problèmes distincts, deux réponses distinctes :
///
/// 1. Riverpod relance de lui-même tout provider en erreur avec un backoff
///    croissant plafonné à ~6,4 s — donc INDÉFINIMENT. Sur un 429 c'est
///    exactement la contreproductive : l'application martèle un serveur déjà
///    saturé, ce qui entretient le refus (c'était la boucle de requêtes
///    observée sur get_series_categories, une toutes les 6,5 s sans fin).
///    Un refus de quota ne se rejoue donc PAS : le passage à l'action reste à
///    l'utilisateur, via le bouton « Réessayer ».
///
/// 2. Couper toute relance supprimerait l'auto-récupération sur une coupure
///    réseau passagère, qui est le cas le plus banal. On conserve donc une
///    relance exponentielle, BORNÉE à [_maxAutoRetries] essais : elle suffit à
///    absorber un incident réseau bref sans jamais pouvoir boucler.
///
/// Retourner `null` = ne pas relancer.
Duration? _retryUnlessRateLimited(int retryCount, Object error) {
  if (ApiService.isRateLimitError(error)) return null;
  if (retryCount >= _maxAutoRetries) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}

/// Nombre de relances automatiques tolérées pour une erreur qui n'est pas un
/// refus de quota.
const int _maxAutoRetries = 3;

final vodCategoriesProvider = FutureProvider<List<MediaCategory>>(
  (ref) async {
    final api = ref.watch(apiServiceProvider);
    // Dépend de l'abonnement actif pour recharger les catégories VOD
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null || sub.type != SubscriptionType.xtream) return const [];
    return api.fetchVodCategories();
  },
  retry: _retryUnlessRateLimited,
);

final seriesCategoriesProvider = FutureProvider<List<MediaCategory>>(
  (ref) async {
    final api = ref.watch(apiServiceProvider);
    ref.watch(activeSubscriptionProvider);
    return api.fetchSeriesCategories();
  },
  retry: _retryUnlessRateLimited,
);

final seriesProvider = FutureProvider<List<Series>>(
  (ref) async {
    final filter = ref.watch(contentFilterProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Series>[];
    final api = ref.watch(apiServiceProvider);
    return filter.visibleList(await api.fetchSeries());
  },
  retry: _retryUnlessRateLimited,
);

final seriesInfoProvider =
    FutureProvider.family<Series, String>((ref, seriesId) async {
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

// ==================== DÉTAILS ENRICHIS (MovieDetail, SeriesDetail) ====================

/// Film enrichi avec métadonnées TMDB/TVmaze/OMDB/IA
final movieDetailProvider =
    FutureProvider.family<MovieDetail, Movie>((ref, movie) async {
  return ref.watch(enrichmentServiceProvider).enrichMovie(movie);
});

/// Série enrichie avec métadonnées TVmaze/TMDB/OMDB/IA
final seriesDetailProvider =
    FutureProvider.family<SeriesDetail, Series>((ref, series) async {
  return ref.watch(enrichmentServiceProvider).enrichSeries(series);
});

final radioChannelsProvider = FutureProvider<List<Channel>>(
  (ref) async {
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) return const <Channel>[];
    final api = ref.watch(apiServiceProvider);
    return api.fetchRadioChannels();
  },
  retry: _retryUnlessRateLimited,
);

/// Cache partagé des replays, avec expiration : relister les chaînes DVR
/// (get_short_epg) à chaque ouverture de l'écran Replay martèlerait le panel
/// et rendrait l'écran lent (25 chaînes × plusieurs appels).
class ReplaysCache {
  ReplaysCache();

  static const _ttl = Duration(minutes: 5);

  List<ReplayItem>? _all;
  DateTime? _fetchedAt;
  Future<List<ReplayItem>>? _inFlight;

  bool get isFresh {
    final fetched = _fetchedAt;
    return _all != null &&
        fetched != null &&
        DateTime.now().difference(fetched) < _ttl;
  }

  /// Valeur déjà en cache, SANS déclencher de chargement.
  ///
  /// `replaysProvider` s'en sert pour s'afficher tout de suite avec ce qui a
  /// déjà été sondé, pendant que la sonde tourne en tâche de fond. Appeler
  /// [fetch] ici déclencherait le chargement et rebloquerait l'écran pendant
  /// toute la sonde (jusqu'à 40 chaînes).
  List<ReplayItem>? get peek => isFresh ? _all : null;

  /// Renvoie la valeur en cache si fraîche, sinon charge via [loader] (un
  /// seul chargement à la fois, partagé entre tous les appelants).
  Future<List<ReplayItem>> fetch(
    Future<List<ReplayItem>> Function() loader,
  ) {
    if (isFresh) return Future.value(_all!);
    return _inFlight ??= loader().then(
      (items) {
        _all = items;
        _fetchedAt = DateTime.now();
        _inFlight = null;
        return items;
      },
      onError: (Object error, StackTrace stackTrace) {
        // Un échec n'est pas mis en cache : la prochaine ouverture retenté.
        _inFlight = null;
        throw error;
      },
    );
  }

  void invalidate() {
    _all = null;
    _fetchedAt = null;
  }
}

final ReplaysCache replaysCache = ReplaysCache();

/// Replays — source RAPIDE.
///
/// `get_short_epg` est plafonné à 4 entrées par les panels : il ne peut pas
/// alimenter seul un replay multi-jours. L'EPG global (XMLTV) est donc la
/// source complète, et `get_short_epg` ne sert qu'à rattraper les chaînes
/// absentes du dump — d'où la sonde séparée [replaysProbeProvider].
///
/// Cette provider n'attend QUE des données déjà chargées (EPG global, grille
/// des chaînes, cache de sonde) : elle ne déclenche aucune requête par
/// chaîne. C'est délibéré — la sonde porte sur 40 chaînes et, sérialisée par
/// [_ApiGate], elle prenait une à deux minutes. Le provider attendait cette sonde
/// avant d'afficher quoi que ce soit, donc l'écran restait en chargement
/// indéfiniment (et chaque relance relançait la sonde).
///
/// L'EPG global et la grille restent « best effort » : un 429 du panneau ne
/// doit pas faire couler l'écran, il doit le priver d'enrichissement.
final replaysProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final filter = ref.watch(contentFilterProvider);
  final api = ref.watch(apiServiceProvider);
  // Changement d'abonnement actif => le cache n'est plus valable
  // (dépendance de re-fetch, la valeur elle-même ne nous sert pas ici).
  ref.watch(activeSubscriptionProvider);

  // Ce qui a déjà été sondé, sans déclencher de chargement. `null` au premier
  // lancement : l'affichage part alors de l'EPG global seul, ce qui est déjà
  // exploitable, et la sonde viendra l'enrichir.
  final shortEpg = replaysCache.peek ?? const <ReplayItem>[];

  final epgResult = await safeAsync<List<EPGProgram>>(
    () => ref.watch(epgProgramsProvider.future),
    context: 'replaysProvider.epg',
    fallbackValue: const <EPGProgram>[],
  );
  final channelsResult = await safeAsync<List<Channel>>(
    () => ref.watch(liveChannelsProvider.future),
    context: 'replaysProvider.channels',
    fallbackValue: const <Channel>[],
  );

  final fromEpg = await api.buildReplaysFromGlobalEpg(
    programs: epgResult.valueOrNull ?? const <EPGProgram>[],
    channels: channelsResult.valueOrNull ?? const <Channel>[],
  );

  final merged = ApiService.mergeReplays(fromEpg, shortEpg);
  if (merged.isEmpty) {
    // Aucun programme, mais on a peut-être été refusé par le panneau : on le
    // dit, plutôt que d'afficher un vide muet que rien n'explique.
    LoggerService.instance.warning(
      'Replay vide court=${shortEpg.length} epg=${fromEpg.length}',
      tag: 'replay',
    );
  }
  return filter.visibleList(merged);
});

/// Replays — sonde `get_short_epg`, en TÂCHE DE FOND.
///
/// Personne ne l'attend pour afficher quoi que ce soit : l'écran se rend avec
/// [replaysProvider], puis cette sonde complète. Son résultat alimente
/// [replaysCache], et c'est l'appelant (l'écran Replay, à l'ouverture) qui
/// invalide ensuite [replaysProvider] pour que la fusion se refasse avec les
/// programmes ajoutés.
///
/// Le cache a un TTL de 5 min et une déduction en vol : la relançer à chaque
/// ouverture ne refait pas la sonde si elle vient d'aboutir.
final replaysProbeProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  return replaysCache.fetch(api.fetchReplays);
});

/// Petits cache par chaîne pour le détail Replay.
///
/// Revenir sur une chaîne déjà consultée ne doit pas coûter un appel : le panel
/// est fragile et l'utilisateur alterne entre deux chaînes. TTL court,
/// le cache est vidé au changement d'abonnement.
class _ChannelReplaysCache {
  static const _ttl = Duration(minutes: 10);

  final Map<String, List<ReplayItem>> _items = {};
  final Map<String, DateTime> _at = {};

  List<ReplayItem>? peek(String channelId) {
    final at = _at[channelId];
    if (at == null || DateTime.now().difference(at) >= _ttl) return null;
    return _items[channelId];
  }

  void put(String channelId, List<ReplayItem> items) {
    _items[channelId] = items;
    _at[channelId] = DateTime.now();
  }

  void invalidate() {
    _items.clear();
    _at.clear();
  }
}

final channelReplaysCache = _ChannelReplaysCache();

/// Replays d'**une** chaîne, chargés à la demande.
///
/// Un appel par chaîne, et un seul : c'est le point délicat du Replay. Le
/// catalogue compte plus de 1400 chaînes réplayables, donc tout ce qui sonde en
/// bloc (ce que faisait la sonde de 40 chaînes au démarrage) sature le quota du
/// panel — le 429 qui suit ne fait pas que ralentir le Replay, il vide aussi
/// l'EPG et les Films.
///
/// `autoDispose` : quitter le détail rend l'entrée au cache et libère le
/// provider, sans jamais déclencher de requête tout seul.
final channelReplaysProvider = FutureProvider.autoDispose
    .family<List<ReplayItem>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  final channels = await ref.watch(liveChannelsProvider.future);
  final channel = channels.where((c) => c.id == id).firstOrNull;
  if (channel == null) return const <ReplayItem>[];

  final cached = channelReplaysCache.peek(id);
  if (cached != null) return cached;

  final items = await api.fetchChannelReplays(channel);
  channelReplaysCache.put(id, items);
  return items;
});

final epgProgramsProvider =
    AsyncNotifierProvider<EPGProgramsNotifier, List<EPGProgram>>(
  EPGProgramsNotifier.new,
);

/// Cache partagé du guide EPG brut, avec expiration, pour éviter de
/// re-télécharger l'intégralité du XMLTV à chaque changement de chaîne.
class EPGDataCache {
  EPGDataCache();

  static const _ttl = Duration(minutes: 30);

  List<EPGProgram>? _all;
  DateTime? _fetchedAt;
  Future<List<EPGProgram>>? _inFlight;

  /// Index par `channelId` → programmes triés par horaire croissant, construit
  /// UNE seule fois au premier chargement complet (O(N)) et réutilisé par tous
  /// les appels `channelEpgProvider` : évite de re-parcourir la liste globale
  /// (48 h) à chaque chaîne demandée.
  final Map<String, List<EPGProgram>> _byChannel = {};

  /// Index de secours sur la clé normalisée (espaces retirés, minuscules).
  ///
  /// Les panels Xtream n'emploient pas toujours le même identifiant dans
  /// l'API et dans le XMLTV : `"TF1"`, `"TF1 "`, `"tf1"` désignent la même
  /// chaîne. Sans cette table, la ligne de la grille restait vide alors que le
  /// guide était disponible — d'où les trous d'affichage dans les grilles.
  final Map<String, String> _normalizedToChannelId = {};

  static String _normalizeKey(String key) =>
      key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Retourne les programmes (triés par horaire) d'une chaîne, sans aucun
  /// re-parcours de la liste globale. Vide si le cache n'est pas encore chargé
  /// ou si la chaîne n'a pas d'entrées EPG.
  List<EPGProgram> programsForChannel(String channelId) {
    final exact = _byChannel[channelId];
    if (exact != null && exact.isNotEmpty) return exact;
    final trimmed = _byChannel[channelId.trim()];
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final resolved = _normalizedToChannelId[_normalizeKey(channelId)];
    if (resolved != null) {
      final fallback = _byChannel[resolved];
      if (fallback != null) return fallback;
    }
    return const <EPGProgram>[];
  }

  /// Charge l'intégralité du guide (filtre 48 h) UNE seule fois à la fois via

  bool get isFresh {
    final fetched = _fetchedAt;
    return _all != null &&
        fetched != null &&
        DateTime.now().difference(fetched) < _ttl;
  }

  /// Charge l'intégralité du guide (filtre 48 h) UNE seule fois à la fois via
  /// un futur partagé : la grille (`_loadAllEpg`) et l'onglet Recherche
  /// (`epgProgramsProvider`) ne déclenchent chacun qu'un seul téléchargement
  /// XMLTV, jamais deux en parallèle.
  Future<List<EPGProgram>> loadFull(ApiService api) async {
    if (isFresh) return _all!;
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _fetchAndFilter(api);
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<EPGProgram>> _fetchAndFilter(ApiService api) async {
    final programs = await api.fetchEpg();
    // On borne la conservation entre le DÉBUT de la journée en cours et +48 h.
    //
    // La borne basse était « maintenant ». La grille représente une journée
    // entière (minuit → minuit) : tout ce qui s'est terminé ce matin était donc
    // jeté au chargement, et la matinée s'affichait en « aucune donnée » alors
    // que le dump XMLTV la contenait — 93 128 entrées récupérées, aucune
    // affichée. Couper à minuit couvre la journée affichée sans garder les
    // semaines précédentes contenues dans le dump.
    final now = DateTime.now();
    final dayStart = EpgDayWindow.ofNow().start;
    final horizon = now.add(const Duration(hours: 48));
    _all = programs
        .where((p) => p.end.isAfter(dayStart) && p.end.isBefore(horizon))
        .toList();
    // Index par chaîne, trié par horaire : recherches dichotomiques O(log N).
    _byChannel.clear();
    _normalizedToChannelId.clear();
    for (final p in _all!) {
      (_byChannel[p.channelId] ??= <EPGProgram>[]).add(p);
      // La clé normalisée ne remplace la clé exacte que si elle est libre :
      // deux identifiants distincts ne doivent pas fusionner par accident.
      _normalizedToChannelId.putIfAbsent(
        _normalizeKey(p.channelId),
        () => p.channelId,
      );
    }
    for (final list in _byChannel.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    _fetchedAt = now;
    return _all!;
  }

  void invalidate() {
    _all = null;
    _fetchedAt = null;
    _byChannel.clear();
  }
}

final epgDataCacheProvider = Provider<EPGDataCache>((ref) => EPGDataCache());

/// Cache des guides courts (get_short_epg) + service de précharge 7 jours (S4).
final shortEpgCacheProvider = Provider<ShortEpgCache>((ref) => ShortEpgCache());
final epgPreloadServiceProvider = Provider<EpgPreloadService>(
  (ref) => EpgPreloadService(cache: ref.watch(shortEpgCacheProvider)),
);

/// Fenêtre catch-up : on ne montre que les programmes terminés depuis 14 jours.
const Duration kCatchUpWindow = Duration(days: 14);

/// Programmes **terminés** d'une chaîne pour le rattrapage (catch-up).
///
/// Diffère de [channelEpgProvider] : l'EPG décrit l'avenir, le catch-up
/// décrit le passé. Seuls les programmes dont la fin est passée et pas trop
/// anciens ([kCatchUpWindow]) sont retournés, du plus récent au plus ancien.
final channelCatchUpProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, channelId) async {
    if (channelId.isEmpty) return const <EPGProgram>[];

    final cache = ref.read(shortEpgCacheProvider);
    final cached = cache.get(channelId);
    if (cached != null) return _pastPrograms(cached);

    final channels = ref.read(liveChannelsProvider).value ?? const <Channel>[];
    final channel = channels.cast<Channel?>().firstWhere(
          (c) => c!.id == channelId,
          orElse: () => null,
        );
    if (channel == null) return const <EPGProgram>[];

    // L'API est lue AVANT le `await` : ce provider est `autoDispose`, et si
    // l'écran se ferme pendant l'appel, le `ref` est déjà détruit. Un
    // `ref.read(...)` placé après l'attente levait alors « Cannot use the Ref
    // … after it has been disposed » — ce que le journaligrams showed quand on
    // ouvrait la grille EPG.
    final api = ref.read(apiServiceProvider);
    final result = await safeAsync<List<EPGProgram>>(
      () => api.fetchChannelEpgPrograms(channel),
      context: 'channelCatchUpProvider',
    );
    final programs = result.valueOrNull;
    if (programs == null || programs.isEmpty) return const <EPGProgram>[];

    cache.put(channelId, programs);
    return _pastPrograms(programs);
  },
);

List<EPGProgram> _pastPrograms(List<EPGProgram> programs) {
  final now = DateTime.now();
  final past = programs
      .where((p) => p.end.isBefore(now))
      .where((p) => now.difference(p.end) <= kCatchUpWindow)
      .toList()
    ..sort((a, b) => b.end.compareTo(a.end));
  return past;
}

/// Cherche une entrée du cache court pour une forme d'identifiant donnée.
///
/// Le cache est écrit sous le `stream_id` nu, alors que l'appelant peut
/// interroger la forme préfixée (`num:stream_id`) ou inversement. On tente donc
/// les deux écritures possibles à partir de l'identifiant demandé.
List<EPGProgram>? _findShortEpgForAnyCandidate(
    ShortEpgCache cache, String epgChannelId) {
  // Forme préfixée « num:stream_id » -> on tente le stream_id seul.
  final colon = epgChannelId.indexOf(':');
  if (colon > 0) {
    final bare = epgChannelId.substring(colon + 1);
    if (bare.isNotEmpty) {
      final hit = cache.get(bare);
      if (hit != null) return hit;
    }
  }
  return null;
}

/// Programmes à venir, **triés par début croissant**.
///
/// `get_short_epg` n'a aucune garantie d'ordre : certains panels livrent la
/// journée en mélange avec celle d'avant. Or `epgCurrentProgram` et
/// `epgNextProgram` localisent par dichotomie, ce qui suppose un tri. Filtrer
/// seul (`where`) conserve le désordre et la dichotomie renvoie alors un
/// programme arbitraire — souvent vide, d'où une grille EPG « vide » alors que
/// le panel répondait.
List<EPGProgram> _upcomingSorted(List<EPGProgram> programs, DateTime now) {
  return programs.where((p) => p.end.isAfter(now)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// EPG d'une chaîne (par son `epg_channel_id` ou son `stream_id`).
///
/// Hydratation à la demande : on interroge `get_short_epg` pour **cette**
/// chaîne au lieu de télécharger le dump XMLTV global (~48 h, plusieurs Mo).
/// Le résultat est mis en cache 30 min par [ShortEpgCache].
/// Renvoie une liste vide si aucun programme à venir n'est disponible.
/// Corps de résolution de l'EPG d'une chaîne, partagé par deux providers.
///
/// [includePast] change ce que l'on garde, pas la SOURCE :
/// - `false` (barre du lecteur, bouton de zapping) : uniquement ce qui est en
///   cours ou à venir ;
/// - `true` (grille EPG) : tout, passé compris.
///
/// Ce filtre était appliqué dans les TROIS branches, y compris le repli sur le
/// dump XMLTV global — qui est pourtant la seule source qui contient du passé. Une
/// grille démarrant à minuit ne pouvait donc jamais afficher les premières
/// heures de la journée : elles étaient supprimées en amont, et le comblement
/// de trous les remplaçait par un bloc « aucune donnée ».
Future<List<EPGProgram>> _resolveChannelEpg(
  Ref ref,
  String epgChannelId, {
  required bool includePast,
}) async {
  if (epgChannelId.isEmpty) return const <EPGProgram>[];

  final cache = ref.watch(shortEpgCacheProvider);
  final now = DateTime.now();
  List<EPGProgram> keep(List<EPGProgram> list) => includePast
      ? (list..sort((a, b) => a.start.compareTo(b.start)))
      : _upcomingSorted(list, now);

  // 1. Cache court (aucun réseau).
  //
  // Le cache est indexé par `stream_id` (cf. l'écriture plus bas), mais
  // l'appelant peut demander une autre forme (`num:stream_id`, ou un id
  // XMLTV). Sans cette recherche multi-clés, une requête faite avec la forme
  // préfixée relançait `get_short_epg` à chaque appel et — surtout —
  // ne bénéficiait jamais du cache : l'EPG de la buttonbar du lecteur
  // restait vide malgré un panel qui répondait.
  final cachedShort = cache.get(epgChannelId) ??
      _findShortEpgForAnyCandidate(cache, epgChannelId);
  if (cachedShort != null) {
    final kept = keep(cachedShort);
    if (kept.isNotEmpty) return kept;
  }

  // Tout ce dont le corps a besoin est lu AVANT le premier `await` : ces
  // providers sont `autoDispose`, donc un `ref` touché après une attente peut
  // déjà avoir été détruit si l'appeleur a quitté l'écran entre-temps.
  final api = ref.read(apiServiceProvider);
  final globalCache = ref.watch(epgDataCacheProvider);
  final channels = ref.read(liveChannelsProvider).value ?? const <Channel>[];
  Channel? channel;
  for (final c in channels) {
    // On compare sur TOUS les identifiants EPG possibles de la chaîne
    // (`stream_id` et `num:stream_id`) : le XMLTV de ces panels utilise la
    // forme préfixée, et ne tester qu'un seul forme faisait échouer la
    // résolution.
    if (c.id == epgChannelId || c.epgChannelIds.contains(epgChannelId)) {
      channel = c;
      break;
    }
  }
  if (channel != null) {
    final target = channel;
    final result = await safeAsync<List<EPGProgram>>(
      () => api.fetchChannelEpgPrograms(target),
      context: 'channelEpgProvider',
    );
    final programs = result.valueOrNull;
    if (programs != null && programs.isNotEmpty) {
      cache.put(target.id, programs);
      final kept = keep(programs);
      if (kept.isNotEmpty) return kept;
    }
  }

  // 3. Repli : le dump XMLTV global, chargé une seule fois et indexé.
  await globalCache.loadFull(api);

  // On essaie chaque identifiant candidat de la chaîne (forme simple et
  // forme préfixée) : le premier qui trouve des programmes gagne.
  final candidates = <String>[epgChannelId];
  final matched = channel;
  if (matched != null) {
    candidates
      ..clear()
      ..addAll(matched.epgChannelIds);
    if (matched.id.isNotEmpty) candidates.add(matched.id);
  }
  for (final candidate in candidates) {
    final found = keep(globalCache.programsForChannel(candidate).toList());
    if (found.isNotEmpty) return found;
  }
  return const <EPGProgram>[];
}

/// EPG d'une chaîne pour la barre du lecteur : uniquement « en cours » et
/// « à venir ». Voir [channelEpgWindowProvider] pour la grille.
final channelEpgProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, epgChannelId) =>
      _resolveChannelEpg(ref, epgChannelId, includePast: false),
);

/// EPG d'une chaîne pour la GRILLE : programmes passés compris.
///
/// La grille représente une journée entière ; lui fournir seulement « à venir »
/// laissait la matinée entière vide, comblée par des blocs de trou alors que le
/// dump XMLTV contenait bel et bien ces programmes.
final channelEpgWindowProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, epgChannelId) =>
      _resolveChannelEpg(ref, epgChannelId, includePast: true),
);

class EPGProgramsNotifier extends AsyncNotifier<List<EPGProgram>> {
  @override
  Future<List<EPGProgram>> build() async {
    final api = ref.watch(apiServiceProvider);
    final cache = ref.watch(epgDataCacheProvider);
    final result = await safeAsync<List<EPGProgram>>(
      // Passe par le cache partagé : aucune redondance avec la grille EPG
      // (un seul fetch XMLTV global). La mise en garde retry garde la
      // robustesse anti-leech draap.
      () => stream_helpers.retryStream(
        () => cache.loadFull(api),
        attempts: 2,
      ),
      context: 'EPGProgramsNotifier.build',
    );
    return result.getOrThrow();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

/// Moniteur de connectivité temps réel (singleton via ChangeNotifier)
final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  final monitor = ConnectivityMonitor();
  ref.onDispose(monitor.dispose);
  return monitor;
});

/// Circuit breaker par hôte (cooldown anti-leech)
final hostCircuitBreakerProvider = Provider<HostCircuitBreaker>((ref) {
  return HostCircuitBreaker.instance;
});

/// Détecteur de stall (flux figé) pendant la lecture
final stallDetectorProvider = Provider<StallDetector>((ref) {
  final detector = StallDetector();
  ref.onDispose(detector.dispose);
  return detector;
});

/// Gestionnaire de téléchargements hors-ligne
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager();
  ref.onDispose(manager.dispose);
  return manager;
});

/// Stream des tâches de téléchargement
final downloadTasksStreamProvider = StreamProvider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.tasksStream;
});

/// Nombre de téléchargements actifs
final activeDownloadsCountProvider = StreamProvider<int>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.tasksStream
      .map((tasks) => tasks.where((t) => t.isActive).length);
});

class StreamAiException implements Exception {
  const StreamAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Horodatage de la dernière mise à jour des flux (UTC), durabilisé afin
/// d'afficher « Dernière mise à jour : … » dans la barre supérieure.
final lastRefreshTimestampProvider =
    NotifierProvider<LastRefreshTimestampNotifier, DateTime?>(
  LastRefreshTimestampNotifier.new,
);

class LastRefreshTimestampNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setTimestamp(DateTime? value) => state = value;
}

Future<void> persistLastRefresh(DateTime timestamp) async {
  final result = await safeAsync<void>(
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'orbit_last_refresh',
        timestamp.toIso8601String(),
      );
    },
    context: 'persistLastRefresh',
  );
  return result.valueOrNull;
}

Future<DateTime?> loadLastRefresh() async {
  final result = await safeAsync<DateTime?>(
    () async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('orbit_last_refresh');
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    },
    context: 'loadLastRefresh',
  );
  return result.valueOrNull;
}
