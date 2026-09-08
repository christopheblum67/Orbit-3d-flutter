import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

class _XtreamSearchResult {
  final List<Channel> live;
  final List<Movie> vod;
  final List<Series> series;

  _XtreamSearchResult({
    required this.live,
    required this.vod,
    required this.series,
  });
}

class SearchService {
  static const String _historyBoxName = 'search_history';
  static const int _maxHistoryEntries = 100;
  static const Duration _historyTtl = Duration(days: 30);
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  final ApiService _api;
  final StorageService _storage;
  final TmdbService _tmdb;
  final TvmazeService _tvmaze;
  final LoggerService _logger = LoggerService.instance;

  Box<SearchHistoryEntry>? _historyBox;

  SearchService({
    required ApiService api,
    required StorageService storage,
    required TmdbService tmdb,
    required TvmazeService tvmaze,
  })  : _api = api,
        _storage = storage,
        _tmdb = tmdb,
        _tvmaze = tvmaze {
    _initHistoryBox();
  }

  Future<void> _initHistoryBox() async {
    if (!Hive.isBoxOpen(_historyBoxName)) {
      _historyBox = await Hive.openBox<SearchHistoryEntry>(_historyBoxName);
    } else {
      _historyBox = Hive.box<SearchHistoryEntry>(_historyBoxName);
    }
    _cleanupHistory();
  }

