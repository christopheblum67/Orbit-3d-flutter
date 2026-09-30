import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
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

// NOTE : `matchmakingProvider` et `matchmakingGroupProvider` ont été supprimés.
// Ils n'avaient aucun consommateur, et leurs `ref.keepAlive()` (dont le lien
// n'était jamais fermé) retenaient indéfiniment un scoring complet du
// catalogue. Le chemin vivant passe par `matchmakingTabProvider` et
// `matchmakingGroupTabProvider`.

// ---------------------------------------------------------------------------
// Session genre filters (OR logic, per-subscription, session-only)
// ---------------------------------------------------------------------------

/// Genres sélectionnés pour filtrer les recommandations (session-only, OR logic).
class MatchmakingGenreFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

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
    NotifierProvider<MatchmakingGenreFilterNotifier, Set<String>>(
  MatchmakingGenreFilterNotifier.new,
);

// ---------------------------------------------------------------------------
// Dismissed / seen recommendations (persisted per profile via StorageService)
// ---------------------------------------------------------------------------

/// Ensemble d'ids de recommandations marquées (retirées ou déjà vues) par profil.
class RecoFlagIdsNotifier extends Notifier<Set<String>> {
  RecoFlagIdsNotifier(this.profileId, this.flagKey);

  final String profileId;
  final String flagKey;

  @override
  Set<String> build() {
    final storage = ref.watch(storageServiceProvider);
    final raw = storage.getSetting('${flagKey}_$profileId');
    if (raw is! List) return <String>{};
    // La box Hive n'est pas typee : `cast<String>()` est paresseux mais le
    // `.toSet()` le force, et une seule valeur non-String (migration de schema,
    // version antérieure) faisait echouer ce `build()`, donc tout l'onglet de
    // matchmaking. On convertit element par element.
    final out = <String>{};
    for (final e in raw) {
      if (e == null) continue;
      final s = '$e'.trim();
      if (s.isNotEmpty) out.add(s);
    }
    return out;
  }

  Future<void> add(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting('${flagKey}_$profileId', state.toList());
  }
}

/// Recommandations retirées par l'utilisateur (long-press → « Retirer »).
final dismissedRecoIdsProvider = NotifierProvider.autoDispose
    .family<RecoFlagIdsNotifier, Set<String>, String>(
  (profileId) => RecoFlagIdsNotifier(profileId, 'dismissed_recos'),
);

/// Recommandations marquées « Déjà vu » par l'utilisateur.
final seenRecoIdsProvider = NotifierProvider.autoDispose
    .family<RecoFlagIdsNotifier, Set<String>, String>(
  (profileId) => RecoFlagIdsNotifier(profileId, 'seen_recos'),
);

// ---------------------------------------------------------------------------
// Matchmaking multi-profil (comparaison « En duo » avec % d'affinité)
// ---------------------------------------------------------------------------

/// Normalisation des genres : mappe les alias courants vers un genre canonique.
/// Ex: "horreur" → "horror", "sci-fi" → "science fiction", etc.
const Map<String, String> _genreAliases = {
  // Français → Anglais (TMDB standard)
  'horreur': 'horror',
  'épouvante': 'horror',
  'science-fiction': 'science fiction',
  'science fiction': 'science fiction',
  'sci-fi': 'science fiction',
  'sci fi': 'science fiction',
  'aventure': 'adventure',
  'animation': 'animation',
  'comedie': 'comedy',
  'comédie': 'comedy',
  'crime': 'crime',
  'documentaire': 'documentary',
  'drame': 'drama',
  'familial': 'family',
  'fantastique': 'fantasy',
  'historique': 'history',
  'musique': 'music',
  'mystere': 'mystery',
  'mystère': 'mystery',
  'romance': 'romance',
  'thriller': 'thriller',
  'guerre': 'war',
  'western': 'western',
  // Anglais → Anglais (normalisation) — seulement ceux non couverts par le français
  'horror': 'horror',
  'action': 'action',
  'adventure': 'adventure',
  'comedy': 'comedy',
  'documentary': 'documentary',
  'drama': 'drama',
  'family': 'family',
  'fantasy': 'fantasy',
  'history': 'history',
  'music': 'music',
  'mystery': 'mystery',
  'tv movie': 'tv movie',
  'tv film': 'tv movie',
};

