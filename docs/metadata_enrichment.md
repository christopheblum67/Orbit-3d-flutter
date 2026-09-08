# Système d'Enrichissement des Métadonnées - Orbit IPTV

## Vue d'ensemble

Ce document décrit l'architecture et le flux d'enrichissement des métadonnées pour les films (VOD) et séries dans l'application Orbit. Le système utilise une chaîne de fallbacks priorisés pour obtenir les métadonnées les plus complètes possibles.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    MetadataEnrichmentService                    │
│                        (Orchestrateur)                          │
└─────────────────────────────────────────────────────────────────┘
          │                           │                    │
          ▼                           ▼                    ▼
    ┌───────────┐               ┌───────────┐       ┌───────────┐
    │  TMDB     │               │  TVmaze   │       │   OMDB    │
    │ Service   │               │ Service   │       │ Service   │
    └───────────┘               └───────────┘       └───────────┘
          │                           │                    │
          ▼                           ▼                    ▼
    ┌─────────────────────────────────────────────────────────────┐
    │                      Cache Hive (24h TTL)                   │
    └─────────────────────────────────────────────────────────────┘
```

## Services

### 1. TmdbService (`lib/services/tmdb_service.dart`)

**Base URL** : `https://api.themoviedb.org/3`
**Authentification** : API Key via `.env` (`TMDB_API_KEY`)
**Langue** : `fr-FR`
**Rate Limit** : 40 requêtes / 10 secondes (token bucket)

**Endpoints utilisés** :
- `GET /movie/{id}` - Détails film + `append_to_response=credits,images,videos,external_ids,keywords`
- `GET /tv/{id}` - Détails série + `append_to_response=aggregate_credits,external_ids,keywords,videos`
- `GET /tv/{id}/season/{n}` - Épisodes d'une saison (pour guest stars)
- `GET /search/movie` - Recherche film par titre + année
- `GET /search/tv` - Recherche série par titre + année

**Données extraites** :
- Année, genre, réalisateur, runtime, note
- Casting (avec `order` pour tri) + équipe technique
- Backdrops, posters, bande-annonces YouTube
- IDs externes (IMDb, TVmaze)
- Mots-clés, pays d'origine, langues parlées
- Budget, revenus, statut

### 2. TvmazeService (`lib/services/tvmaze_service.dart`)

**Base URL** : `https://api.tvmaze.com`
**Authentification** : Aucune (gratuit)
**Rate Limit** : 1 requête / seconde

**Endpoints utilisés** :
- `GET /shows/{id}` - Détails série/film
- `GET /shows/{id}/cast` - Casting global
- `GET /shows/{id}/seasons` - Saisons
- `GET /shows/{id}/episodes` - Tous les épisodes (avec `guest_stars` par épisode)
- `GET /search/shows` - Recherche par titre

**Spécificités** :
- **Source primaire pour les séries** (meilleure couverture guest stars)
- `guest_stars` natif par épisode dans `/episodes`
- Format de dates : `YYYY-MM-DD`
- Images : URLs directes (pas de template TMDB)

### 3. OmdbService (`lib/services/omdb_service.dart`)

**Base URL** : `https://www.omdbapi.com`
**Authentification** : API Key via `.env` (`OMDB_API_KEY`)
**Rate Limit** : 1 requête / seconde

**Endpoints utilisés** :
- `GET ?i={imdb_id}&plot=full` - Par IMDb ID
- `GET ?t={title}&y={year}&plot=full` - Par titre + année

**Rôle** : Fallback pour combler les manques (année, runtime, réalisateur, rating, réseau)

### 4. MetadataEnrichmentService (`lib/services/metadata_enrichment_service.dart`)

Orchestrateur principal qui chaîne les fallbacks.

## Flux d'enrichissement

### Film (VOD)

```
1. TMDB (Primaire)
   ├─ Recherche par titre + année → tmdbId
   ├─ GET /movie/{tmdbId} avec append_to_response
   └─ Si succès → MovieDetail complet

2. OMDB (Fallback 1 - si année/runtime/réalisateur manquent)
   ├─ Par IMDb ID (depuis TMDB external_ids)
   ├─ Sinon par titre + année
   └─ Complète les champs manquants

3. TVmaze (Fallback 2 - si casting vide)
   ├─ Recherche film par titre
   ├─ GET /shows/{id}/cast
   └─ Ajoute le casting

4. IA (Dernier recours - si champs critiques encore manquants)
   └─ Prompt structuré → génère métadonnées manquantes
```

