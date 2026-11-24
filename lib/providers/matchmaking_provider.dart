import 'dart:async';
import 'dart:math' as math;

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
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
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
    this.quality = 6,
  });

  final Recommendation reco;
  final int score;
  final int favCount;
  final double avgRating;

  /// Affinité normalisée (0.0 → 1.0), renseignée pour les classements d'onglets.
  final double affinity;
  final double quality;
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
  'sf': 'science fiction',
  'aventure': 'adventure',
  'animation': 'animation',
  'comedie': 'comedy',
  'comédie': 'comedy',
  'comédie dramatique': 'drama',
  'comedie dramatique': 'drama',
  'crime': 'crime',
  'documentaire': 'documentary',
  'drame': 'drama',
  'familial': 'family',
  'famille': 'family',
  'fantastique': 'fantasy',
  'historique': 'history',
  'histoire': 'history',
  'policier': 'crime',
  'suspense': 'thriller',
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
final RegExp _kMatchSeparators = RegExp(r'[\-_]');
final RegExp _kGenreSeparators = RegExp(r'[,/|&]');

String _normalizeForMatch(String text) =>
    text.toLowerCase().replaceAll(_kMatchSeparators, ' ');

final RegExp _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);
final Map<String, Set<String>> _genreTextAliases = () {
  final aliases = <String, Set<String>>{};
  for (final entry in _genreAliases.entries) {
    (aliases[entry.value] ??= <String>{})
        .add(_normalizeForMatch(entry.key));
  }
  return aliases;
}();

bool _containsGenreWord(String text, String word) {
  var start = text.indexOf(word);
  while (start >= 0) {
    final end = start + word.length;
    final left = start == 0 || !_wordCharacter.hasMatch(text[start - 1]);
    final right = end == text.length || !_wordCharacter.hasMatch(text[end]);
    if (left && right) return true;
    start = text.indexOf(word, start + 1);
  }
  return false;
}

