import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';

enum SearchType {
  live,
  vod,
  series,
  replay,
  epg,
}

enum SearchSource {
  local,
  xtream,
  tmdb,
  tvmaze,
}

class SearchItem {
  final String id;
  final SearchType type;
  final String title;
  final String subtitle;
  final String posterUrl;
  final String? streamUrl;
  final String? categoryId;
  final double score;
  final SearchSource source;
  final dynamic originalObject;

  SearchItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.posterUrl,
    this.streamUrl,
    this.categoryId,
    required this.score,
    required this.source,
    this.originalObject,
  });

  factory SearchItem.fromChannel(Channel channel,
      {double score = 1.0, SearchSource source = SearchSource.xtream,}) {
    return SearchItem(
      id: channel.id,
      type: SearchType.live,
      title: channel.name,
      subtitle: channel.groupLabel,
      posterUrl: channel.logoUrl,
      streamUrl: channel.streamUrl,
      categoryId: channel.categoryId,
      score: score,
      source: source,
      originalObject: channel,
    );
  }

  factory SearchItem.fromMovie(Movie movie,
      {double score = 1.0, SearchSource source = SearchSource.xtream,}) {
    return SearchItem(
      id: movie.id,
      type: SearchType.vod,
      title: movie.title,
      subtitle:
          '${movie.year > 0 ? movie.year : ''} ${movie.genre.isNotEmpty ? '· ${movie.genre}' : ''}'
              .trim(),
      posterUrl: movie.posterUrl,
      streamUrl: movie.streamUrl,
      categoryId: movie.categoryId,
      score: score,
      source: source,
      originalObject: movie,
    );
  }

  factory SearchItem.fromSeries(Series series,
      {double score = 1.0, SearchSource source = SearchSource.xtream,}) {
    return SearchItem(
      id: series.id,
      type: SearchType.series,
      title: series.title,
      subtitle:
          '${series.year > 0 ? series.year : ''} ${series.genre.isNotEmpty ? '· ${series.genre}' : ''}'
              .trim(),
      posterUrl: series.coverUrl,
      streamUrl: null,
      categoryId: series.categoryId,
      score: score,
      source: source,
      originalObject: series,
    );
  }

  factory SearchItem.fromReplay(ReplayItem replay,
      {double score = 1.0, SearchSource source = SearchSource.xtream,}) {
    return SearchItem(
      id: replay.id,
      type: SearchType.replay,
      title: replay.title,
      subtitle: '${replay.startTime} → ${replay.endTime}',
      posterUrl: '',
      streamUrl: replay.streamUrl,
      categoryId: replay.categoryId,
      score: score,
      source: source,
      originalObject: replay,
    );
  }

  factory SearchItem.fromEpg(EPGProgram program,
      {double score = 1.0, SearchSource source = SearchSource.xtream,}) {
    return SearchItem(
      id: '${program.channelId}_${program.start.millisecondsSinceEpoch}',
      type: SearchType.epg,
      title: program.title,
      subtitle:
          '${program.channelId} · ${program.start.toString().substring(11, 16)}–${program.end.toString().substring(11, 16)}',
      posterUrl: '',
      streamUrl: null,
      categoryId: null,
      score: score,
      source: source,
      originalObject: program,
    );
  }

  String get typeLabel {
    return switch (type) {
      SearchType.live => 'Live',
      SearchType.vod => 'Films',
      SearchType.series => 'Séries',
      SearchType.replay => 'Replay',
      SearchType.epg => 'EPG',
    };
  }

  IconData get typeIcon {
    return switch (type) {
      SearchType.live => Icons.live_tv,
      SearchType.vod => Icons.movie,
      SearchType.series => Icons.tv,
      SearchType.replay => Icons.replay,
      SearchType.epg => Icons.schedule,
    };
  }
}

class SearchSuggestion {
  final String text;
  final SearchType? type;
  final bool isHistory;

  SearchSuggestion({
    required this.text,
    this.type,
    this.isHistory = false,
  });
}

class UnifiedSearchResult {
  final List<SearchItem> items;
  final bool isOffline;
  final DateTime timestamp;

  UnifiedSearchResult({
    required this.items,
    this.isOffline = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory UnifiedSearchResult.empty() {
    return UnifiedSearchResult(items: []);
  }

  UnifiedSearchResult take(int limit) {
    return UnifiedSearchResult(
      items: items.take(limit).toList(),
      isOffline: isOffline,
      timestamp: timestamp,
    );
  }

  int get count => items.length;

  List<SearchItem> getByType(SearchType type) {
    return items.where((item) => item.type == type).toList();
  }

  Map<SearchType, List<SearchItem>> get groupedByType {
    final map = <SearchType, List<SearchItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.type, () => []).add(item);
    }
    return map;
  }
}

class SearchHistoryEntry {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  SearchHistoryEntry({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'resultCount': resultCount,
    };
  }

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      query: map['query'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      resultCount: map['resultCount'] as int,
    );
  }
}
