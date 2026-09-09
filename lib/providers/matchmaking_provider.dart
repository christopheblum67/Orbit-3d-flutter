import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

const int kMatchmakingLimit = 24;

/// Score unifié d'un film ou d'une série vis-à-vis des genres favoris.
class ScoredReco {
  ScoredReco(this.reco, this.score, this.favCount, this.avgRating);

  final Recommendation reco;
  final int score;
  final int favCount;
  final double avgRating;
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

  final dismissedA =
      ref.watch(dismissedRecoIdsProvider(pair.a));
  final dismissedB =
      ref.watch(dismissedRecoIdsProvider(pair.b));
  final seenA = ref.watch(seenRecoIdsProvider(pair.a));
  final seenB = ref.watch(seenRecoIdsProvider(pair.b));

  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];
  final series = ref.watch(seriesProvider).valueOrNull ?? const <Series>[];
  if (movies.isEmpty && series.isEmpty) return const [];

  final scored = <PairedReco>[];
  void consider(Recommendation reco) {
    if (dismissedA.contains(reco.id) ||
        dismissedB.contains(reco.id) ||
        seenA.contains(reco.id) ||
        seenB.contains(reco.id)) {
      return;
    }
    final a = profileAffinity(reco, favsA);
    final b = profileAffinity(reco, favsB);
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

  return scored.take(kMatchmakingLimit).toList();
});