/// Normalise un genre via la table d'alias (insensible à la casse).
String _normalizeGenre(String genre) {
  final lower = genre.trim().toLowerCase();
  return _genreAliases[lower] ?? lower;
}

/// Normalise un texte libre pour une recherche de genre dedans.
///
/// `_normalizeGenre` ramène un genre à sa forme canonique
/// (`science-fiction` -> `science fiction`). Si on ne fait pas de meme côté
/// texte, une description comme « histoire de science-fiction spatiale »
/// ne contient plus jamais « science fiction » et l'affinite tombe a zero.
String _normalizeForMatch(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[\-_]'), ' ');

// ---------------------------------------------------------------------------

/// Affinité normalisée (0.0 → 1.0) d'un contenu pour un profil donné.
///
/// Chaque genre favori : +1.0 s'il apparaît dans le genre, +0.6 dans le titre,
/// +0.4 dans la description. Bonus de note si rating ≥ 5 (petit) ou ≥ 7.
/// Sans genres favoris : signal faible fondé sur la note uniquement.
double profileAffinity(Recommendation reco, List<String> favorites) {
  final title = _normalizeForMatch(reco.title);
  final desc = _normalizeForMatch(reco.description);
  // Le genre est teste sous ses deux formes : séparateurs normalises et
  // alias canonique.
  final genreForms = <String>{
    _normalizeForMatch(reco.genre),
    _normalizeGenre(reco.genre),
  };

  if (favorites.isEmpty) {
    return (reco.rating / 20).clamp(0.0, 0.5).toDouble();
  }

  var sum = 0.0;
  for (final raw in favorites) {
    final fav = _normalizeForMatch(raw);
    if (fav.isEmpty) continue;
    // Un genre favori correspond si SON libelle d'origine OU son alias
    // canonique apparait. Canoniser un seul des deux cote voilait des
    // correspondances : « Science-Fiction » -> « science fiction » ne matchait
    // plus « science-fiction spatiale », et « Aventure » -> « adventure »
    // ne matchait plus le titre « Aventure spatiale ».
    final alias = _genreAliases[raw.trim().toLowerCase()];
    bool contains(String haystack) =>
        haystack.contains(fav) || (alias != null && haystack.contains(alias));

    if (genreForms.any(contains)) {
      sum += 1.0;
    } else if (contains(title)) {
      sum += 0.6;
    } else if (contains(desc)) {
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

/// Rend une clé de groupe **canonique** : triée, sans doublon.
ProfileGroup canonicalProfileGroup(Iterable<String> ids) {
  final set = ids.where((id) => id.isNotEmpty).toSet().toList()..sort();
  return set;
}

/// Clé de cache **scalaire** d'un groupe de profils.
///
/// Indispensable : `List<String>` a une égalité par *identité* en Dart, donc
/// chaque appel à [canonicalProfileGroup] produit une instance différente. Or
/// Riverpond indexe les providers `family` par égalité de l'argument : une
/// nouvelle liste = nouvelle entrée de cache = nouveau scoring. Dans l'onglet
/// groupe, la clé est reconstruite à chaque `build`, ce qui créait une boucle
/// « nouveau provider → loading → rebuild → nouveau provider » : l'écran
/// restait indéfiniment sur « Chargement » avec 2 profils sélectionnés.
///
/// Une chaîne triée a une égalité par valeur : le même groupe logique retombe
/// toujours sur la même entrée, quel que soit l'ordre de sélection.
String profileGroupCacheKey(Iterable<String> ids) =>
    canonicalProfileGroup(ids).join('|');

/// Relit une clé [profileGroupCacheKey] en liste d'identifiants.
ProfileGroup parseProfileGroupKey(String key) =>
    key.isEmpty ? const <String>[] : key.split('|');

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
  double get minAffinity =>
      affinities.isEmpty ? 0.0 : affinities.reduce((a, b) => a < b ? a : b);
}

/// Seuil au-delà duquel un contenu est considéré comme un « coup de cœur »
/// pour l'ensemble du groupe et doit passer devant tout le reste.
const double kStrongAffinityThreshold = 0.80;

/// Classe une liste d'affinités pour faire remonter les « coups de cœur ».
///
/// Le tri naturel reste inchangé, mais tout contenu au-dessus de
/// [kStrongAffinityThreshold] passe devant les autres, quel que soit son
/// rang initial. L'ordre relatif des éléments d'un même groupe est conservé,
/// donc le résultat reste stable et déterministe.
///
/// Sans cela, un contenu à 95 % d'affinité pouvait se retrouver derrière un
/// contenu à 60 % : le classement ne traduisait plus du tout la force réelle
/// du signal, alors que le badge affiché sur la tuile indiquait 95 %.
List<ScoredReco> prioritizeStrongAffinity(List<ScoredReco> items) {
  bool strong(ScoredReco e) => e.affinity >= kStrongAffinityThreshold;

  final strongs = items.where(strong).toList();
  final rest = items.where((e) => !strong(e)).toList();
  return <ScoredReco>[...strongs, ...rest];
}

/// Équivalent groupe de [prioritizeStrongAffinity].
///
/// Le seuil porte sur le **maillon faible** ([GroupReco.minAffinity]) et non
/// sur la moyenne : un contenu plébiscité par un seul profil (95 % / 10 %)
/// n'est pas un coup de cœur du groupe, et le faire passer devant tout le
/// reste produirait mécaniquement du contenu que la majorité du groupe
/// n'aurait jamais choisi.
List<GroupReco> prioritizeStrongGroupAffinity(List<GroupReco> items) {
  bool strong(GroupReco e) => e.minAffinity >= kStrongAffinityThreshold;

  final strongs = items.where(strong).toList();
  final rest = items.where((e) => !strong(e)).toList();
  return <GroupReco>[...strongs, ...rest];
}

/// Ancien `matchmakingGroupProvider` : supprimé (aucun consommateur, et son
/// `ref.keepAlive()` non fermé retenait ~20 Mo par permutation de groupe).
/// Le chemin vivant est `matchmakingGroupTabProvider`.

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
    final list = ref.watch(p).value ?? const <TmdbRankEntry>[];
    for (final e in list) {
      final t = _normTitle(e.title);
      if (t.isNotEmpty) titles.add(t);
    }
  }
  return titles;
});

