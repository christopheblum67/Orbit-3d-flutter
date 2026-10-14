import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';
import 'package:orbit_3d_flutter/services/search_fts_service.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

/// Entrée du cache court des résultats distants.
class _RemoteCacheEntry {
  _RemoteCacheEntry(this.items, this.at);

  final List<SearchItem> items;
  final DateTime at;
}

/// Instantané du catalogue local servant à alimenter l'index FTS5.
class SearchCatalogue {
  const SearchCatalogue({
    this.movies = const <Movie>[],
    this.series = const <Series>[],
    this.channels = const <Channel>[],
  });

  final List<Movie> movies;
  final List<Series> series;
  final List<Channel> channels;

  bool get isEmpty => movies.isEmpty && series.isEmpty && channels.isEmpty;
}

class SearchService {
  static const String _historyBoxName = 'search_history';
  static const int _maxHistoryEntries = 100;
  static const Duration _historyTtl = Duration(days: 30);

  final ApiService _api;
  final TmdbService _tmdb;
  final TvmazeService _tvmaze;

  /// Charge les favoris du profil courant, ou une liste vide si absent.
  final Future<List<FavoriteEntry>> Function()? _loadFavorites;

  /// Charge le récemment regardé du profil courant, ou vide si absent.
  final Future<List<RecentEntry>> Function()? _loadRecentlyWatched;

  /// Charge le catalogue (Live + VOD + Séries) pour alimenter l'index FTS5.
  final Future<SearchCatalogue> Function()? _loadCatalogue;

  /// Service FTS5 SQLite pour la recherche plein-texte persistante.
  final SearchFtsService _fts = SearchFtsService.instance;

  Future<void>? _indexingJob;

  SearchService({
    required ApiService api,
    required TmdbService tmdb,
    required TvmazeService tvmaze,
    Future<List<FavoriteEntry>> Function()? loadFavorites,
    Future<List<RecentEntry>> Function()? loadRecentlyWatched,
    Future<SearchCatalogue> Function()? loadCatalogue,
  })  : _api = api,
        _tmdb = tmdb,
        _tvmaze = tvmaze,
        _loadFavorites = loadFavorites,
        _loadRecentlyWatched = loadRecentlyWatched,
        _loadCatalogue = loadCatalogue {
    _initHistoryBox();
  }

  Future<void> _initHistoryBox() async {
    if (!Hive.isBoxOpen(_historyBoxName)) {
      await Hive.openBox(_historyBoxName);
    }
    _cleanupHistory();
  }

  void _cleanupHistory() {
    HiveSync.readBox<SearchHistoryEntry, void>(_historyBoxName, (box) {
      final now = DateTime.now();
      final keysToDelete = <dynamic>[];
      for (final key in box.keys) {
        final entry = box.get(key);
        if (entry != null && now.difference(entry.timestamp) > _historyTtl) {
          keysToDelete.add(key);
        }
      }
      for (final key in keysToDelete) {
        box.delete(key);
      }
    });
  }