### Série

```
1. TVmaze (Primaire)
   ├─ Recherche par titre → tvmazeId
   ├─ GET /shows/{id} + embed=cast
   ├─ GET /shows/{id}/seasons
   ├─ GET /shows/{id}/episodes (avec guest_stars par épisode)
   └─ Si succès → SeriesDetail complet avec guestStarsPerSeason

2. TMDB (Fallback - guest stars par saison si TVmaze vide)
   ├─ Recherche série par titre → tmdbId
   ├─ Pour chaque saison > 0 : GET /tv/{id}/season/{n}
   ├─ Extrait `guest_star: true` des épisodes
   └─ Construit guestStarsPerSeason

3. OMDB (Fallback - champs manquants)
   └─ Complète année, runtime, réseaux, saisons

4. IA (Dernier recours)
```

## Mapping Xtream ID → ID Externes

Les IDs Xtream (ex: `vod_id: "12345"`) **ne correspondent pas** aux IDs TMDB/TVmaze.

**Stratégie** : Recherche par **titre + année** via :
- TMDB : `/search/movie?query={titre}&year={année}` ou `/search/tv`
- TVmaze : `/search/shows?q={titre}` + filtrage type

**Ambiguïté** : Prend le premier résultat, log un warning.

## Modèles de données

### MovieDetail (`lib/models/movie_detail.dart`)

Étend les données Xtream (`Movie`) avec :
```dart
// IDs externes
String imdbId;
int tmdbId;
int tvmazeId;

// Métadonnées enrichies
int runtime;
List<String> keywords;
List<String> originCountry;
List<String> spokenLanguages;
int budget;
int revenue;
String status;
String? trailerUrl;        // YouTube URL
String? backdropUrl;
String? originalLanguage;
String? originalTitle;

// Tracking
bool aiGenerated;
String dataSource;  // 'tmdb' | 'omdb' | 'tvmaze' | 'ai' | 'xtream'
```

### SeriesDetail (`lib/models/series_detail.dart`)

Étend les données Xtream (`Series`) avec :
```dart
// IDs externes
String imdbId;
int tvmazeId;
int tmdbId;

// Métadonnées enrichies
int runtime;
List<String> keywords;
List<String> networks;
String status;              // Running, Ended, Canceled
String firstAirDate;        // YYYY-MM-DD
String? lastAirDate;
int numberOfSeasons;
int numberOfEpisodes;
String? originalLanguage;
String? originalName;

// Guest stars par saison (clé = numéro de saison)
Map<int, List<Actor>> guestStarsPerSeason;

// Distribution principale
List<Actor> cast;

// Tracking
bool aiGenerated;
String dataSource;
```

### Actor (`lib/models/cast.dart`)

Champs ajoutés :
```dart
bool isGuestStar;      // true pour invités spéciaux (séries)
ActorSource source;    // tmdb | tvmaze | omdb | ai | xtream

// Helper
String get profileUrl; // Construit URL TMDB complète
bool get hasProfile;
```

## Widget Réutilisable : CastCarousel

**Fichier** : `lib/core/widgets/cast_carousel.dart`

```dart
CastCarousel({
  required List<Actor> actors,
  String? title,
  bool showCharacter = true,
  int? maxVisible,
  Function(Actor)? onActorTap,
  double itemWidth = 130,
  double imageSize = 100,
})
```

**Fonctionnalités** :
- Scroll horizontal (`ListView.separated`)
- Photos circulaires avec `CachedNetworkImage` (lazy loading)
- Hero animations pour transitions
- **Navigation D-pad TV** via `TvFocus` wrapper
- Badge "Invité" pour `isGuestStar = true`
- Variante `CompactCastCarousel` pour espaces réduits

**Utilisation** :
- Film : `CastCarousel(actors: detail.cast.take(12).toList(), title: 'Distribution')`
- Série guests : `CastCarousel(actors: detail.getGuestStarsForSeason(season), title: 'Invités spéciaux S$season')`

## Providers Riverpod

**Fichier** : `lib/providers/providers.dart`

