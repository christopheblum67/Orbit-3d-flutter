import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/core/utils/error_handler.dart';
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
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';
import 'package:orbit_3d_flutter/services/radio_service.dart';
import 'package:orbit_3d_flutter/services/notification_service.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/services/rust_proxy_manager.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';
import 'package:orbit_3d_flutter/services/omdb_service.dart';
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';
import 'package:orbit_3d_flutter/services/search_service.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/services/connectivity_monitor.dart';
import 'package:orbit_3d_flutter/services/host_circuit_breaker.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
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
export 'profile_type_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
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

final searchServiceProvider = Provider<SearchService>((ref) {
  final service = SearchService(
    api: ref.watch(apiServiceProvider),
    storage: ref.watch(storageServiceProvider),
    tmdb: ref.watch(tmdbServiceProvider),
    tvmaze: ref.watch(tvmazeServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final searchProvider =
    FutureProvider.family<UnifiedSearchResult, String>((ref, query) async {
  if (query.trim().isEmpty) return UnifiedSearchResult.empty();
  return ref.watch(searchServiceProvider).search(query);
});

final searchFilteredProvider = FutureProvider.family<UnifiedSearchResult,
    ({String query, SearchType? filterType})>((ref, params) async {
  if (params.query.trim().isEmpty) return UnifiedSearchResult.empty();
  return ref
      .watch(searchServiceProvider)
      .search(params.query, filterType: params.filterType);
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

final currentProfileProvider = NotifierProvider<CurrentProfileNotifier, UserProfile?>(
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

final liveChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final sub = await ref
      .watch(activeSubscriptionProvider.future)
      .catchError((_) => null);
  if (sub == null) return const <Channel>[];
  final api = ref.watch(apiServiceProvider);
  return api.fetchLiveChannels();
});

final moviesProvider = FutureProvider<List<Movie>>((ref) async {
  final sub = await ref
      .watch(activeSubscriptionProvider.future)
      .catchError((_) => null);
  if (sub == null) return const <Movie>[];
  final api = ref.watch(apiServiceProvider);
  return api.fetchMovies();
});

/// Catégories Live TV extraites des group-titres M3U (pour playlists M3U)
final liveCategoriesFromM3UProvider =
    FutureProvider<List<MediaCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final sub = await ref.watch(activeSubscriptionProvider.future);
  if (sub == null || sub.type != SubscriptionType.m3u) return const [];
  final channels = await api.fetchLiveChannels();
  final groups = <String>{};
  for (final c in channels) {
    if (c.group.isNotEmpty) groups.add(c.group);
  }
  return groups.map((g) => MediaCategory(id: g, name: g)).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

final vodCategoriesProvider = FutureProvider<List<MediaCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  // Dépend de l'abonnement actif pour recharger les catégories VOD
  final sub = await ref.watch(activeSubscriptionProvider.future);
  if (sub == null || sub.type != SubscriptionType.xtream) return const [];
  return api.fetchVodCategories();
});

final seriesCategoriesProvider =
    FutureProvider<List<MediaCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider.future);
  return api.fetchSeriesCategories();
});

final seriesProvider = FutureProvider<List<Series>>((ref) async {
  final sub = await ref
      .watch(activeSubscriptionProvider.future)
      .catchError((_) => null);
  if (sub == null) return const <Series>[];
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeries();
});

final seriesInfoProvider =
    FutureProvider.family<Series, String>((ref, seriesId) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeriesInfo(seriesId);
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

final radioChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final sub = await ref
      .watch(activeSubscriptionProvider.future)
      .catchError((_) => null);
  if (sub == null) return const <Channel>[];
  final api = ref.watch(apiServiceProvider);
  return api.fetchRadioChannels();
});

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

final replaysProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  // Changement d'abonnement actif => le cache n'est plus valable
  // (dépendance de re-fetch, la valeur elle-même ne nous sert pas ici).
  ref.watch(activeSubscriptionProvider.future);
  return replaysCache.fetch(api.fetchReplays);
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

  /// Retourne les programmes (triés par horaire) d'une chaîne, sans aucun
  /// re-parcours de la liste globale. Vide si le cache n'est pas encore chargé
  /// ou si la chaîne n'a pas d'entrées EPG.
  List<EPGProgram> programsForChannel(String channelId) =>
      _byChannel[channelId] ?? const <EPGProgram>[];

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
    // Ne conserve que les programmes à venir (48 h) : l'XMLTV draap contient
    // ~94 000 entrées, inutile de les garder toutes en mémoire pour la grille.
    final now = DateTime.now();
    _all = programs
        .where(
          (p) =>
              p.end.isAfter(now) &&
              p.end.isBefore(now.add(const Duration(hours: 48))),
        )
        .toList();
    // Index par chaîne, trié par horaire : recherches dichotomiques O(log N).
    _byChannel.clear();
    for (final p in _all!) {
      (_byChannel[p.channelId] ??= <EPGProgram>[]).add(p);
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

/// EPG d'une chaîne

/// EPG d'une chaîne (par son `epg_channel_id`), chargé paresseusement puis
/// mis en cache avec une expiration. Renvoie une liste vide si la chaîne
/// n'a pas d'identifiant EPG ou aucun programme à venir.
final channelEpgProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, epgChannelId) async {
    if (epgChannelId.isEmpty) return const <EPGProgram>[];
    final api = ref.watch(apiServiceProvider);
    final cache = ref.watch(epgDataCacheProvider);
    await cache.loadFull(api);
    final now = DateTime.now();
    // L'index construit par le cache (trié par horaire) évite un re-parcours
    // de la liste globale (48 h) à chaque chaîne demandée.
    return cache
        .programsForChannel(epgChannelId)
        .where((p) => p.end.isAfter(now))
        .toList();
  },
);

class EPGProgramsNotifier extends AsyncNotifier<List<EPGProgram>> {
  @override
  Future<List<EPGProgram>> build() async {
    final api = ref.watch(apiServiceProvider);
    final cache = ref.watch(epgDataCacheProvider);
    try {
      // Passe par le cache partagé : aucune redondance avec la grille EPG
      // (un seul fetch XMLTV global). La mise en garde retry garde la
      // robustesse anti-leech draap.
      return await stream_helpers.retryStream(
        () => cache.loadFull(api),
        attempts: 2,
      );
    } catch (error, stackTrace) {
      ErrorHandler.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: 'EPG',
      );
      rethrow;
    }
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
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'orbit_last_refresh',
      timestamp.toIso8601String(),
    );
  } catch (_) {
    // Non bloquant.
  }
}

Future<DateTime?> loadLastRefresh() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('orbit_last_refresh');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  } catch (_) {
    return null;
  }
}