/// Tri par affinité (à plat) pour une liste de recommandations d'un type donné.
///
/// Le catalogue fait ~100 000 entrées. Matérialiser un `ScoredReco` par entrée
/// puis trier la liste complète revenait à allouer ~100 000 objets et à faire
/// ~1,7 M comparaisons pour n'en garder que `limit` (200). On garde ici un
/// top-K : la liste ne dépasse jamais `limit + 1` éléments, le tri ne porte que
/// sur ce tas, et le rejet rapide évite le scorage des éléments déjà trop
/// mauvais (l'affinité est calculée avant, mais rien n'est stocké).
List<ScoredReco> _rankByAffinity({
  required Iterable<Recommendation> recos,
  required List<String> favoriteGenres,
  required Set<String> favoriteIds,
  required Set<String> seenIds,
  required Set<String> tmdbTitles,
  Set<String> sessionFilters = const {},
  Set<String> hiddenCategories = const {},
  required int limit,
}) {
  int byAffinity(ScoredReco a, ScoredReco b) {
    final c = b.affinity.compareTo(a.affinity);
    if (c != 0) return c;
    return b.avgRating.compareTo(a.avgRating);
  }

  final top = <ScoredReco>[];
  for (final r in recos) {
    // Catégories masquées par l'utilisateur (préférences) : on ne propose pas
    // de contenu qui ne doit pas être visible, quel que soit son score.
    if (hiddenCategories.isNotEmpty && hiddenCategories.contains(r.categoryId)) {
      continue;
    }
    if (sessionFilters.isNotEmpty) {
      // Meme normalisation que `profileAffinity`, sinon un filtre « Science
      // Fiction » ne matche jamais un genre « Science-Fiction ».
      final recoGenre = _normalizeForMatch(r.genre);
      if (!sessionFilters.any((f) => recoGenre.contains(_normalizeForMatch(f)))) {
        continue;
      }
    }
    final aff = profileAffinityWithSignals(
      r,
      favoriteGenres,
      favoriteIds: favoriteIds,
      seenIds: seenIds,
      tmdbTitles: tmdbTitles,
    );
    if (aff <= 0) continue;
    // Rejet rapide : le tas est plein et cet élément n'en fait pas mieux que
    // le pire. Evite l'allocation ET le tri.
    if (top.length >= limit && aff <= top.last.affinity) continue;
    top.add(
      ScoredReco(
        r,
        (aff * 100).round(),
        0,
        r.rating,
        affinity: aff,
      ),
    );
    if (top.length > limit) {
      top.sort(byAffinity);
      top.removeLast();
    }
  }
  top.sort(byAffinity);
  // Les « coups de cœur » (> 80 %) passent devant tout le reste, sans
  // modifier l'ordre relatif à l'intérieur de chaque groupe.
  return prioritizeStrongAffinity(top);
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

/// Calcule le pourcentage d'affinité d'un contenu pour le profil courant.
///
/// Réutilise exactement la formule du matchmaking ([profileAffinityWithSignals])
/// afin que le badge affiché sur les tuiles Films/Séries et le score de
/// l'onglet Matchmaking ne divergent jamais. Contexte résolu une seule fois
/// (genres favoris, favoris, déjà vus, titres TMDB) : le calcul par tuile reste
/// une simple comparaison de chaînes.
class ProfileAffinityScorer {
  const ProfileAffinityScorer({
    required this.favoriteGenres,
    required this.favoriteIds,
    required this.seenIds,
    required this.tmdbTitles,
  });

  final List<String> favoriteGenres;
  final Set<String> favoriteIds;
  final Set<String> seenIds;
  final Set<String> tmdbTitles;

  /// Affinité en pourcentage (0-100), prête pour [MediaCard.matchPercent].
  int percentFor(Recommendation reco) =>
      (profileAffinityWithSignals(
        reco,
        favoriteGenres,
        favoriteIds: favoriteIds,
        seenIds: seenIds,
        tmdbTitles: tmdbTitles,
      ) *
              100)
          .round();

  int percentForMovie(Movie m) =>
      percentFor(Recommendation(kind: RecommendationKind.movie, movie: m));

  int percentForSeries(Series s) =>
      percentFor(Recommendation(kind: RecommendationKind.series, series: s));
}

/// Contexte d'affinité du profil courant, ou null si aucun profil n'est actif.
///
/// Volontairement non async : il ne dépend que de données déjà chargées, donc
/// les grilles Films/Séries l'affichent sans état de chargement.
final profileAffinityScorerProvider = Provider<ProfileAffinityScorer?>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return null;

  // Union des favoris films + séries : le badge ignore le type, on ne veut
  // pas qu'un favori série fasse disparaître l'affinité d'un film.
  final favoriteIds = <String>{
    ..._favoriteIdsOf(ref, ContentType.vod),
    ..._favoriteIdsOf(ref, ContentType.series),
  };

  return ProfileAffinityScorer(
    favoriteGenres: _cleanedGenres(profile.favoriteGenres),
    favoriteIds: favoriteIds,
    seenIds: ref.watch(seenRecoIdsProvider(profile.id)),
    tmdbTitles: ref.watch(recommendationTitlesProvider),
  );
});

