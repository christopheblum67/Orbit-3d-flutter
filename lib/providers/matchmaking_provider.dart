import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

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

/// Paire de profils à comparer (identifiants).
typedef ProfilePair = ({String a, String b});

/// Contenu scoré pour une paire de profils.
class PairedReco {
  PairedReco({
    required this.reco,
    required this.affinityA,
    required this.affinityB,
  });

  final Recommendation reco;
  final double affinityA;
  final double affinityB;

  /// Affinité moyenne des deux profils.
  double get combined => (affinityA + affinityB) / 2;

  /// Chevauchement des goûts : élevé quand LES DEUX apprécient le contenu.
  double get overlap => affinityA * affinityB;
}

/// Classement « En duo » : films + séries scorés par affinité pour deux profils.
///
/// La paire est identifiée par un record `(a: idA, b: idB)`. Les contenus déjà
/// retirés ou marqués « Déjà vu » par l'un des deux profils sont exclus.
/// Tri : affinité moyenne, puis chevauchement, puis note.
final matchmakingPairProvider = FutureProvider.autoDispose
    .family<List<PairedReco>, ProfilePair>((ref, pair) async {
  return _computePairScored(ref, pair).take(kMatchmakingLimit).toList();
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
    ));
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

/// Résultat paginé pour un onglet « En duo » : films et séries avec affinité duo.
typedef PairTabMatchmaking = ({
  List<PairedReco> movies,
  List<PairedReco> series,
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

/// Score complet « duo » : version non tronquée pour les onglets (pagination 50).
List<PairedReco> _computePairScored(Ref ref, ProfilePair pair) {
  final profiles =
      ref.watch(profilesProvider).valueOrNull ?? const <UserProfile>[];
  UserProfile? profileA;
  UserProfile? profileB;
  for (final p in profiles) {
    if (p.id == pair.a) profileA = p;
    if (p.id == pair.b) profileB = p;
  }
  if (profileA == null || profileB == null) return const [];

  List<String> favoritesOf(UserProfile p) => p.favoriteGenres
      .map((g) => g.trim().toLowerCase())
      .where((g) => g.isNotEmpty)
      .toList();

  final favsA = favoritesOf(profileA);
  final favsB = favoritesOf(profileB);

  final dismissedA = ref.watch(dismissedRecoIdsProvider(pair.a));
  final dismissedB = ref.watch(dismissedRecoIdsProvider(pair.b));
  final seenA = ref.watch(seenRecoIdsProvider(pair.a));
  final seenB = ref.watch(seenRecoIdsProvider(pair.b));
  final seenAll = {...seenA, ...seenB};
  final tmdbTitles = ref.watch(recommendationTitlesProvider);

  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];
  final series = ref.watch(seriesProvider).valueOrNull ?? const <Series>[];
  if (movies.isEmpty && series.isEmpty) return const [];

  final scored = <PairedReco>[];
  void consider(Recommendation reco) {
    if (dismissedA.contains(reco.id) || dismissedB.contains(reco.id)) return;
    final a = profileAffinityWithSignals(
      reco,
      favsA,
      seenIds: seenAll,
      tmdbTitles: tmdbTitles,
    );
    final b = profileAffinityWithSignals(
      reco,
      favsB,
      seenIds: seenAll,
      tmdbTitles: tmdbTitles,
    );
    if (a + b <= 0) return;
    scored.add(PairedReco(reco: reco, affinityA: a, affinityB: b));
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
    return y.reco.rating.compareTo(x.reco.rating);
  });

  return scored;
}

/// Films + séries « En duo » avec affinité (mode onglet, pagination 50).
final matchmakingPairTabProvider = FutureProvider.autoDispose
    .family<PairTabMatchmaking, ProfilePair>((ref, pair) async {
  final scored = _computePairScored(ref, pair);
  final movies = scored
      .where((p) => p.reco.kind == RecommendationKind.movie)
      .toList();
  final series = scored
      .where((p) => p.reco.kind == RecommendationKind.series)
      .toList();
  return (movies: movies, series: series);
});