/// Vrai si [label] est — ou contient — un genre **reconnu**, plutôt qu'un simple
/// nom de catégorie Xtream (« Récents », « Nouveautés », « Netflix », …).
///
/// Sert à décider s'il faut aller chercher le vrai genre d'une œuvre auprès de
/// TMDB : un film rangé dans une catégorie non-genre reçoit le nom de cette
/// catégorie comme `genre` (cf. `ApiService._enrichMovieListMap`), ce qui donne
/// une affinité faussement nulle. On découpe sur les séparateurs usuels pour
/// accepter « Action & Aventure », « Horreur, Thriller », etc.
bool isKnownGenreLabel(String label) {
  for (final raw in label.split(RegExp(r'[,/|&]'))) {
    final token = raw.trim().toLowerCase();
    if (token.isEmpty) continue;
    if (_genreAliases.containsKey(token)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------

/// Découpe un libellé de genre multi-valeurs (« Horreur, Fantastique, Mystère »)
/// en jetons **canoniques** (alias résolus), insensibles à la casse.
///
/// C'est le cœur du correctif d'affinité : les deux côtés (genres du film ET
/// genres favoris du profil) sont ramenés au MÊME vocabulaire AVANT de
/// comparer. Sans cela, un profil étiqueté `fantasy` (anglais) ne matchait
/// jamais un film listé `Fantastique` (français), car `_genreAliases` n'allait
/// que dans un sens (`fantastique` → `fantasy`, jamais l'inverse).
/// Les libellés de genre d'un catalogue sont peu nombreux (noms de catégories,
/// genres TMDB) mais le scoring les redécoupe pour chacun des ~130 000 titres :
/// on mémorise donc la découpe.
final Map<String, Set<String>> _genreTokenMemo = <String, Set<String>>{};

Set<String> _canonicalGenreTokens(String raw) {
  final memo = _genreTokenMemo[raw];
  if (memo != null) return memo;
  final tokens = <String>{};
  for (final part in raw.split(_kGenreSeparators)) {
    final t = part.trim().toLowerCase();
    if (t.isNotEmpty) tokens.add(_normalizeGenre(t));
  }
  if (_genreTokenMemo.length > 20000) _genreTokenMemo.clear();
  return _genreTokenMemo[raw] = tokens;
}

/// Jetons canoniques des genres favoris, calculés une fois par liste.
final Expando<Set<String>> _favTokensMemo = Expando<Set<String>>('favTokens');

Set<String> _favoriteTokens(List<String> favorites) {
  final cached = _favTokensMemo[favorites];
  if (cached != null) return cached;
  final tokens = <String>{
    for (final f in favorites) ..._canonicalGenreTokens(f),
  };
  _favTokensMemo[favorites] = tokens;
  return tokens;
}

/// Affinité normalisée (0.0 → 1.0) d'un contenu pour un profil donné.
///
/// Fondée **uniquement sur les genres déclarés du profil** — jamais sur la
/// liste des favoris, qui est vidée après visionnage et n'est donc pas un
/// signal de goût stable.
///
/// * **précision** — part des genres DU FILM que le profil aime. C'était le
///   défaut : on divisait par le nombre de genres du PROFIL (6), si bien que
///   deux genres sur trois qui matchaient ne valaient que `2/6 = 33 %`. Un film
///   de moins de 3 genres est plafonné (dénominateur mini 3) pour qu'un film
///   mono-genre ne décroche pas 100 % sur un seul match.
/// * **rappel** — part des genres favoris présents dans le film. Dampène les
///   profils très larges : 2 matchs sur 6 favoris ≠ 2 sur 2.
///
/// La précision pèse 4× le rappel : « ce film me correspond » compte plus que
/// « ce film couvre mes cases ». Leur moyenne pondérée est adoucie par
/// l'exposant 0,85 avant le bonus de note (rating ≥ 5 ou ≥ 7).
/// Sans genres favoris : signal faible fondé sur la note uniquement.
double profileAffinity(Recommendation reco, List<String> favorites) {
  if (favorites.isEmpty) {
    return (reco.rating / 20).clamp(0.0, 0.5).toDouble();
  }

  final favTokens = _favoriteTokens(favorites);
  if (favTokens.isEmpty) {
    return (reco.rating / 20).clamp(0.0, 0.5).toDouble();
  }

  final ratingBoost = reco.rating >= 7 ? 0.08 : (reco.rating >= 5 ? 0.03 : 0.0);

  final filmGenres = _canonicalGenreTokens(reco.genre);
  if (filmGenres.isEmpty) {
    // Film sans genre exploitable : repli sur titre + description.
    final text =
        '${_normalizeForMatch(reco.title)} ${_normalizeForMatch(reco.description)}';
    final touched = favTokens.where((genre) {
      final aliases = _genreTextAliases[genre] ?? {genre};
      return aliases.any((alias) => _containsGenreWord(text, alias));
    }).length;
    return ((touched / favTokens.length) * 0.5 + ratingBoost).clamp(0.0, 1.0);
  }

  final matched = filmGenres.where(favTokens.contains).length;
  final denominator = filmGenres.length < 3 ? 3 : filmGenres.length;
  final precision = matched / denominator;
  final recall = matched / favTokens.length;

  final genreRatio = (precision * 0.8) + (recall * 0.2);
  final softened = math.pow(genreRatio, 0.85).toDouble().clamp(0.0, 1.0);
  return (softened + ratingBoost).clamp(0.0, 1.0);
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
  // Le boost « présent dans la liste des favoris » (+0.15) a été retiré : cette
  // liste est vidée après visionnage, ce n'est pas un signal de goût stable.
  // Le pourcentage ne dépend donc QUE des genres déclarés du profil.
  final normTitle = reco.title.trim().toLowerCase();
  if (_favoriteTokens(favorites).isNotEmpty && tmdbTitles.contains(normTitle)) {
    a = (a + 0.08).clamp(0.0, 1.0);
  }
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
    this.quality = 6,
  });

  final Recommendation reco;
  final List<double> affinities; // Une affinité par profil
  final double quality;

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
const double kStrongAffinityThreshold = 0.75;

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
  bool strong(ScoredReco e) => e.affinity > kStrongAffinityThreshold;

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
  bool strong(GroupReco e) => e.minAffinity > kStrongAffinityThreshold;

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

final _matchmakingRankingProviders = [
  flixPatrolMoviesProvider,
  flixPatrolTvProvider,
  flixPatrolTrendingMoviesProvider,
  flixPatrolTrendingTvProvider,
  flixPatrolTopRatedMoviesProvider,
  flixPatrolTopRatedTvProvider,
];

/// Titres normalisés issus des classements TMDB (ex-FlixPatrol) ; sert de
/// signal « recommandation » pour le boost d'affinité dans les onglets.
final recommendationTitlesProvider = Provider<Set<String>>((ref) {
  final titles = <String>{};
  for (final p in _matchmakingRankingProviders) {
    final list = ref.watch(p).value ?? const <TmdbRankEntry>[];
    for (final e in list) {
      final t = _normTitle(e.title);
      if (t.isNotEmpty) titles.add(t);
    }
  }
  return titles;
});

typedef RankingGenreKey = ({String title, int year, bool isTv});

RankingGenreKey _metadataKey(String title, int year, bool isTv) =>
    (title: _normTitle(title), year: year, isTv: isTv);

/// Métadonnées vérifiées et recherches déjà tentées pendant cette session.
class AffinityMetadataNotifier extends Notifier<Map<RankingGenreKey, TmdbRankEntry>> {
  final Set<RankingGenreKey> _attempted = {};

  @override
  Map<RankingGenreKey, TmdbRankEntry> build() {
    ref.watch(tmdbApiKeyOverrideProvider);
    _attempted.clear();
    return const {};
  }

  bool wasAttempted(RankingGenreKey key) => _attempted.contains(key);

  void markAttempted(RankingGenreKey key) => _attempted.add(key);

  void addAll(Map<RankingGenreKey, TmdbRankEntry> entries) {
    if (entries.isNotEmpty) state = {...state, ...entries};
  }
}

final affinityMetadataProvider = NotifierProvider<AffinityMetadataNotifier,
    Map<RankingGenreKey, TmdbRankEntry>>(AffinityMetadataNotifier.new);

/// Métadonnées des classements et de l'enrichissement, sans identité ambiguë.
final rankingMetadataProvider =
    Provider<Map<RankingGenreKey, TmdbRankEntry>>((ref) {
  final ids = <RankingGenreKey, int>{};
  final entries = <RankingGenreKey, TmdbRankEntry>{};
  final ambiguous = <RankingGenreKey>{};
  void add(RankingGenreKey key, TmdbRankEntry entry) {
    if (key.title.isEmpty || key.year <= 0 || entry.tmdbId <= 0 ||
        ambiguous.contains(key)) return;
    if (ids.containsKey(key) && ids[key] != entry.tmdbId) {
      ambiguous.add(key);
      entries.remove(key);
      return;
    }
    ids[key] = entry.tmdbId;
    final old = entries[key];
    if (old == null ||
        (old.genreNames.isEmpty && entry.genreNames.isNotEmpty) ||
        (old.genreNames.isNotEmpty == entry.genreNames.isNotEmpty &&
            entry.voteCount > old.voteCount)) {
      entries[key] = entry;
    }
  }
  for (final provider in _matchmakingRankingProviders) {
    for (final entry in ref.watch(provider).value ?? const <TmdbRankEntry>[]) {
      add(_metadataKey(entry.title, entry.year, entry.isTv), entry);
    }
  }
  ref.watch(affinityMetadataProvider).forEach(add);
  return entries;
});

final rankingGenresProvider = Provider<Map<RankingGenreKey, String>>((ref) {
  return {
    for (final item in ref.watch(rankingMetadataProvider).entries)
      if (item.value.genreNames.isNotEmpty)
        item.key: item.value.genreNames,
  };
});

/// Une recherche prudente, étalée et limitée, uniquement pendant Matchmaking.
final affinityBackgroundEnrichmentProvider = FutureProvider.autoDispose<void>((ref) async {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return;
  ref.watch(tmdbApiKeyOverrideProvider);
  final tmdb = ref.watch(tmdbAffinityServiceProvider);
  if (!tmdb.hasApiKey) return;
  final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
  final series = ref.watch(seriesProvider).value ?? const <Series>[];
  final filters = ref.watch(vodCategoryFilterProvider);

  final store = ref.read(affinityMetadataProvider.notifier);
  final known = ref.read(rankingMetadataProvider);
  final selected = <({RankingGenreKey key, String title})>[];
  final selectedSet = <RankingGenreKey>{};
  void select(String title, int year, String genre, bool isTv) {
    if (year <= 0 || isKnownGenreLabel(genre) ||
        TmdbService.normalizeSearchTitle(title).isEmpty) return;
    final key = _metadataKey(title, year, isTv);
    if (store.wasAttempted(key) || known.containsKey(key) ||
        !selectedSet.add(key)) return;
    final cached = isTv
        ? tmdb.peekTvLight(title, year: year)
        : tmdb.peekMovieLight(title, year: year);
    if (cached != null) return;
    selected.add((key: key, title: title));
  }

  var scanned = 0;
  for (final movie in movies) {
    if (++scanned % _kYieldEvery == 0) {
      await _yieldToUi();
      if (!ref.mounted) return;
    }
    if (filters.hiddenVodCategoryIds.contains(movie.categoryId)) continue;
    select(movie.title, movie.year, movie.genre, false);
    if (selected.length >= 10) break;
  }
  final movieCount = selected.length;
  for (final item in series) {
    if (++scanned % _kYieldEvery == 0) {
      await _yieldToUi();
      if (!ref.mounted) return;
    }
    if (filters.hiddenSeriesCategoryIds.contains(item.categoryId)) continue;
    select(item.title, item.year, item.genre, true);
    if (selected.length - movieCount >= 10) break;
  }

  final pending = <RankingGenreKey, TmdbRankEntry>{};
  await Future<void>.delayed(Duration.zero);
  for (final item in selected) {
    if (!ref.mounted) break;
    final key = item.key;
    store.markAttempted(key);
    final entry = key.isTv
        ? await tmdb.searchTvLightVerified(item.title, key.year)
        : await tmdb.searchMovieLightVerified(item.title, key.year);
    if (!ref.mounted) break;
    if (entry != null && isMatchingAffinityMetadata(key, entry)) {
      pending[key] = entry;
    }
    if (pending.length >= 10) {
      if (ref.mounted) store.addAll(pending);
      pending.clear();
    }
    if (ref.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }
  store.addAll(pending);
});

bool isMatchingAffinityMetadata(RankingGenreKey key, TmdbRankEntry entry) =>
    TmdbService.normalizeSearchTitle(key.title).isNotEmpty &&
    entry.tmdbId > 0 &&
    entry.year == key.year &&
    entry.isTv == key.isTv &&
    TmdbService.normalizeSearchTitle(key.title).toLowerCase() ==
        TmdbService.normalizeSearchTitle(entry.title).toLowerCase();

/// Note bayésienne neutre en l'absence de votes vérifiables.
double affinityWeightedRating(TmdbRankEntry? entry) {
  if (entry == null || entry.voteCount <= 0 ||
      !entry.rating.isFinite || entry.rating <= 0 || entry.rating > 10) {
    return 6;
  }
  const priorVotes = 50;
  const priorRating = 6;
  return (entry.voteCount * entry.rating + priorVotes * priorRating) /
      (entry.voteCount + priorVotes);
}

double affinityQualityFor(
  Recommendation reco,
  Map<RankingGenreKey, TmdbRankEntry> metadata, {
  TmdbRankEntry? cached,
}) {
  if (reco.year <= 0) return 6;
  final key = _metadataKey(
    reco.title, reco.year, reco.kind == RecommendationKind.series,
  );
  final ranked = metadata[key];
  final verified = cached != null && isMatchingAffinityMetadata(key, cached)
      ? cached
      : null;
  if (verified != null && ranked != null &&
      verified.tmdbId != ranked.tmdbId) return 6;
  final entry = verified == null
      ? ranked
      : ranked == null || verified.voteCount >= ranked.voteCount
          ? verified
          : ranked;
  return affinityWeightedRating(entry);
}

Recommendation _withRankingGenre(
  Recommendation reco,
  Map<RankingGenreKey, String> genres,
) {
  if (reco.year <= 0 || isKnownGenreLabel(reco.genre)) return reco;
  final key = (
    title: _normTitle(reco.title),
    year: reco.year,
    isTv: reco.kind == RecommendationKind.series,
  );
  return recommendationWithRealGenre(reco, genres[key] ?? '');
}

/// Tri par affinité (à plat) pour une liste de recommandations d'un type donné.
///
/// Le catalogue fait ~100 000 entrées. Matérialiser un `ScoredReco` par entrée
/// puis trier la liste complète revenait à allouer ~100 000 objets et à faire
/// ~1,7 M comparaisons pour n'en garder que `limit` (200). On garde ici un
/// top-K : la liste ne dépasse jamais `limit + 1` éléments, le tri ne porte que
/// sur ce tas, et le rejet rapide évite le scorage des éléments déjà trop
/// mauvais (l'affinité est calculée avant, mais rien n'est stocké).
/// Rend la main à la boucle d'événements toutes les [kYieldEvery] itérations :
/// le scoring de ~100 000 titres d'un seul bloc gelait le thread UI plus de
/// 10 s sur la TV (ANR, application tuée).
const int _kYieldEvery = 1500;

Future<void> _yieldToUi() => Future<void>.delayed(Duration.zero);

Future<List<ScoredReco>> _rankByAffinity({
  required Iterable<Recommendation> recos,
  required List<String> favoriteGenres,
  required Set<String> favoriteIds,
  required Set<String> seenIds,
  required Set<String> tmdbTitles,
  Set<String> sessionFilters = const {},
  Set<String> hiddenCategories = const {},
  required int limit,
  required double Function(Recommendation) qualityFor,
}) async {
  int byAffinity(ScoredReco a, ScoredReco b) {
    final aStrong = a.affinity > kStrongAffinityThreshold;
    final bStrong = b.affinity > kStrongAffinityThreshold;
    if (aStrong != bStrong) return aStrong ? -1 : 1;
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    final quality = b.quality.compareTo(a.quality);
    if (quality != 0) return quality;
    final title = _normTitle(a.reco.title).compareTo(_normTitle(b.reco.title));
    return title != 0 ? title : a.reco.id.compareTo(b.reco.id);
  }

  final top = <ScoredReco>[];
  var visited = 0;
  for (final r in recos) {
    if (++visited % _kYieldEvery == 0) await _yieldToUi();
    // Catégories masquées par l'utilisateur (préférences) : on ne propose pas
    // de contenu qui ne doit pas être visible, quel que soit son score.
    if (hiddenCategories.isNotEmpty &&
        hiddenCategories.contains(r.categoryId)) {
      continue;
    }
    if (sessionFilters.isNotEmpty) {
      // Meme normalisation que `profileAffinity`, sinon un filtre « Science
      // Fiction » ne matche jamais un genre « Science-Fiction ».
      final recoGenre = _normalizeForMatch(r.genre);
      if (!sessionFilters
          .any((f) => recoGenre.contains(_normalizeForMatch(f)))) {
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
    final percent = (aff * 100).round();
    if (top.length >= limit) {
      final last = top.last;
      final strong = aff > kStrongAffinityThreshold;
      final lastStrong = last.affinity > kStrongAffinityThreshold;
      if ((!strong && lastStrong) ||
          (strong == lastStrong && percent < last.score)) continue;
    }
    final entry = ScoredReco(
        r,
        percent,
        0,
        r.rating,
        affinity: aff,
        quality: qualityFor(r),
    );
    if (top.length >= limit && byAffinity(entry, top.last) >= 0) continue;
    top.add(entry);
    if (top.length >= limit) {
      top.sort(byAffinity);
      if (top.length > limit) top.removeLast();
    }
  }
  top.sort(byAffinity);
  // Les « coups de cœur » (> 75 %) passent devant tout le reste, sans
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
    this.rankingGenres = const {},
    this.rankingMetadata = const {},
  });

  final List<String> favoriteGenres;
  final Set<String> favoriteIds;
  final Set<String> seenIds;
  final Set<String> tmdbTitles;
  final Map<RankingGenreKey, String> rankingGenres;
  final Map<RankingGenreKey, TmdbRankEntry> rankingMetadata;

  /// Affinité en pourcentage (0-100), prête pour [MediaCard.matchPercent].
  int percentFor(Recommendation reco) => (profileAffinityWithSignals(
            _withRankingGenre(reco, rankingGenres),
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

  double qualityFor(Recommendation reco, {TmdbRankEntry? cached}) =>
      affinityQualityFor(reco, rankingMetadata, cached: cached);
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
    rankingGenres: ref.watch(rankingGenresProvider),
    rankingMetadata: ref.watch(rankingMetadataProvider),
  );
});

/// Clé d'identité d'une demande de « vrai genre » (film).
///
/// Riverpod indexe les providers `family` par égalité d'argument : une classe
/// sans `==`/`hashCode` produirait une nouvelle entrée de cache à chaque build
/// (« nouveau provider → requête → rebuild → nouveau provider »). D'où
/// l'égalité par valeur.
class MovieGenreQuery {
  const MovieGenreQuery({
    required this.id,
    required this.title,
    required this.year,
    required this.catalogGenre,
  });

  final String id;
  final String title;
  final int year;

  /// Genre tel que fourni par le catalogue (souvent le nom de catégorie Xtream).
  final String catalogGenre;

  @override
  bool operator ==(Object other) =>
      other is MovieGenreQuery &&
      other.id == id &&
      other.title == title &&
      other.year == year &&
      other.catalogGenre == catalogGenre;

  @override
  int get hashCode => Object.hash(id, title, year, catalogGenre);

  @override
  String toString() => 'MovieGenreQuery($id)';
}

/// Vrai genre d'un film, résolu à la demande pour le scoring d'affinité.
///
/// Le catalogue VOD ne porte pas le genre réel : `get_vod_streams` ne le renvoie
/// pas et l'app le remplace par le **nom de catégorie** du panel
/// (`ApiService._enrichMovieListMap`). Un film récent rangé dans « Récents »
/// n'obtient donc jamais de correspondance avec les genres favoris et retombe au
/// seul bonus de note (3 %). On va chercher ici le genre TMDB (une requête
/// `searchMovieLight`, mise en cache Hive 24 h) pour les seules tuiles
/// réellement affichées dont le genre catalogue n'est pas un genre.
///
/// Ne se déclenche que si le profil courant a des genres favoris : sans eux le
/// badge ne dépend pas du genre, la requête serait inutile.
final movieRealGenreProvider =
    FutureProvider.autoDispose.family<String, MovieGenreQuery>((ref, q) async {
  final scorer = ref.watch(profileAffinityScorerProvider);
  final favs = scorer?.favoriteGenres ?? const <String>[];

  // Plus de court-circuit `isKnownGenreLabel` : une catégorie nommée comme un
  // genre (ex. « Horreur ») masquait les genres TMDB réels, plus riches
  // (ex. « Horreur, Thriller, Mystère ») → le score restait sous-évalué.
  // La requête est mise en cache Hive 24 h, une seule fois par tuile.
  if (favs.isEmpty) return q.catalogGenre;

  ref.watch(tmdbApiKeyOverrideProvider);
  // Instance DÉDIÉE à l'affinité : sa file de rate-limit est séparée de celle
  // de la fiche détail, donc ces recherches de genre ne peuvent plus retarder
  // l'enrichissement TMDB du détail film.
  final tmdb = ref.watch(tmdbAffinityServiceProvider);
  if (!tmdb.hasApiKey || q.title.trim().isEmpty) {
    return q.catalogGenre;
  }

  final entry = await tmdb.searchMovieLight(
    q.title,
    year: q.year > 0 ? q.year : null,
  );
  final real = entry?.genreNames ?? '';
  return real.isNotEmpty ? real : q.catalogGenre;
});

/// Clé d'égalité par valeur pour [seriesRealGenreProvider] (même raison que
/// [MovieGenreQuery] : Riverpod famille indexée par `==`/`hashCode`).
class SeriesGenreQuery {
  const SeriesGenreQuery({
    required this.id,
    required this.title,
    required this.year,
    required this.catalogGenre,
  });

  final String id;
  final String title;
  final int year;

  /// Genre tel que fourni par le catalogue (souvent le nom de catégorie Xtream).
  final String catalogGenre;

  @override
  bool operator ==(Object other) =>
      other is SeriesGenreQuery &&
      other.id == id &&
      other.title == title &&
      other.year == year &&
      other.catalogGenre == catalogGenre;

  @override
  int get hashCode => Object.hash(id, title, year, catalogGenre);

  @override
  String toString() => 'SeriesGenreQuery($id)';
}

/// Vrai genre d'une série, résolu à la demande pour le scoring d'affinité.
///
/// `get_series` ne renvoie pas le genre réel (comme `get_vod_streams`, l'app y
/// met le nom de catégorie) : une série d'un onglet « Tous » ne matcherait
/// donc aucun genre favori. Même correctif que [movieRealGenreProvider], côté
/// TMDB TV (`searchTvLight`, cache Hive 24 h), pour les seules tuiles
/// réellement affichées.
final seriesRealGenreProvider =
    FutureProvider.autoDispose.family<String, SeriesGenreQuery>((ref, q) async {
  final scorer = ref.watch(profileAffinityScorerProvider);
  final favs = scorer?.favoriteGenres ?? const <String>[];

  if (favs.isEmpty) return q.catalogGenre;

  ref.watch(tmdbApiKeyOverrideProvider);
  // Instance DÉDIÉE à l'affinité (file de rate-limit séparée de la fiche
  // détail) : même isolation que la VOD.
  final tmdb = ref.watch(tmdbAffinityServiceProvider);
  if (!tmdb.hasApiKey || q.title.trim().isEmpty) {
    return q.catalogGenre;
  }

  // Pas de court-circuit `isKnownGenreLabel` ici : un genre panel nommé comme
  // un genre (ex. « Drame ») cache les genres TMDB réels, plus riches (ex.
  // « Drame, Fantastique, Action & Aventure »). C'est ce qui laissait
  // « Avatar : Seven Havens » à 33 % alors que TMDB le classe différemment.
  final entry = await tmdb.searchTvLight(
    q.title,
    year: q.year > 0 ? q.year : null,
  );
  final real = entry?.genreNames ?? '';
  return real.isNotEmpty ? real : q.catalogGenre;
});

/// Applique un vrai genre TMDB déjà résolu à un [Movie] (copie).
///
/// No-op si le genre réel est inconnu (`realGenre` vide) ou identique au genre
/// catalogue : aucune régression pour les titres non résolus.
Movie movieWithRealGenre(Movie movie, String realGenre) {
  if (realGenre.isEmpty || realGenre == movie.genre) return movie;
  return movie.copyWith(genre: realGenre);
}

/// Idem [movieWithRealGenre], côté [Series].
Series seriesWithRealGenre(Series series, String realGenre) {
  if (realGenre.isEmpty || realGenre == series.genre) return series;
  return series.withGenre(realGenre);
}

/// Réinjecte un genre réel TMDB déjà résolu dans une [Recommendation].
///
/// Alignement « Pour vous » ↔ grilles : les tuiles Films/Séries et le tri par
/// affinité scorent sur le **vrai genre TMDB** (« Horreur, Mystère, … »), pas sur
/// le nom de catégorie Xtream que porte le catalogue. Le matchmaking parcourt
/// tout le catalogue et ne peut pas résoudre les genres à la volée (rate-limit
/// TMDB) : il réutilise donc le cache Hive partagé via `TmdbService.peek*Light`,
/// puis applique ici le genre connu. Sans genre réel, la recommandation est
/// rendue telle quelle.
Recommendation recommendationWithRealGenre(
  Recommendation base,
  String realGenre,
) {
  if (realGenre.isEmpty || realGenre == base.genre) return base;
  final movie = base.movie;
  if (movie != null) {
    return Recommendation(
      kind: base.kind,
      movie: movieWithRealGenre(movie, realGenre),
    );
  }
  final series = base.series;
  if (series != null) {
    return Recommendation(
      kind: base.kind,
      series: seriesWithRealGenre(series, realGenre),
    );
  }
  return base;
}

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

  final seenIds = {
    ...ref.watch(seenRecoIdsProvider(profileId)),
    ...ref.watch(dismissedRecoIdsProvider(profileId)),
  };
  final tmdbTitles = ref.watch(recommendationTitlesProvider);
  final rankingGenres = ref.watch(rankingGenresProvider);
  final rankingMetadata = ref.watch(rankingMetadataProvider);
  // Catégories masquées par abonnement : le matchmaking ne doit pas proposer
  // du contenu que l'utilisateur a choisi de cacher.
  final categoryFilter = ref.watch(vodCategoryFilterProvider);
  final hiddenMovies = categoryFilter.hiddenVodCategoryIds;
  final hiddenSeries = categoryFilter.hiddenSeriesCategoryIds;

  // Alignement avec les grilles : on réinjecte le vrai genre TMDB déjà résolu
  // (cache Hive partagé écrit par les tuiles et l'enrichissement de grille, lu
  // ici **sans réseau ni latence**) avant de scorer. Sans ça, « Pour vous »
  // classerait un film rangé dans « Récents » sur son seul nom de catégorie et
  // divergerait du badge de sa tuile. Le peek est court-circuité sans genres
  // favoris, cas où le score ne dépend pas du genre.
  final affinityTmdb = ref.watch(tmdbAffinityServiceProvider);
  double qualityFor(Recommendation reco) => affinityQualityFor(
        reco,
        rankingMetadata,
        cached: reco.kind == RecommendationKind.movie
            ? affinityTmdb.peekMovieLight(reco.title, year: reco.year > 0 ? reco.year : null)
            : affinityTmdb.peekTvLight(reco.title, year: reco.year > 0 ? reco.year : null),
      );
  final useRealGenre = favoriteGenres.isNotEmpty;
  final favoriteMovieIds = _favoriteIdsOf(ref, ContentType.vod);
  final favoriteSeriesIds = _favoriteIdsOf(ref, ContentType.series);
  Recommendation movieReco(Movie m) {
    if (!useRealGenre) {
      return Recommendation(kind: RecommendationKind.movie, movie: m);
    }
    final real = affinityTmdb
            .peekMovieLight(m.title, year: m.year > 0 ? m.year : null)
            ?.genreNames ??
        '';
    return _withRankingGenre(
      recommendationWithRealGenre(
        Recommendation(kind: RecommendationKind.movie, movie: m),
        real,
      ),
      rankingGenres,
    );
  }

  Recommendation seriesReco(Series s) {
    if (!useRealGenre) {
      return Recommendation(kind: RecommendationKind.series, series: s);
    }
    final real = affinityTmdb
            .peekTvLight(s.title, year: s.year > 0 ? s.year : null)
            ?.genreNames ??
        '';
    return _withRankingGenre(
      recommendationWithRealGenre(
        Recommendation(kind: RecommendationKind.series, series: s),
        real,
      ),
      rankingGenres,
    );
  }

  final scoredMovies = await _rankByAffinity(
    // Iterable paresseux : pas de liste de 99 569 `Recommendation` en mémoire.
    recos: movies.map(movieReco),
    favoriteGenres: favoriteGenres,
    favoriteIds: favoriteMovieIds,
    seenIds: seenIds,
    tmdbTitles: tmdbTitles,
    sessionFilters: sessionFilters,
    hiddenCategories: hiddenMovies,
    limit: kMatchmakingTabLimit,
    qualityFor: qualityFor,
  );

  final scoredSeries = await _rankByAffinity(
    recos: series.map(seriesReco),
    favoriteGenres: favoriteGenres,
    favoriteIds: favoriteSeriesIds,
    seenIds: seenIds,
    tmdbTitles: tmdbTitles,
    sessionFilters: sessionFilters,
    hiddenCategories: hiddenSeries,
    limit: kMatchmakingTabLimit,
    qualityFor: qualityFor,
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
    required this.qualityFor,
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
  final double Function(Recommendation) qualityFor;
}

/// Score « groupe » borné : on ne conserve que les `limit` meilleures affinités
/// au lieu de matérialiser un `GroupReco` par contenu (~20 Mo par groupe).
///
/// Les films et séries sont séparés pendant le parcours : la liste rendue ne
/// dépasse jamais `limit` éléments par type, au lieu de deux `.where().toList()`
/// sur 100 000 éléments.
Future<({List<GroupReco> movies, List<GroupReco> series})> _computeGroupTab(
  ProfileGroup group,
  List<Movie> movies,
  List<Series> series,
  _GroupScoreContext ctx, {
  required int limit,
}) async {
  int byCombined(GroupReco a, GroupReco b) {
    final aStrong = a.minAffinity > kStrongAffinityThreshold;
    final bStrong = b.minAffinity > kStrongAffinityThreshold;
    if (aStrong != bStrong) return aStrong ? -1 : 1;
    final c = (b.combined * 100).round().compareTo((a.combined * 100).round());
    if (c != 0) return c;
    final quality = b.quality.compareTo(a.quality);
    if (quality != 0) return quality;
    final title = _normTitle(a.reco.title).compareTo(_normTitle(b.reco.title));
    return title != 0 ? title : a.reco.id.compareTo(b.reco.id);
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
    if (top.length >= limit) {
      final minimum = affinities.reduce(math.min);
      final combined = affinities.reduce((a, b) => a + b) / affinities.length;
      final last = top.last;
      final strong = minimum > kStrongAffinityThreshold;
      final lastStrong = last.minAffinity > kStrongAffinityThreshold;
      if ((!strong && lastStrong) ||
          (strong == lastStrong &&
              (combined * 100).round() < (last.combined * 100).round())) return;
    }
    final entry = GroupReco(
      reco: reco,
      affinities: affinities,
      quality: ctx.qualityFor(reco),
    );
    // Rejet rapide : le tas est plein et cet élément n'en fait pas mieux que
    // le pire. Evite l'allocation ET le tri.
    if (top.length >= limit && byCombined(entry, top.last) >= 0) return;
    top.add(entry);
    if (top.length >= limit) {
      top.sort(byCombined);
      if (top.length > limit) top.removeLast();
    }
  }

  var visited = 0;
  for (final m in movies) {
    if (++visited % _kYieldEvery == 0) await _yieldToUi();
    consider(Recommendation(kind: RecommendationKind.movie, movie: m));
  }
  for (final s in series) {
    if (++visited % _kYieldEvery == 0) await _yieldToUi();
    consider(Recommendation(kind: RecommendationKind.series, series: s));
  }

  topMovies.sort(byCombined);
  topSeries.sort(byCombined);
  // Même priorisation que l'onglet simple : les contenus que TOUS les profils
  // du groupe aiment (> 75 % pour le maillon faible) passent devant.
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
  final rankingGenres = ref.watch(rankingGenresProvider);
  final rankingMetadata = ref.watch(rankingMetadataProvider);
  // Alignement avec les grilles (voir [recommendationWithRealGenre]) : le mode
  // groupe réutilise lui aussi le vrai genre TMDB déjà résolu, sans réseau.
  final affinityTmdb = ref.watch(tmdbAffinityServiceProvider);
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
    qualityFor: (reco) => affinityQualityFor(
      reco,
      rankingMetadata,
      cached: reco.kind == RecommendationKind.movie
          ? affinityTmdb.peekMovieLight(reco.title, year: reco.year > 0 ? reco.year : null)
          : affinityTmdb.peekTvLight(reco.title, year: reco.year > 0 ? reco.year : null),
    ),
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

  // Alignement du vrai genre TMDB (cache partagé, sans réseau) avant le scoring
  // groupe, pour rester cohérent avec l'onglet simple et les grilles.
  final alignGenres = ctx.favoritesPerProfile.any((g) => g.isNotEmpty);
  final moviesAligned = <Movie>[];
  final seriesAligned = <Series>[];
  if (alignGenres) {
    var n = 0;
    for (final m in movies) {
      if (++n % _kYieldEvery == 0) await _yieldToUi();
      final reco = _withRankingGenre(
        recommendationWithRealGenre(
          Recommendation(kind: RecommendationKind.movie, movie: m),
          affinityTmdb
                  .peekMovieLight(m.title, year: m.year > 0 ? m.year : null)
                  ?.genreNames ??
              '',
        ),
        rankingGenres,
      );
      moviesAligned.add(reco.movie!);
    }
    for (final s in series) {
      if (++n % _kYieldEvery == 0) await _yieldToUi();
      final reco = _withRankingGenre(
        recommendationWithRealGenre(
          Recommendation(kind: RecommendationKind.series, series: s),
          affinityTmdb
                  .peekTvLight(s.title, year: s.year > 0 ? s.year : null)
                  ?.genreNames ??
              '',
        ),
        rankingGenres,
      );
      seriesAligned.add(reco.series!);
    }
  }

  return _computeGroupTab(
    key,
    alignGenres ? moviesAligned : movies,
    alignGenres ? seriesAligned : series,
    ctx,
    limit: kMatchmakingTabLimit,
  );
});