/// Films + séries classés par affinité profil (onglets Films / Séries, mode « Pour vous »).
final matchmakingTabProvider = FutureProvider.autoDispose
    .family<TabMatchmaking, String>((ref, profileId) async {
  ref.keepAlive();
  final profile = ref.watch(currentProfileProvider);
  if (profile == null || profile.id != profileId) {
    return (movies: const <ScoredReco>[], series: const <ScoredReco>[]);
  }

  final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
  final series = ref.watch(seriesProvider).value ?? const <Series>[];
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
  // Catégories masquées par abonnement : le matchmaking ne doit pas proposer
  // du contenu que l'utilisateur a choisi de cacher.
  final categoryFilter = ref.watch(vodCategoryFilterProvider);
  final hiddenMovies = categoryFilter.hiddenVodCategoryIds;
  final hiddenSeries = categoryFilter.hiddenSeriesCategoryIds;

  final scoredMovies = _rankByAffinity(
    // Iterable paresseux : pas de liste de 99 569 `Recommendation` en mémoire.
    recos: movies.map(
      (m) => Recommendation(kind: RecommendationKind.movie, movie: m),
    ),
    favoriteGenres: favoriteGenres,
    favoriteIds: _favoriteIdsOf(ref, ContentType.vod),
    seenIds: seenIds,
    tmdbTitles: tmdbTitles,
    sessionFilters: sessionFilters,
    hiddenCategories: hiddenMovies,
    limit: kMatchmakingTabLimit,
  );

  final scoredSeries = _rankByAffinity(
    recos: series.map(
      (s) => Recommendation(kind: RecommendationKind.series, series: s),
    ),
    favoriteGenres: favoriteGenres,
    favoriteIds: _favoriteIdsOf(ref, ContentType.series),
    seenIds: seenIds,
    tmdbTitles: tmdbTitles,
    sessionFilters: sessionFilters,
    hiddenCategories: hiddenSeries,
    limit: kMatchmakingTabLimit,
  );

  return (movies: scoredMovies, series: scoredSeries);
});


