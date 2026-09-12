import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:collection/collection.dart';

const int kMatchmakingLimit = 50;

/// Page d'affichage des onglets Films / Séries (chargement infini).
const int kMatchmakingPageSize = 50;

/// Plafond de recommandations conservées par onglet (plusieurs pages de 50).
const int kMatchmakingTabLimit = 200;

/// Score unifié d'un film ou d'une série vis-à-vis des genres favoris.
class ScoredReco {
  ScoredReco(
    this.reco,
    this.score,
    this.favCount,
    this.avgRating, {
    this.affinity = 0,
  });

  final Recommendation reco;
  final int score;
  final int favCount;
  final double avgRating;

  /// Affinité normalisée (0.0 → 1.0), renseignée pour les classements d'onglets.
  final double affinity;
}

/// Score un contenu (film ou série) par rapport aux genres favoris.
ScoredReco scoreContent(Recommendation reco, List<String> favorites) {
  final titleLower = reco.title.toLowerCase();
  final genresStr = reco.genre.toLowerCase();
  final descLower = reco.description.toLowerCase();

  var favCount = 0;
  var score = 0;

  for (final rawFav in favorites) {
    final fav = rawFav.toLowerCase();
    final inGenre = genresStr.contains(fav);
    final inTitle = inGenre || titleLower.contains(fav);
    final inDesc = descLower.contains(fav);
    if (inGenre) score += 3;
    if (inTitle) score += 1;
    if (inDesc && !inGenre) score += 1;
    if (inGenre || inTitle || inDesc) favCount++;
  }

  final ratingBonus = reco.rating >= 7 ? 2 : (reco.rating >= 5 ? 1 : 0);
  return ScoredReco(reco, score + ratingBonus, favCount, reco.rating);
}

/// Scoring direct d'un [Movie].
ScoredReco scoreMovie(Movie m, List<String> favorites) => scoreContent(
      Recommendation(kind: RecommendationKind.movie, movie: m),
      favorites,
    );

/// Scoring direct d'une [Series].
ScoredReco scoreSeries(Series s, List<String> favorites) => scoreContent(
      Recommendation(kind: RecommendationKind.series, series: s),
      favorites,
    );

/// Trie et filtre les recommandations par pertinence.
///
/// - Tri principal : score décroissant, puis nombre de favoris, puis note.
/// - Si [favorites] est vide : retourne les contenus ayant une note ≥ 6 ou
///   un score > 0 (aperçu raisonnable plutôt que rien).
/// - Sinon : ne retient que les contenus ayant au moins un genre matché,
///   avec une variété entre films/séries.
List<Recommendation> rankRecommendations({
  required List<Movie> movies,
  required List<Series> series,
  required List<String> favorites,
}) {
  final recos = <ScoredReco>[
    ...movies.map((m) => scoreMovie(m, favorites)),
    ...series.map((s) => scoreSeries(s, favorites)),
  ];

  recos.sort((a, b) {
    final s = b.score.compareTo(a.score);
    if (s != 0) return s;
    final f = b.favCount.compareTo(a.favCount);
    if (f != 0) return f;
    return b.avgRating.compareTo(a.avgRating);
  });

  if (favorites.isEmpty) {
    return recos
        .where((e) => e.avgRating >= 6 || e.score > 0)
        .take(kMatchmakingLimit)
        .map((e) => e.reco)
        .toList();
  }

  final chosen = <Recommendation>[];
  for (final e in recos) {
    if (e.favCount <= 0) continue;
    if (chosen.length >= kMatchmakingLimit) break;
    chosen.add(e.reco);
  }
  return chosen;
}

/// Provider Riverpod qui combine films + séries avec scoring + filtre genres session.
final matchmakingProvider = FutureProvider.autoDispose
    .family<List<Recommendation>, String>((ref, profileId) async {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null || profile.id != profileId) {
    return const <Recommendation>[];
  }

  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];
  final series = ref.watch(seriesProvider).valueOrNull ?? const <Series>[];
  if (movies.isEmpty && series.isEmpty) return const <Recommendation>[];

  final favorites = profile.favoriteGenres
      .map((g) => g.trim().toLowerCase())
      .where((g) => g.isNotEmpty)
      .toList();

  // Filtre genres session (OR logic)
  final sessionFilters = ref.watch(matchmakingGenreFilterProvider)
      .map((g) => g.trim().toLowerCase())
      .where((g) => g.isNotEmpty)
      .toSet();

  final ranked = rankRecommendations(
    movies: movies,
    series: series,
    favorites: favorites,
  );

  // Si pas de filtre session, on retourne tout le classement
  if (sessionFilters.isEmpty) return ranked;

  // Filtre OR : au moins un genre sélectionné correspond au genre du contenu
  return ranked.where((reco) {
    final recoGenre = reco.genre.toLowerCase();
    return sessionFilters.any((f) => recoGenre.contains(f));
  }).toList();
});

