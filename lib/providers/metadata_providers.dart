import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/person.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/omdb_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_api_key_store.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';

// ==================== MÉTADONNÉES EXTERNES (TMDB, TVmaze, OMDB) ====================

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  final service = TmdbService();
  ref.onDispose(service.dispose);
  return service;
});

/// Instance TMDB **dédiée** au calcul du % d'affinité (grille VOD).
///
/// File de rate-limit (`_requestTimestamps`) séparée de [tmdbServiceProvider] :
/// la résolution du genre réel d'une tuile ne peut donc plus faire attendre les
/// appels TMDB de la fiche détail (recherche du film, similaires,
/// recommandations), qui partageaient auparavant la même file.
/// Si `TMDB_API_KEY_AFFINITY` est fourni dans le fichier runtime, le quota TMDB est en
/// plus totalement distinct.
final tmdbAffinityServiceProvider = Provider<TmdbService>((ref) {
  final service = TmdbService(
    keyResolver: () => TmdbApiKeyStore.instance.affinityKey,
  );
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
///
/// `autoDispose` sur les 10 classements : chacun retenait sa
/// `List<TmdbRankEntry>` en mémoire pour toute la session dès la première
/// consultation. Les résultats sont déjà en cache Hive (`getRankings` /
/// `searchMovieLight`), donc les recharger après un aller-retour dans Parcourir
/// ne rejoue pas le réseau.
final flixPatrolMoviesProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>((ref) {
  ref.watch(tmdbApiKeyOverrideProvider);
  return ref
      .watch(tmdbServiceProvider)
      .getRankings('/movie/popular', isTv: false);
});

final flixPatrolTvProvider = FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/popular', isTv: true);
  },
);

final flixPatrolTrendingMoviesProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/trending/movie/week', isTv: false);
  },
);

final flixPatrolTrendingTvProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/trending/tv/week', isTv: true);
  },
);

final flixPatrolTopRatedMoviesProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/top_rated', isTv: false);
  },
);

final flixPatrolTopRatedTvProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/top_rated', isTv: true);
  },
);

final flixPatrolNowPlayingMoviesProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/now_playing', isTv: false);
  },
);

final flixPatrolUpcomingMoviesProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/movie/upcoming', isTv: false);
  },
);

final flixPatrolOnTheAirTvProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/on_the_air', isTv: true);
  },
);

final flixPatrolAiringTodayTvProvider =
    FutureProvider.autoDispose<List<TmdbRankEntry>>(
  (ref) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref
        .watch(tmdbServiceProvider)
        .getRankings('/tv/airing_today', isTv: true);
  },
);

/// Films similaires TMDB (pour page détail film)
final tmdbSimilarMoviesProvider =
    FutureProvider.autoDispose.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getSimilarMovies(tmdbId);
  },
);

/// Séries similaires TMDB (pour page détail série)
final tmdbSimilarTvProvider =
    FutureProvider.autoDispose.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getSimilarTv(tmdbId);
  },
);

/// Recommandations films TMDB
final tmdbMovieRecommendationsProvider =
    FutureProvider.autoDispose.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getMovieRecommendations(tmdbId);
  },
);

/// Recommandations séries TMDB
final tmdbTvRecommendationsProvider =
    FutureProvider.autoDispose.family<List<TmdbRankEntry>, int>(
  (ref, tmdbId) {
    ref.watch(tmdbApiKeyOverrideProvider);
    return ref.watch(tmdbServiceProvider).getTvRecommendations(tmdbId);
  },
);

/// Détail d'une personne TMDB (bio + filmographie) pour l'écran acteur
final tmdbPersonDetailProvider =
    FutureProvider.autoDispose.family<PersonDetail?, int>((ref, personId) {
  ref.watch(tmdbApiKeyOverrideProvider);
  return ref.watch(tmdbServiceProvider).getPersonDetail(personId);
});

/// Recherche TMDB d'une personne par nom (acteurs hors TMDB) → ID (0 si absent)
final tmdbPersonSearchProvider = FutureProvider.autoDispose.family<int, String>(
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