/// Contexte de scoring d'un groupe, résolu UNE FOIS avant de parcourir le
/// catalogue. Toute donnée calculée ici était auparavant recalculée à chaque
/// élément du catalogue (100 000 items x 4 profils), soit ~2,4 M allocations.
class _GroupScoreContext {
  _GroupScoreContext({
    required this.profiles,
    required this.favoritesPerProfile,
    required this.dismissed,
    required this.seen,
    required this.tmdbTitles,
    required this.hiddenMovies,
    required this.hiddenSeries,
  });

  final List<UserProfile> profiles;

  /// Genres favoris normalisés, un par profil, calculés une seule fois.
  final List<List<String>> favoritesPerProfile;
  final Set<String> dismissed;
  final Set<String> seen;
  final Set<String> tmdbTitles;

  /// Catégories masquées par abonnement, séparées par type.
  final Set<String> hiddenMovies;
  final Set<String> hiddenSeries;
}

/// Score « groupe » borné : on ne conserve que les `limit` meilleures affinités
/// au lieu de matérialiser un `GroupReco` par contenu (~20 Mo par groupe).
///
/// Les films et séries sont séparés pendant le parcours : la liste rendue ne
/// dépasse jamais `limit` éléments par type, au lieu de deux `.where().toList()`
/// sur 100 000 éléments.
({List<GroupReco> movies, List<GroupReco> series}) _computeGroupTab(
  ProfileGroup group,
  List<Movie> movies,
  List<Series> series,
  _GroupScoreContext ctx, {
  required int limit,
}) {
  int byCombined(GroupReco a, GroupReco b) {
    final c = b.combined.compareTo(a.combined);
    if (c != 0) return c;
    return b.reco.rating.compareTo(a.reco.rating);
  }

  final topMovies = <GroupReco>[];
  final topSeries = <GroupReco>[];

  void consider(Recommendation reco) {
    if (ctx.dismissed.contains(reco.id)) return;
    // Catégories masquées par l'utilisateur : jamais proposées, quel que soit
    // le score du groupe.
    if (reco.kind == RecommendationKind.movie &&
        ctx.hiddenMovies.contains(reco.categoryId)) {
      return;
    }
    if (reco.kind == RecommendationKind.series &&
        ctx.hiddenSeries.contains(reco.categoryId)) {
      return;
    }

    final affinities = List<double>.filled(ctx.profiles.length, 0);
    var anyPositive = false;
    for (var i = 0; i < ctx.profiles.length; i++) {
      final aff = profileAffinityWithSignals(
        reco,
        ctx.favoritesPerProfile[i],
        seenIds: ctx.seen,
        tmdbTitles: ctx.tmdbTitles,
      );
      affinities[i] = aff;
      if (aff > 0) anyPositive = true;
    }
    if (!anyPositive) return;

    final top = reco.kind == RecommendationKind.movie ? topMovies : topSeries;
    final entry = GroupReco(reco: reco, affinities: affinities);
    // Rejet rapide : le tas est plein et cet élément n'en fait pas mieux que
    // le pire. Evite l'allocation ET le tri.
    if (top.length >= limit && entry.combined <= top.last.combined) return;
    top.add(entry);
    if (top.length > limit) {
      top.sort(byCombined);
      top.removeLast();
    }
  }

  for (final m in movies) {
    consider(Recommendation(kind: RecommendationKind.movie, movie: m));
  }
  for (final s in series) {
    consider(Recommendation(kind: RecommendationKind.series, series: s));
  }

  topMovies.sort(byCombined);
  topSeries.sort(byCombined);
  // Même priorisation que l'onglet simple : les contenus que TOUS les profils
  // du groupe aiment (> 80 % pour le maillon faible) passent devant.
  return (
    movies: prioritizeStrongGroupAffinity(topMovies),
    series: prioritizeStrongGroupAffinity(topSeries),
  );
}