// ---------------------------------------------------------------------------
// Session genre filters (OR logic, per-subscription, session-only)
// ---------------------------------------------------------------------------

/// Genres sélectionnés pour filtrer les recommandations (session-only, OR logic).
class MatchmakingGenreFilterNotifier extends StateNotifier<Set<String>> {
  MatchmakingGenreFilterNotifier() : super(const <String>{});

  void toggle(String genre) {
    if (state.contains(genre)) {
      state = {...state}..remove(genre);
    } else {
      state = {...state, genre};
    }
  }

  void clear() {
    state = const <String>{};
  }
}

final matchmakingGenreFilterProvider =
    StateNotifierProvider<MatchmakingGenreFilterNotifier, Set<String>>((ref) {
  return MatchmakingGenreFilterNotifier();
});

// ---------------------------------------------------------------------------
// Dismissed / seen recommendations (persisted per profile via StorageService)
// ---------------------------------------------------------------------------

/// Ensemble d'ids de recommandations marquées (retirées ou déjà vues) par profil.
class RecoFlagIdsNotifier extends StateNotifier<Set<String>> {
  RecoFlagIdsNotifier(this._storage, this._profileId, this._flagKey)
      : super(const <String>{}) {
    final raw = _storage.getSetting('${_flagKey}_$_profileId');
    if (raw is List) {
      state = raw.cast<String>().toSet();
    }
  }

  final StorageService _storage;
  final String _profileId;
  final String _flagKey;

  Future<void> add(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    await _storage.setSetting('${_flagKey}_$_profileId', state.toList());
  }
}

AutoDisposeStateNotifierProviderFamily<RecoFlagIdsNotifier, Set<String>, String>
    _recoFlagProvider(String flagKey) {
  return StateNotifierProvider.autoDispose
      .family<RecoFlagIdsNotifier, Set<String>, String>(
    (ref, profileId) {
      final storage = ref.watch(storageServiceProvider);
      return RecoFlagIdsNotifier(storage, profileId, flagKey);
    },
  );
}

/// Recommandations retirées par l'utilisateur (long-press → « Retirer »).
final dismissedRecoIdsProvider = _recoFlagProvider('dismissed_recos');

/// Recommandations marquées « Déjà vu » par l'utilisateur.
final seenRecoIdsProvider = _recoFlagProvider('seen_recos');

// ---------------------------------------------------------------------------
// Matchmaking multi-profil (comparaison « En duo » avec % d'affinité)
// ---------------------------------------------------------------------------

/// Affinité normalisée (0.0 → 1.0) d'un contenu pour un profil donné.
///
/// Chaque genre favori : +1.0 s'il apparaît dans le genre, +0.6 dans le titre,
/// +0.4 dans la description. Bonus de note si rating ≥ 5 (petit) ou ≥ 7.
/// Sans genres favoris : signal faible fondé sur la note uniquement.
double profileAffinity(Recommendation reco, List<String> favorites) {
  final title = reco.title.toLowerCase();
  final genre = reco.genre.toLowerCase();
  final desc = reco.description.toLowerCase();

  if (favorites.isEmpty) {
    return (reco.rating / 20).clamp(0.0, 0.5).toDouble();
  }

  var sum = 0.0;
  for (final raw in favorites) {
    final fav = raw.trim().toLowerCase();
    if (fav.isEmpty) continue;
    if (genre.contains(fav)) {
      sum += 1.0;
    } else if (title.contains(fav)) {
      sum += 0.6;
    } else if (desc.contains(fav)) {
      sum += 0.4;
    }
  }

  final ratingBoost = reco.rating >= 7 ? 0.08 : (reco.rating >= 5 ? 0.03 : 0.0);
  return (sum / favorites.length + ratingBoost).clamp(0.0, 1.0).toDouble();
}

/// Affinité enrichie par signaux profils : favoris (+), déjà vues (exclusion)
/// et correspondance TMDB « recommandation » (ex-FlixPatrol, boost faible).
double profileAffinityWithSignals(
  Recommendation reco,
  List<String> favorites, {
  Set<String> favoriteIds = const {},
  Set<String> seenIds = const {},
  Set<String> tmdbTitles = const {},
}) {
  if (seenIds.contains(reco.id)) return 0.0;
  var a = profileAffinity(reco, favorites);
  if (favoriteIds.contains(reco.id)) a = (a + 0.15).clamp(0.0, 1.0);
  final normTitle = reco.title.trim().toLowerCase();
  if (tmdbTitles.contains(normTitle)) a = (a + 0.08).clamp(0.0, 1.0);
  return a;
}

/// Normalise un titre pour la correspondance TMDB (cas, espaces).
String _normTitle(String title) => title.trim().toLowerCase();