  String _normalize(String query) {
    return query
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\sàâäéèêëïîôöùûüÿç-]'), '');
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix =
        List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }

  double _fuzzyScore(String query, String target) {
    final normalizedQuery = _normalize(query);
    final normalizedTarget = _normalize(target);

    if (normalizedQuery.isEmpty) return 0.0;
    if (normalizedTarget.isEmpty) return 0.0;

    if (normalizedTarget == normalizedQuery) return 1.0;
    if (normalizedTarget.startsWith(normalizedQuery)) return 0.9;
    if (normalizedTarget.contains(normalizedQuery)) return 0.7;

    final distance = _levenshteinDistance(normalizedQuery, normalizedTarget);
    final maxLen = normalizedQuery.length > normalizedTarget.length
        ? normalizedQuery.length
        : normalizedTarget.length;
    if (maxLen == 0) return 0.0;

    final similarity = 1.0 - (distance / maxLen);
    if (similarity > 0.6) return similarity * 0.5;
    return 0.0;
  }

  double _calculateScore(String query, SearchItem item) {
    double score = _fuzzyScore(query, item.title);

    if (item.subtitle.isNotEmpty) {
      score = (score + _fuzzyScore(query, item.subtitle) * 0.5) / 1.5;
    }

    switch (item.type) {
      case SearchType.live:
        score *= 1.2;
        break;
      case SearchType.vod:
        score *= 1.1;
        break;
      case SearchType.series:
        score *= 1.1;
        break;
      case SearchType.replay:
        score *= 1.0;
        break;
      case SearchType.epg:
        score *= 0.9;
        break;
    }

    if (item.source == SearchSource.local) {
      score *= 1.15;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Masque un résultat dont la catégorie figure dans les catégories
  /// masquées de l'abonnement actif (les deux listes sont optionnelles pour
  /// ne pas casser les appelants existants).
  bool _shouldHideCategory(SearchItem item,
      List<String>? hiddenVodCategoryIds,
      List<String>? hiddenSeriesCategoryIds,) {
    if (hiddenVodCategoryIds == null && hiddenSeriesCategoryIds == null) {
      return false;
    }
    final categoryId = item.categoryId;
    if (categoryId == null || categoryId.isEmpty) return false;
    if (item.type == SearchType.vod && hiddenVodCategoryIds != null) {
      return hiddenVodCategoryIds.contains(categoryId);
    }
    if (item.type == SearchType.series && hiddenSeriesCategoryIds != null) {
      return hiddenSeriesCategoryIds.contains(categoryId);
    }
    return false;
  }

  /// Restreint (ou élargit) les résultats à une catégorie de section.
  ///
  /// C'est le pendant du filtrage par catégorie déjà appliqué dans les grilles
  /// VOD / Séries / Chaînes : la recherche doit suivre exactement la même
  /// règle, sinon l'utilisateur sélectionne une catégorie et découvre des
  /// résultats qui ne lui appartiennent pas.
  ///
  /// `null` = pas de filtre (toutes les catégories de la section). Une chaîne
  /// vide est traitée comme « pas de filtre » : c'est ce que renvoie un
  /// sélecteur de catégorie sur mobile quand aucune n'est choisie.
  static bool _matchesCategory(SearchItem item, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return true;
    return item.categoryId == categoryId;
  }

  Future<UnifiedSearchResult> search(String query,
      {int limit = 50,
      SearchType? filterType,
      AppLocalizations? l,
      List<String>? hiddenVodCategoryIds,
      List<String>? hiddenSeriesCategoryIds,
      String? categoryId,}) async {
    final normalized = _normalize(query);
    if (normalized.length < 2) return UnifiedSearchResult.empty();

    // Clé de cache des résultats distants : elle inclut le filtre de type, car
    // « matrix » en Films et en Séries ne renvoient pas les mêmes éléments.
    // Elle inclut aussi les catégories masquées : sans cela, modifier le
    // masquage servirait des résultats distants calculés avec l'ancien
    // filtre, et du contenu masqué réapparaîtrait en recherche.
    final hiddenKey = [
      ...?hiddenVodCategoryIds,
      ...?hiddenSeriesCategoryIds,
    ].join(',');
    final remoteKey =
        '${filterType?.name ?? 'all'}|$normalized|${hiddenKey.hashCode}';
    final cachedRemote = _cachedRemote(remoteKey);

    // 1. Paralléliser les 3 branches : local, FTS, remote
    await _ensureCatalogueIndexed();
    final results = await Future.wait<List<SearchItem>>([
      _searchLocal(normalized, l),
      _fts.search(query: query, type: filterType).then(
        (hits) => hits.map((h) => h.toSearchItem()).toList(),
      ),
      if (cachedRemote != null)
        Future<List<SearchItem>>.value(cachedRemote)
      else
        _searchRemote(normalized, filterType: filterType),
    ]);

    final localResults = results[0];
    final ftsResults = results[1];
    final remoteResults = results[2];
    if (cachedRemote == null) {
      _cacheRemote(remoteKey, remoteResults);
    }
    // 4. Fusion & déduplication
    final allItems = <SearchItem>[];
    allItems.addAll(localResults);
    allItems.addAll(ftsResults);
    allItems.addAll(remoteResults);

    // Déduplication par ID + type
    final seen = <String>{};
    final unique = <SearchItem>[];
    for (final item in allItems) {
      final key = '${item.type}:${item.id}';
      if (seen.add(key)) unique.add(item);
    }

    // Catégories masquées par abonnement : on retire ces résultats avant le
    // tri pour que les compteurs et le classement restent cohérents.
    final withoutHidden = unique
        .where((item) => !_shouldHideCategory(
            item, hiddenVodCategoryIds, hiddenSeriesCategoryIds,),)
        .toList();

    // Restriction à la catégorie sélectionnée, appliquée après le masquage :
    // l'ordre des filtres n'est pas décoratif, il garantit que les compteurs
    // par type et le classement portent sur les seuls résultats visibles.
    final visible = categoryId == null || categoryId.isEmpty
        ? withoutHidden
        : withoutHidden
            .where((item) => _matchesCategory(item, categoryId))
            .toList();

    // Scoring & tri
    visible.sort((a, b) => _calculateScore(normalized, b)
        .compareTo(_calculateScore(normalized, a)),);

    // Historique
    await addToHistory(normalized);

    return UnifiedSearchResult(
      items: visible.take(limit).toList(),
      timestamp: DateTime.now(),
    );
  }

  Future<List<SearchItem>> _searchLocal(
      String query, AppLocalizations? l,) async {
    final items = <SearchItem>[];

// Historique de recherche - on ajoute comme suggestions textuelles
    await safeAsync<void>(
      () async {
        final history = await getHistory();
        for (final h in history) {
          items.add(SearchItem(
            id: 'history-$h',
            type: SearchType.vod, // type par défaut pour l'affichage
            title: h,
            subtitle: l?.recentSearch ?? 'Recherche récente',
            posterUrl: '',
            score: 0.5,
            source: SearchSource.local,
          ),);
        }
      },
      context: 'SearchService._searchLocal history',
    );

// Favoris
    await safeAsync<void>(
      () async {
        items.addAll(await _getFavorites());
      },
      context: 'SearchService._searchLocal favorites',
    );

    // Récemment regardé
    await safeAsync<void>(
      () async {
        items.addAll(await _getRecentlyWatched());
      },
      context: 'SearchService._searchLocal recently watched',
    );

    return items;
  }

  /// Initialise l'index FTS5 et l'alimente avec le catalogue local (une fois).
  Future<void> _ensureCatalogueIndexed() async {
    if (_fts.isReady) return;
    final job = _indexingJob;
    if (job != null) return job;
    final future = () async {
      await safeAsync<void>(
        () async {
          await _fts.init();
          final loader = _loadCatalogue;
          if (loader == null) return;
          // L'index est persistant : on ne le reconstruit que s'il est vide.
          if (await _fts.count > 0) return;
          final catalogue = await loader();
          await _fts.rebuild(
            movies: catalogue.movies,
            series: catalogue.series,
            channels: catalogue.channels,
          );
        },
        context: 'SearchService._ensureCatalogueIndexed',
      );
      _indexingJob = null;
    }();
    _indexingJob = future;
    return future;
  }

  Future<List<SearchItem>> _searchRemote(String query,
      {SearchType? filterType,}) async {
    final futures = <Future<List<SearchItem>>>[];

    // Seuil de déclenchement des sources distantes : en dessous de 3 caractères
    // les APIs de recherche ne renvoient que du bruit, et surtout le taper de
    // l'utilisateur déclencherait une requête réseau par frappe. On s'appuie
    // alors sur l'index local/FTS, qui répond instantanément.
    if (query.trim().length >= _remoteMinLength) {
      // TMDB (films + séries) — parallélisé
      if (filterType == null ||
          filterType == SearchType.vod ||
          filterType == SearchType.series) {
        futures.add(_searchTmdb(query, filterType: filterType));
      }

      // TVmaze (séries) — parallélisé
      if (filterType == null || filterType == SearchType.series) {
        futures.add(_searchTvmaze(query));
      }

      // API Xtream (live + VOD + séries) — parallélisé
      if (filterType == null ||
          filterType == SearchType.live ||
          filterType == SearchType.vod ||
          filterType == SearchType.series) {
        futures.add(_searchXtream(query));
      }
    }

    if (futures.isEmpty) return const <SearchItem>[];
    final allResults = await Future.wait(futures);
    return allResults.expand((e) => e).toList();
  }

  /// Longueur minimale pour interroger les sources distantes.
  static const int _remoteMinLength = 3;

  /// Cache mémoire court des résultats distants, par requête normalisée.
  ///
  /// Sans lui, revenir sur une requête déjà tapée relançait TMDB + TVmaze +
  /// Xtream alors que le résultat était identique quelques secondes plus tôt.
  /// La clé inclut le filtre de type pour ne pas mélanger les jeux.
  final Map<String, _RemoteCacheEntry> _remoteCache = {};

  /// Nombre maximal d'entrées (les quelques dernières requêtes suffisent).
  static const int _remoteCacheMaxEntries = 40;

  /// Durée de vie d'une entrée, alignée sur le TTL du cache applicatif.
  static const Duration _remoteCacheTtl = Duration(minutes: 5);

  List<SearchItem>? _cachedRemote(String key) {
    final entry = _remoteCache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > _remoteCacheTtl) {
      _remoteCache.remove(key);
      return null;
    }
    return entry.items;
  }

  void _cacheRemote(String key, List<SearchItem> items) {
    if (_remoteCache.length >= _remoteCacheMaxEntries) {
      // Purge des entrées les plus anciennes.
      final stale = _remoteCache.entries
          .where((e) =>
              DateTime.now().difference(e.value.at) > _remoteCacheTtl,)
          .map((e) => e.key)
          .toList();
      for (final key in stale) {
        _remoteCache.remove(key);
      }
      if (_remoteCache.length >= _remoteCacheMaxEntries) {
        _remoteCache.remove(_remoteCache.keys.first);
      }
    }
    _remoteCache[key] = _RemoteCacheEntry(items, DateTime.now());
  }

  Future<List<SearchItem>> _searchTmdb(String query,
      {SearchType? filterType,}) async {
    final result = await safeAsync<List<SearchItem>>(
      () async {
        final results = <SearchItem>[];
        // Recherche films
        if (filterType == null || filterType == SearchType.vod) {
          final movieId = await _tmdb.searchMovieId(query);
          if (movieId != null) {
            final movie = await _tmdb.getMovieDetail(movieId);
            if (movie != null) {
              results.add(
                  SearchItem.fromMovieDetail(movie, source: SearchSource.tmdb),);
            }
          }
        }
        // Recherche séries
        if (filterType == null || filterType == SearchType.series) {
          final tvId = await _tmdb.searchTvId(query);
          if (tvId != null) {
            final series = await _tmdb.getTvDetail(tvId);
            if (series != null) {
              results.add(SearchItem.fromSeriesDetail(series,
                  source: SearchSource.tmdb,),);
            }
          }
        }
        return results;
      },
      context: 'SearchService._searchTmdb',
      fallbackValue: const <SearchItem>[],
    );
    return result.getOrElse(const <SearchItem>[]);
  }

  Future<List<SearchItem>> _searchTvmaze(String query) async {
    final result = await safeAsync<List<SearchItem>>(
      () async {
        final results = <SearchItem>[];
        final showId = await _tvmaze.searchShowId(query);
        if (showId != null) {
          final show = await _tvmaze.getShowDetail(showId);
          if (show != null) {
            results.add(
                SearchItem.fromSeriesDetail(show, source: SearchSource.tvmaze),);
          }
        }
        return results;
      },
      context: 'SearchService._searchTvmaze',
      fallbackValue: const <SearchItem>[],
    );
    return result.getOrElse(const <SearchItem>[]);
  }

  Future<List<SearchItem>> _searchXtream(String query) async {
    final result = await safeAsync<List<SearchItem>>(
      () async {
        final xtreamResults = await _api.search(query);
        return xtreamResults.items;
      },
      context: 'SearchService._searchXtream',
      fallbackValue: const <SearchItem>[],
    );
    return result.getOrElse(const <SearchItem>[]);
  }

  Future<void> addToHistory(String query) async {
    await HiveSync.writeBoxAsync<SearchHistoryEntry, void>(_historyBoxName,
        (box) async {
      final normalized = _normalize(query);
      if (normalized.length < 2) return;

      final existingKeys = <dynamic>[];
      for (final key in box.keys) {
        final entry = box.get(key);
        if (entry != null && entry.query == normalized) {
          existingKeys.add(key);
        }
      }
      for (final key in existingKeys) {
        box.delete(key);
      }

      final entry = SearchHistoryEntry(
        query: normalized,
        timestamp: DateTime.now(),
        resultCount: 0,
      );

      await box.add(entry);

      if (box.length > _maxHistoryEntries) {
        var oldestKey = box.keys.first;
        var oldestEntry = box.get(oldestKey);
        for (final key in box.keys) {
          final entry = box.get(key);
          if (entry != null &&
              oldestEntry != null &&
              entry.timestamp.isBefore(oldestEntry.timestamp)) {
            oldestKey = key;
            oldestEntry = entry;
          }
        }
        await box.delete(oldestKey);
      }
    });
  }

  Future<List<String>> getHistory() async {
    return HiveSync.readBox<SearchHistoryEntry, List<String>>(_historyBoxName,
        (box) {
      final entries = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return entries.map((e) => e.query).toList();
    });
  }

  Future<void> clearHistory() async {
    await HiveSync.writeBoxAsync<SearchHistoryEntry, void>(_historyBoxName,
        (box) async {
      await box.clear();
    });
  }

  Future<List<SearchItem>> _getFavorites() async {
    final loader = _loadFavorites;
    if (loader == null) return [];
    final result = await safeAsync<List<SearchItem>>(
      () async {
        final favorites = await loader();
        return favorites
            .map((f) => SearchItem(
                  id: f.id,
                  type: switch (f.type) {
                    ContentType.live => SearchType.live,
                    ContentType.vod => SearchType.vod,
                    ContentType.series => SearchType.series,
                    ContentType.replay => SearchType.replay,
                  },
                  title: f.title,
                  subtitle: f.subtitle,
                  posterUrl: f.posterUrl,
                  streamUrl: f.streamUrl,
                  score: 0.6,
                  source: SearchSource.local,
                  originalObject: f,
                ),)
            .toList();
      },
      context: 'SearchService._getFavorites',
      fallbackValue: const <SearchItem>[],
    );
    return result.getOrElse(const <SearchItem>[]);
  }

  Future<List<SearchItem>> _getRecentlyWatched() async {
    final loader = _loadRecentlyWatched;
    if (loader == null) return [];
    final result = await safeAsync<List<SearchItem>>(
      () async {
        final recents = await loader();
        return recents
            .map((r) => SearchItem(
                  id: r.id,
                  type: switch (r.type) {
                    ContentType.live => SearchType.live,
                    ContentType.vod => SearchType.vod,
                    ContentType.series => SearchType.series,
                    ContentType.replay => SearchType.replay,
                  },
                  title: r.title,
                  subtitle: r.subtitle,
                  posterUrl: r.posterUrl,
                  streamUrl: r.streamUrl,
                  score: 0.5,
                  source: SearchSource.local,
                  originalObject: r,
                ),)
            .toList();
      },
      context: 'SearchService._getRecentlyWatched',
      fallbackValue: const <SearchItem>[],
    );
    return result.getOrElse(const <SearchItem>[]);
  }

  void dispose() {
    HiveSync.readBox<SearchHistoryEntry, void>(_historyBoxName, (box) {
      if (box.isOpen) {
        box.close();
      }
    });
  }

  /// Fournit des suggestions de recherche en temps réel (pour l'autocomplétion).
  Stream<List<SearchSuggestion>> suggestions(String query) async* {
    if (query.trim().length < 2) {
      yield [];
      return;
    }

    final history = await getHistory();
    final normalized = _normalize(query);
    final suggestions = history
        .where((h) => _normalize(h).contains(normalized))
        .take(5)
        .map((h) => SearchSuggestion(text: h, isHistory: true))
        .toList();

    yield suggestions;
  }
}

extension SearchItemCopyWith on SearchItem {
  SearchItem copyWith({
    String? id,
    SearchType? type,
    String? title,
    String? subtitle,
    String? posterUrl,
    String? streamUrl,
    String? categoryId,
    double? score,
    SearchSource? source,
    dynamic originalObject,
  }) {
    return SearchItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      posterUrl: posterUrl ?? this.posterUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      categoryId: categoryId ?? this.categoryId,
      score: score ?? this.score,
      source: source ?? this.source,
      originalObject: originalObject ?? this.originalObject,
    );
  }
}