/// Films + séries « En groupe » avec affinité (mode onglet, pagination 50).
///
/// Toutes les dépendances `ref.watch` sont résolues AVANT le moindre `await` :
/// `ref.watch` après un gap asynchrone lève `UnmountedRefException` dès que le
/// provider est invalidé pendant le chargement (changement d'abonnement,
/// rafraîchissement du catalogue VOD...).
final matchmakingGroupTabProvider = FutureProvider.autoDispose
    .family<GroupTabMatchmaking, String>((ref, groupKey) async {
  // La clé est une chaîne triée (voir [profileGroupCacheKey]) : égalité par
  // valeur, donc une entrée de cache stable par groupe logique. Avec une
  // `List` en argument, le provider était recréé à chaque build et l'onglet
  // groupe restait bloqué sur « Chargement ».
  final key = parseProfileGroupKey(groupKey);
  if (key.length < 2 || key.length > 4) {
    return (movies: const <GroupReco>[], series: const <GroupReco>[]);
  }

  // --- Toutes les lectures de `ref` avant le moindre await. ---
  final profiles = ref.watch(profilesProvider).value ?? const <UserProfile>[];
  final selectedProfiles = <UserProfile>[];
  for (final id in key) {
    final p = profiles.firstWhereOrNull((p) => p.id == id);
    if (p != null) selectedProfiles.add(p);
  }
  if (selectedProfiles.length != key.length) {
    return (movies: const <GroupReco>[], series: const <GroupReco>[]);
  }

  final allDismissed = <String>{};
  final allSeen = <String>{};
  for (final id in key) {
    allDismissed.addAll(ref.watch(dismissedRecoIdsProvider(id)));
    allSeen.addAll(ref.watch(seenRecoIdsProvider(id)));
  }
  final tmdbTitles = ref.watch(recommendationTitlesProvider);
  final categoryFilter = ref.watch(vodCategoryFilterProvider);
  final moviesAsync = ref.watch(moviesProvider.future);
  final seriesAsync = ref.watch(seriesProvider.future);

  final ctx = _GroupScoreContext(
    profiles: selectedProfiles,
    favoritesPerProfile: [
      for (final p in selectedProfiles) _cleanedGenres(p.favoriteGenres),
    ],
    dismissed: allDismissed,
    seen: allSeen,
    tmdbTitles: tmdbTitles,
    hiddenMovies: categoryFilter.hiddenVodCategoryIds,
    hiddenSeries: categoryFilter.hiddenSeriesCategoryIds,
  );

  // --- A partir d'ici, plus aucun acces a `ref`. ---
  final movies = await moviesAsync.timeout(
    const Duration(seconds: 25),
    onTimeout: () => const <Movie>[],
  );
  final series = await seriesAsync.timeout(
    const Duration(seconds: 25),
    onTimeout: () => const <Series>[],
  );

  if (movies.isEmpty && series.isEmpty) {
    return (movies: const <GroupReco>[], series: const <GroupReco>[]);
  }

  return _computeGroupTab(
    key,
    movies,
    series,
    ctx,
    limit: kMatchmakingTabLimit,
  );
});