```dart
// Services
final tmdbServiceProvider = Provider<TmdbService>(...);
final tvmazeServiceProvider = Provider<TvmazeService>(...);
final omdbServiceProvider = Provider<OmdbService>(...);
final enrichmentServiceProvider = Provider<MetadataEnrichmentService>(...);

// Famille pour détails enrichis
final movieDetailProvider = FutureProvider.family<MovieDetail, Movie>((ref, movie) async {
  return ref.watch(enrichmentServiceProvider).enrichMovie(movie);
});

final seriesDetailProvider = FutureProvider.family<SeriesDetail, Series>((ref, series) async {
  return ref.watch(enrichmentServiceProvider).enrichSeries(series);
});
```

## Configuration

### Variables d'environnement (`.env`)

```env
# TMDB - TheMovieDB
TMDB_API_KEY=your_tmdb_key

# OMDB - Open Movie Database
OMDB_API_KEY=your_omdb_key

# TVmaze - Pas de clé nécessaire

# IA (existant)
IA_API_KEY=your_openai_key
IA_API_ENDPOINT=https://api.openai.com/v1/chat/completions
```

### Cache Hive

**Boîte** : `metadata_cache`
**Clés** :
- `tmdb:movie:{id}` / `tmdb:tv:{id}`
- `tvmaze:movie:{id}` / `tvmaze:show:{id}`
- `omdb:imdb:{id}` / `omdb:search:{title}_{year}`

**Structure entrée** :
```json
{
  "data": { ... réponse API ... },
  "fetchedAt": 1699999999999  // timestamp ms
}
```

**TTL** : 24 heures (86,400,000 ms)

## Rate Limiting

| Service | Limite | Implémentation |
|---------|--------|----------------|
| TMDB | 40 req / 10s | Token bucket (timestamps sliding window) |
| TVmaze | 1 req / s | Intervalle minimum entre requêtes |
| OMDB | 1 req / s | Intervalle minimum entre requêtes |

## Gestion des erreurs / Hors-ligne

1. **Pas de clé API** : Service retourne `null` gracieusement, fallback au suivant
2. **Erreur réseau** : Log warning, fallback au service suivant
3. **Hors-ligne** : Données Xtream de base affichées + badge "Données locales"
4. **Toutes APIs KO** : Données Xtream + pas d'erreur bloquante

## Intégration dans les écrans

### MovieDetailScreen (`lib/features/vod/movie_detail_screen.dart`)

```dart
final detailAsync = ref.watch(movieDetailProvider(movie));
// Affichage via detailAsync.when(data: (detail) => _MovieDetailContent(detail: detail))
// Nouveautés : runtime, pays, langues, budget/revenus, bouton bande-annonce, CastCarousel
```

### SeriesDetailScreen (`lib/features/series/series_detail_screen.dart`)

```dart
final baseSeriesAsync = ref.watch(seriesInfoProvider(seriesId));
// Puis :
final detailAsync = ref.watch(seriesDetailProvider(baseSeries));
// Nouveautés : header enrichi (statut, réseau, 1ère diffusion), 
// CompactCastCarousel distribution, CastCarousel guests par saison
```

## Tests

**Fichier** : `test/unit/metadata_enrichment_test.dart`

Couverture :
- `MovieDetail.fromMovie()`, `copyWith()`, `pegiLabel`, `needsEnrichment`
- `SeriesDetail.fromSeries()`, `copyWith()`, `getGuestStarsForSeason()`, `pegiLabel`
- `Actor.fromMap()`, `copyWith()`, `profileUrl`, `isGuestStar`

## Points d'attention

1. **Ordre de priorité** : TMDB (films) / TVmaze (séries) → OMDB → IA
2. **Stream URL** : Toujours source Xtream (lecture). APIs externes = affichage seulement.
3. **Guest stars** : TVmaze natif par épisode ; TMDB via `/season/{n}` avec `guest_star: true`
4. **IA** : Uniquement si TOUTES les APIs externes échouent (dernier recours)
5. **Pas de breaking** : Fonctionne sans clés API (fallback gracieux sur données Xtream)
6. **Performance** : Parallélisation `detail + credits` ; skeleton loaders pendant enrichissement

## Évolutions futures

- [ ] Implémentation réelle du fallback IA (étendre `AiService`)
- [ ] Recherche floue améliorée (Levenshtein) pour mapping titres
- [ ] Support des images TVmaze directes (sans template TMDB)
- [ ] Métriques de taux de succès par source
- [ ] Préchargement en background (prefetch au scroll)