import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';
import 'package:orbit_3d_flutter/services/search_index_service.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

class SearchService {
  static const String _historyBoxName = 'search_history';
  static const int _maxHistoryEntries = 100;
  static const Duration _historyTtl = Duration(days: 30);

  final ApiService _api;
  final TmdbService _tmdb;
  final TvmazeService _tvmaze;

  /// Charge les favoris du profil courant, ou une liste vide si absent.
  final Future<List<FavoriteEntry>> Function()? _loadFavorites;

  /// Charge le « récemment regardé » du profil courant, ou vide si absent.
  final Future<List<RecentEntry>> Function()? _loadRecentlyWatched;

  /// Index plein-texte local du catalogue (VOD/Séries/Live), optionnel.
  final SearchIndexService? _index;

  /// Charge les entrées du catalogue à indexer (toute la VOD/Séries/Live),
  /// ou null si absent. Appelé une seule fois (mémorisé).
  final Future<List<SearchIndexEntry>> Function()? _loadCatalogue;

  Future<void>? _indexingJob;

  SearchService({
    required ApiService api,
    required TmdbService tmdb,
    required TvmazeService tvmaze,
    Future<List<FavoriteEntry>> Function()? loadFavorites,
    Future<List<RecentEntry>> Function()? loadRecentlyWatched,
    SearchIndexService? searchIndex,
    Future<List<SearchIndexEntry>> Function()? loadCatalogue,
  })  : _api = api,
        _tmdb = tmdb,
        _tvmaze = tvmaze,
        _loadFavorites = loadFavorites,
        _loadRecentlyWatched = loadRecentlyWatched,
        _index = searchIndex,
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

  Future<UnifiedSearchResult> search(String query, {int limit = 50, SearchType? filterType, AppLocalizations? l}) async {
    final normalized = _normalize(query);
    if (normalized.length < 2) return UnifiedSearchResult.empty();

    // 1. Paralléliser les 3 branches : local, index, remote
    await _ensureCatalogueIndexed();
    final results = await Future.wait([
      _searchLocal(normalized, l),
      Future.value(_searchIndex(normalized, filterType: filterType)),
      _searchRemote(normalized, filterType: filterType),
    ]);

    final localResults = results[0];
    final ftsResults = results[1];
    final remoteResults = results[2];

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

    // Scoring & tri
    unique.sort((a, b) => _calculateScore(normalized, b).compareTo(_calculateScore(normalized, a)));

    // Historique
    await addToHistory(normalized);

    return UnifiedSearchResult(
      items: unique.take(limit).toList(),
      timestamp: DateTime.now(),
    );
  }

  Future<List<SearchItem>> _searchLocal(String query, AppLocalizations? l) async {
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
            ));
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

  /// Construit l'index plein-texte du catalogue une seule fois (mémorisé).
  Future<void> _ensureCatalogueIndexed() async {
    if (_index == null) return;
    if (_index!.isBuilt) return;
    final job = _indexingJob;
    if (job != null) return job;
    final loader = _loadCatalogue;
    if (loader == null) return;
    final future = () async {
      await safeAsync<void>(
        () async {
          final entries = await loader();
          _index!.build(entries);
        },
        context: 'SearchService._ensureCatalogueIndexed',
      );
      _indexingJob = null;
    }();
    _indexingJob = future;
    return future;
  }

  /// Recherche plein-texte dans l'index local du catalogue, mappée en
  /// [SearchItem] (source locale) avec un score dérivé du rang.
  List<SearchItem> _searchIndex(String query, {SearchType? filterType}) {
    final index = _index;
    if (index == null) return const [];
    final hits = index.search(query, type: filterType);
    return [
      for (final hit in hits)
        SearchItem(
          id: hit.entry.id,
          type: hit.entry.type,
          title: hit.entry.title,
          subtitle: hit.entry.subtitle,
          posterUrl: hit.entry.posterUrl,
          streamUrl: hit.entry.streamUrl.isEmpty ? null : hit.entry.streamUrl,
          categoryId: hit.entry.categoryId.isEmpty ? null : hit.entry.categoryId,
          score: (0.3 + 0.6 * hit.rank).clamp(0.0, 1.0),
          source: SearchSource.local,
        ),
    ];
  }

  Future<List<SearchItem>> _searchRemote(String query, {SearchType? filterType}) async {
    final futures = <Future<List<SearchItem>>>[];

    // TMDB (films + séries) — parallélisé
    if (filterType == null || filterType == SearchType.vod || filterType == SearchType.series) {
      futures.add(_searchTmdb(query, filterType: filterType));
    }

    // TVmaze (séries) — parallélisé
    if (filterType == null || filterType == SearchType.series) {
      futures.add(_searchTvmaze(query));
    }

    // API Xtream (live + VOD + séries) — parallélisé
    if (filterType == null || filterType == SearchType.live || filterType == SearchType.vod || filterType == SearchType.series) {
      futures.add(_searchXtream(query));
    }

    final allResults = await Future.wait(futures);
    return allResults.expand((e) => e).toList();
  }

  Future<List<SearchItem>> _searchTmdb(String query, {SearchType? filterType}) async {
    final result = await safeAsync<List<SearchItem>>(
      () async {
        final results = <SearchItem>[];
        // Recherche films
        if (filterType == null || filterType == SearchType.vod) {
          final movieId = await _tmdb.searchMovieId(query);
          if (movieId != null) {
            final movie = await _tmdb.getMovieDetail(movieId);
            if (movie != null) {
              results.add(SearchItem.fromMovieDetail(movie, source: SearchSource.tmdb));
            }
          }
        }
        // Recherche séries
        if (filterType == null || filterType == SearchType.series) {
          final tvId = await _tmdb.searchTvId(query);
          if (tvId != null) {
            final series = await _tmdb.getTvDetail(tvId);
            if (series != null) {
              results.add(SearchItem.fromSeriesDetail(series, source: SearchSource.tmdb));
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
            results.add(SearchItem.fromSeriesDetail(show, source: SearchSource.tvmaze));
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
    await HiveSync.writeBoxAsync<SearchHistoryEntry, void>(_historyBoxName, (box) async {
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
    return HiveSync.readBox<SearchHistoryEntry, List<String>>(_historyBoxName, (box) {
      final entries = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return entries.map((e) => e.query).toList();
    });
  }

  Future<void> clearHistory() async {
    await HiveSync.writeBoxAsync<SearchHistoryEntry, void>(_historyBoxName, (box) async {
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
                ))
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
                ))
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