/// Groupe de profils à comparer (2 à 4 identifiants).
typedef ProfileGroup = List<String>;

/// Contenu scoré pour un groupe de profils.
class GroupReco {
  GroupReco({
    required this.reco,
    required this.affinities,
  });

  final Recommendation reco;
  final List<double> affinities; // Une affinité par profil

  /// Affinité moyenne de tous les profils.
  double get combined => affinities.isEmpty
      ? 0.0
      : affinities.reduce((a, b) => a + b) / affinities.length;

  /// Chevauchement des goûts : produit des affinités (élevé si TOUS apprécient).
  double get overlap => affinities.fold(1.0, (a, b) => a * b);

  /// Affinité minimale (le maillon faible du groupe).
  double get minAffinity => affinities.isEmpty ? 0.0 : affinities.reduce((a, b) => a < b ? a : b);
}

/// Classement « En groupe » : films + séries scorés par affinité pour N profils.
///
/// Le groupe est identifié par une liste d'ids. Les contenus déjà
/// retirés ou marqués « Déjà vu » par l'un des profils sont exclus.
/// Tri : affinité moyenne, puis chevauchement, puis affinité min, puis note.
final matchmakingGroupProvider = FutureProvider.autoDispose
    .family<List<GroupReco>, ProfileGroup>((ref, group) async {
  return _computeGroupScored(ref, group).take(kMatchmakingLimit).toList();
});

// ---------------------------------------------------------------------------
// Onglets Films / Séries : scoring enrichi + pagination par type
// ---------------------------------------------------------------------------

/// Genres favoris nettoyés (lowercase, non vides).
List<String> _cleanedGenres(List<String> genres) => genres
    .map((g) => g.trim().toLowerCase())
    .where((g) => g.isNotEmpty)
    .toList();

/// Set d'ids de contenu favori d'un type donné pour le profil courant.
Set<String> _favoriteIdsOf(Ref ref, ContentType type) {
  final favs = ref.watch(favoritesProvider);
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return const {};
  return favs.values
      .where((e) => e.type == type && e.profileId == profile.id)
      .map((e) => e.id)
      .toSet();
}

/// Titres normalisés issus des classements TMDB (ex-FlixPatrol) ; sert de
/// signal « recommandation » pour le boost d'affinité dans les onglets.
final recommendationTitlesProvider = Provider<Set<String>>((ref) {
  final titles = <String>{};
  final providers = [
    flixPatrolMoviesProvider,
    flixPatrolTvProvider,
    flixPatrolTrendingMoviesProvider,
    flixPatrolTrendingTvProvider,
    flixPatrolTopRatedMoviesProvider,
    flixPatrolTopRatedTvProvider,
  ];
  for (final p in providers) {
    final list = ref.watch(p).valueOrNull ?? const <TmdbRankEntry>[];
    for (final e in list) {
      final t = _normTitle(e.title);
      if (t.isNotEmpty) titles.add(t);
    }
  }
  return titles;
});

/// Tri par affinité (à plat) pour une liste de recommandations d'un type donné.
List<ScoredReco> _rankByAffinity({
  required List<Recommendation> recos,
  required List<String> favoriteGenres,
  required Set<String> favoriteIds,
  required Set<String> seenIds,
  required Set<String> tmdbTitles,
  Set<String> sessionFilters = const {},
  required int limit,
}) {
  final scored = <ScoredReco>[];
  for (final r in recos) {
    if (sessionFilters.isNotEmpty) {
      final recoGenre = r.genre.toLowerCase();
      if (!sessionFilters.any((f) => recoGenre.contains(f))) continue;
    }
    final aff = profileAffinityWithSignals(
      r,
      favoriteGenres,
      favoriteIds: favoriteIds,
      seenIds: seenIds,
      tmdbTitles: tmdbTitles,
    );
    if (aff <= 0) continue;
    scored.add(ScoredReco(
      r,
      (aff * 100).round(),
      0,
      r.rating,
      affinity: aff,
    ),);
  }
  scored.sort((a, b) {
    final c = b.affinity.compareTo(a.affinity);
    if (c != 0) return c;
    return b.avgRating.compareTo(a.avgRating);
  });
  return scored.take(limit).toList();
}

/// Résultat paginé pour un onglet : films et séries triés séparément.
typedef TabMatchmaking = ({
  List<ScoredReco> movies,
  List<ScoredReco> series,
});

/// Résultat paginé pour un onglet « En groupe » : films et séries avec affinité groupe.
typedef GroupTabMatchmaking = ({
  List<GroupReco> movies,
  List<GroupReco> series,
});