  void _cleanupHistory() {
    if (_historyBox == null) return;
    final now = DateTime.now();
    final keysToDelete = <dynamic>[];
    for (final key in _historyBox!.keys) {
      final entry = _historyBox!.get(key);
      if (entry != null && now.difference(entry.timestamp) > _historyTtl) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      _historyBox!.delete(key);
    }
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
    for (var i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (var j = 0; j <= b.length; j++) matrix[0][j] = j;

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

  Future<UnifiedSearchResult> search(String query, {int limit = 50}) async {
    final normalized = _normalize(query);
    if (normalized.length < 2) return UnifiedSearchResult.empty();

    try {
      final localResults = await _localSearch(normalized);
      final remoteResults = await _remoteSearch(normalized);
      final merged = _mergeAndRank(localResults, remoteResults, normalized);

      _enrichAsync(merged.items);

      return merged.take(limit);
    } catch (e, stack) {
      _logger.error('Search error: $e', stackTrace: stack);
      final localOnly = await _localSearch(normalized);
      return localOnly.take(limit).copyWith(isOffline: true);
    }
  }

  Future<UnifiedSearchResult> _localSearch(String query) async {
    final items = <SearchItem>[];
    final history = await getHistory();

    for (final h in history) {
      final score = _fuzzyScore(query, h);
      if (score > 0.3) {
        items.add(SearchItem(
          id: 'history_$h',
          type: SearchType.vod,
          title: h,
          subtitle: 'Historique',
          posterUrl: '',
          score: score * 0.8,
          source: SearchSource.local,
        ));
      }
    }

    final favorites = await _getFavorites();
    for (final fav in favorites) {
      final score = _fuzzyScore(query, fav.title);
      if (score > 0.3) {
        items.add(fav.copyWith(score: score * 0.9, source: SearchSource.local));
      }
    }

    final recent = await _getRecentlyWatched();
    for (final rec in recent) {
      final score = _fuzzyScore(query, rec.title);
      if (score > 0.3) {
        items
            .add(rec.copyWith(score: score * 0.85, source: SearchSource.local));
      }
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    return UnifiedSearchResult(items: items);
  }

  Future<UnifiedSearchResult> _remoteSearch(String query) async {
    final apiResult = await _api.search(query);
    final items = <SearchItem>[];

    for (final channel
        in apiResult.items.where((i) => i.type == SearchType.live)) {
      items.add(channel.copyWith(
          score: _fuzzyScore(query, channel.title),
          source: SearchSource.xtream));
    }
    for (final movie
        in apiResult.items.where((i) => i.type == SearchType.vod)) {
      items.add(movie.copyWith(
          score: _fuzzyScore(query, movie.title), source: SearchSource.xtream));
    }
    for (final series
        in apiResult.items.where((i) => i.type == SearchType.series)) {
      items.add(series.copyWith(
          score: _fuzzyScore(query, series.title),
          source: SearchSource.xtream));
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    return UnifiedSearchResult(items: items);
  }

  UnifiedSearchResult _mergeAndRank(
    UnifiedSearchResult local,
    UnifiedSearchResult remote,
    String query,
  ) {
    final allItems = <SearchItem>[
      ...local.items,
      ...remote.items,
    ];

    final seenIds = <String>{};
    final uniqueItems = <SearchItem>[];

    for (final item in allItems) {
      final key = '${item.type}_${item.id}';
      if (!seenIds.contains(key)) {
        seenIds.add(key);
        final scoredItem = item.copyWith(score: _calculateScore(query, item));
        uniqueItems.add(scoredItem);
      }
    }

    uniqueItems.sort((a, b) => b.score.compareTo(a.score));
    return UnifiedSearchResult(items: uniqueItems);
  }

  void _enrichAsync(List<SearchItem> items) {
    unawaited(_enrichItems(items));
  }

  Future<void> _enrichItems(List<SearchItem> items) async {
    for (final item in items.take(10)) {
      try {
        if (item.type == SearchType.vod && item.originalObject is Movie) {
          final movie = item.originalObject as Movie;
          if (movie.year > 0) {
            final tmdbId =
                await _tmdb.searchMovieId(movie.title, year: movie.year);
            if (tmdbId != null) {
              final detail = await _tmdb.getMovieDetail(tmdbId);
              if (detail != null && detail.posterUrl.isNotEmpty) {
                final index = items.indexOf(item);
                if (index != -1) {
                  items[index] = item.copyWith(posterUrl: detail.posterUrl);
                }
              }
            }
          }
        } else if (item.type == SearchType.series &&
            item.originalObject is Series) {
          final series = item.originalObject as Series;
          if (series.year > 0) {
            final tvmazeId = await _tvmaze.searchShowId(series.title);
            if (tvmazeId != null) {
              final detail = await _tvmaze.getShowDetail(tvmazeId);
              if (detail != null && detail.coverUrl.isNotEmpty) {
                final index = items.indexOf(item);
                if (index != -1) {
                  items[index] = item.copyWith(posterUrl: detail.coverUrl);
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.warning('Enrichment failed for ${item.title}: $e');
      }
    }
  }

  Stream<List<SearchSuggestion>> suggestions(String query) async* {
    if (query.trim().length < 2) {
      yield [];
      return;
    }

    final normalized = _normalize(query);
    final history = await getHistory();

    final historySuggestions = history
        .where((h) => _normalize(h).contains(normalized))
        .take(5)
        .map((h) => SearchSuggestion(text: h, isHistory: true))
        .toList();

    yield historySuggestions;

    try {
      final apiResult = await _api.search(normalized);
      final apiSuggestions = <SearchSuggestion>[];

      for (final item
          in apiResult.items.where((i) => i.type == SearchType.live).take(3)) {
        apiSuggestions
            .add(SearchSuggestion(text: item.title, type: SearchType.live));
      }
      for (final item
          in apiResult.items.where((i) => i.type == SearchType.vod).take(3)) {
        apiSuggestions
            .add(SearchSuggestion(text: item.title, type: SearchType.vod));
      }
      for (final item in apiResult.items
          .where((i) => i.type == SearchType.series)
          .take(3)) {
        apiSuggestions
            .add(SearchSuggestion(text: item.title, type: SearchType.series));
      }

      if (apiSuggestions.isNotEmpty) {
        yield [...historySuggestions, ...apiSuggestions];
      }
    } catch (_) {
      yield historySuggestions;
    }
  }

  Future<void> addToHistory(String query) async {
    if (_historyBox == null) await _initHistoryBox();
    if (_historyBox == null) return;

    final normalized = _normalize(query);
    if (normalized.length < 2) return;

    final existingKeys = <dynamic>[];
    for (final key in _historyBox!.keys) {
      final entry = _historyBox!.get(key);
      if (entry != null && entry.query == normalized) {
        existingKeys.add(key);
      }
    }
    for (final key in existingKeys) {
      await _historyBox!.delete(key);
    }

    final entry = SearchHistoryEntry(
      query: normalized,
      timestamp: DateTime.now(),
      resultCount: 0,
    );

    await _historyBox!.add(entry);

    if (_historyBox!.length > _maxHistoryEntries) {
      var oldestKey = _historyBox!.keys.first;
      var oldestEntry = _historyBox!.get(oldestKey);
      for (final key in _historyBox!.keys) {
        final entry = _historyBox!.get(key);
        if (entry != null &&
            oldestEntry != null &&
            entry.timestamp.isBefore(oldestEntry.timestamp)) {
          oldestKey = key;
          oldestEntry = entry;
        }
      }
      await _historyBox!.delete(oldestKey);
    }
  }

  Future<List<String>> getHistory() async {
    if (_historyBox == null) await _initHistoryBox();
    if (_historyBox == null) return [];

    final entries = _historyBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return entries.map((e) => e.query).toList();
  }

  Future<void> clearHistory() async {
    if (_historyBox != null) {
      await _historyBox!.clear();
    }
  }

  Future<List<SearchItem>> _getFavorites() async {
    try {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchItem>> _getRecentlyWatched() async {
    try {
      return [];
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    if (_historyBox != null && _historyBox!.isOpen) {
      _historyBox!.close();
    }
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

extension UnifiedSearchResultCopyWith on UnifiedSearchResult {
  UnifiedSearchResult copyWith({
    List<SearchItem>? items,
    bool? isOffline,
    DateTime? timestamp,
  }) {
    return UnifiedSearchResult(
      items: items ?? this.items,
      isOffline: isOffline ?? this.isOffline,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