/// Films + séries classés par affinité profil (onglets Films / Séries, mode « Pour vous »).
final matchmakingTabProvider = FutureProvider.autoDispose
    .family<TabMatchmaking, String>((ref, profileId) async {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null || profile.id != profileId) {
    return (movies: const <ScoredReco>[], series: const <ScoredReco>[]);
  }

  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];
  final series = ref.watch(seriesProvider).valueOrNull ?? const <Series>[];
  if (movies.isEmpty && series.isEmpty) {
    return (movies: const <ScoredReco>[], series: const <ScoredReco>[]);
  }

  final favoriteGenres = _cleanedGenres(profile.favoriteGenres);
  final sessionFilters = ref
      .watch(matchmakingGenreFilterProvider)
      .map((g) => g.trim().toLowerCase())
      .where((g) => g.isNotEmpty)
      .toSet();

  final seenIds = ref.watch(seenRecoIdsProvider(profileId));
  final tmdbTitles = ref.watch(recommendationTitlesProvider);

  final scoredMovies = _rankByAffinity(
    recos: movies
        .map((m) => Recommendation(kind: RecommendationKind.movie, movie: m))
        .toList(),
    favoriteGenres: favoriteGenres,
    favoriteIds: _favoriteIdsOf(ref, ContentType.vod),
    seenIds: seenIds,
    tmdbTitles: tmdbTitles,
    sessionFilters: sessionFilters,
    limit: kMatchmakingTabLimit,
  );

  final scoredSeries = _rankByAffinity(
    recos: series
        .map((s) => Recommendation(kind: RecommendationKind.series, series: s))
        .toList(),
    favoriteGenres: favoriteGenres,
    favoriteIds: _favoriteIdsOf(ref, ContentType.series),
    seenIds: seenIds,
    tmdbTitles: tmdbTitles,
    sessionFilters: sessionFilters,
    limit: kMatchmakingTabLimit,
  );

  return (movies: scoredMovies, series: scoredSeries);
});

/// Score complet « groupe » : version non tronquée pour les onglets (pagination 50).
/// Supporte 2 à 4 profils.
List<GroupReco> _computeGroupScored(Ref ref, ProfileGroup group) {
  if (group.length < 2 || group.length > 4) return const [];

  final profiles =
      ref.watch(profilesProvider).valueOrNull ?? const <UserProfile>[];
  final selectedProfiles = <UserProfile>[];
  for (final id in group) {
    final p = profiles.firstWhereOrNull((p) => p.id == id);
    if (p != null) {
      selectedProfiles.add(p);
    }
  }
  if (selectedProfiles.length != group.length) return const [];

  List<String> favoritesOf(UserProfile p) => p.favoriteGenres
      .map((g) => g.trim().toLowerCase())
      .where((g) => g.isNotEmpty)
      .toList();

  // Collecter tous les IDs dismiss/seen du groupe
  final allDismissed = <String>{};
  final allSeen = <String>{};
  for (final id in group) {
    allDismissed.addAll(ref.watch(dismissedRecoIdsProvider(id)));
    allSeen.addAll(ref.watch(seenRecoIdsProvider(id)));
  }
  final tmdbTitles = ref.watch(recommendationTitlesProvider);

  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];
  final series = ref.watch(seriesProvider).valueOrNull ?? const <Series>[];
  if (movies.isEmpty && series.isEmpty) return const [];

  final scored = <GroupReco>[];
  void consider(Recommendation reco) {
    if (allDismissed.contains(reco.id)) return;

    final affinities = <double>[];
    for (final profile in selectedProfiles) {
      final favs = favoritesOf(profile);
      final aff = profileAffinityWithSignals(
        reco,
        favs,
        seenIds: allSeen,
        tmdbTitles: tmdbTitles,
      );
      affinities.add(aff);
    }

    // Exclure si toutes les affinités sont nulles
    if (affinities.every((a) => a <= 0)) return;

    scored.add(GroupReco(reco: reco, affinities: affinities));
  }

  for (final m in movies) {
    consider(Recommendation(kind: RecommendationKind.movie, movie: m));
  }
  for (final s in series) {
    consider(Recommendation(kind: RecommendationKind.series, series: s));
  }

  scored.sort((x, y) {
    final c = y.combined.compareTo(x.combined);
    if (c != 0) return c;
    final o = y.overlap.compareTo(x.overlap);
    if (o != 0) return o;
    final m = y.minAffinity.compareTo(x.minAffinity);
    if (m != 0) return m;
    return y.reco.rating.compareTo(x.reco.rating);
  });

  return scored;
}

/// Films + séries « En groupe » avec affinité (mode onglet, pagination 50).
final matchmakingGroupTabProvider = FutureProvider.autoDispose
    .family<GroupTabMatchmaking, ProfileGroup>((ref, group) async {
  final scored = _computeGroupScored(ref, group);
  final movies = scored
      .where((p) => p.reco.kind == RecommendationKind.movie)
      .toList();
  final series = scored
      .where((p) => p.reco.kind == RecommendationKind.series)
      .toList();
  return (movies: movies, series: series);
});
