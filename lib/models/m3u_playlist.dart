import 'dart:convert';

import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class M3uPlaylist {
  const M3uPlaylist({
    required this.channels,
    required this.radios,
    required this.movies,
    required this.series,
  });

  final List<Channel> channels;
  final List<Channel> radios;
  final List<Movie> movies;
  final List<Series> series;
}

class M3uPlaylistParser {
  static final _episodePattern = RegExp(
    r'^(.*?)\s*(?:[-._ ]*)S(\d{1,2})\s*[-._ ]*E(\d{1,3})(?:\s*[-._ ]*(.*))?$',
    caseSensitive: false,
  );
  static final _alternateEpisodePattern = RegExp(
    r'^(.*?)\s*(?:[-._ ]*)(\d{1,2})x(\d{1,3})(?:\s*[-._ ]*(.*))?$',
    caseSensitive: false,
  );
  static final _labeledEpisodePattern = RegExp(
    r'^(.*?)\s+(?:season|saison)\s*(\d{1,2})\s*[-._ ]*'
    r'(?:episode|épisode|ep|e)\s*(\d{1,3})(?:\s*[-._ ]*(.*))?$',
    caseSensitive: false,
  );
  static final _yearPattern = RegExp(r'\s*[\[(](19|20)\d{2}[\])]\s*$');
  static final _movieGroupPattern = RegExp(
    r'(^|[\s|,/()_\-–])(movie|movies|film|films|vod|cinema|cin[eé]ma)([\s|,/()_\-–]|$)',
    caseSensitive: false,
  );
  static final _seriesGroupPattern = RegExp(
    r'(^|[\s|,/()_\-–])(series|serie|s[eé]ries|tv\s*shows?|shows?|episodes?)([\s|,/()_\-–]|$)',
    caseSensitive: false,
  );
  static final _radioGroupPattern = RegExp(
    r'(^|[\s|,/()_\-–])(radio|radios|audio|musique|music)([\s|,/()_\-–]|$)',
    caseSensitive: false,
  );
  static final _liveGroupPattern = RegExp(
    r'(^|[\s|,/()_\-–])(live|iptv|channels?|cha[iî]nes?|tv)([\s|,/()_\-–]|$)',
    caseSensitive: false,
  );
  static final _movieExtensionPattern = RegExp(
    r'\.(mkv|mp4|avi|mov|wmv|mpg|mpeg|m4v|flv)$',
    caseSensitive: false,
  );

  static M3uPlaylist parse(String content) {
    final channels = <Channel>[];
    final radios = <Channel>[];
    final movies = <Movie>[];
    final seriesEntries = <_SeriesEntry>[];
    _M3uEntry? pending;

    void addEntry(_M3uEntry entry) {
      if (entry.name.trim().isEmpty) return;
      switch (_classify(entry)) {
        case _M3uKind.live:
          channels.add(
            Channel(
              id: 'm3u-live-${channels.length}',
              name: entry.name,
              logoUrl: entry.logo,
              streamUrl: entry.url,
              group: entry.group,
              categoryId: entry.group,
              epgChannelId: entry.attributes['tvg-id'] ?? '',
              supportsReplay: (entry.catchupMode.isNotEmpty &&
                      entry.catchupMode != 'none') ||
                  entry.catchupSource.isNotEmpty ||
                  entry.catchupDays > 0 ||
                  entry.timeshift > 0,
              timeshift: Duration(seconds: entry.timeshift),
              archiveDays: entry.catchupDays,
              catchupMode: entry.catchupMode,
              catchupSource: entry.catchupSource,
            ),
          );
        case _M3uKind.radio:
          radios.add(
            Channel(
              id: 'm3u-radio-${radios.length}',
              name: entry.name,
              logoUrl: entry.logo,
              streamUrl: entry.url,
              group: entry.group,
              categoryId: entry.group,
              epgChannelId: entry.attributes['tvg-id'] ?? '',
            ),
          );
        case _M3uKind.movie:
          final yearMatch = _yearPattern.firstMatch(entry.name);
          final year = yearMatch == null
              ? 0
              : int.tryParse(
                    yearMatch.group(0)!.replaceAll(RegExp(r'\D'), ''),
                  ) ??
                  0;
          final title = yearMatch == null
              ? entry.name
              : entry.name.substring(0, yearMatch.start).trim();
          movies.add(
            Movie(
              id: 'm3u-movie-${movies.length}',
              title: title.isEmpty ? entry.name : title,
              description: '',
              posterUrl: entry.logo,
              year: year,
              genre: entry.group,
              director: '',
              rating: 0,
              pegi: '',
              streamId: entry.url,
              categoryId: entry.group,
            ),
          );
        case _M3uKind.series:
          seriesEntries.add(_SeriesEntry(entry, seriesEntries.length));
      }
    }

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim().replaceFirst('\uFEFF', '');
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTINF')) {
        pending = _parseInfo(line);
      } else if (line.startsWith('#EXTGRP:') && pending != null) {
        pending = pending.withGroup(line.substring('#EXTGRP:'.length).trim());
      } else if (!line.startsWith('#') && pending != null) {
        addEntry(pending.withUrl(line));
        pending = null;
      }
    }

    return M3uPlaylist(
      channels: channels,
      radios: radios,
      movies: movies,
      series: _groupSeries(seriesEntries),
    );
  }

  static _M3uEntry _parseInfo(String line) {
    final comma = _titleSeparator(line);
    final metadata = comma < 0 ? line : line.substring(0, comma);
    final attributes = <String, String>{
      for (final match in RegExp(r'([\w-]+)="([^"]*)"').allMatches(metadata))
        match.group(1)!.toLowerCase(): match.group(2)!.trim(),
    };
    final title = comma < 0 ? '' : line.substring(comma + 1).trim();
    return _M3uEntry(
      name: (title.isNotEmpty ? title : attributes['tvg-name'] ?? '').trim(),
      displayName: title,
      logo: attributes['tvg-logo'] ?? '',
      group: attributes['group-title'] ?? '',
      type: attributes['tvg-type'] ??
          attributes['content-type'] ??
          attributes['media-type'] ??
          attributes['type'] ??
          '',
      attributes: attributes,
      catchupMode: (attributes['catchup'] ?? '').toLowerCase(),
      catchupSource: attributes['catchup-source'] ?? '',
      catchupDays: int.tryParse(attributes['catchup-days'] ?? '') ?? 0,
      timeshift: int.tryParse(attributes['timeshift'] ?? '') ?? 0,
    );
  }

  static int _titleSeparator(String line) {
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == '"') inQuotes = !inQuotes;
      if (line[i] == ',' && !inQuotes) return i;
    }
    return -1;
  }

  static _M3uKind _classify(_M3uEntry entry) {
    final type = entry.type.trim().toLowerCase();
    if (type.contains('radio') || type == 'audio') {
      return _M3uKind.radio;
    }
    if (type.contains('series') ||
        type.contains('episode') ||
        type.contains('tvshow') ||
        type.contains('tv-show')) {
      return _M3uKind.series;
    }
    if (type.contains('movie') || type.contains('film') || type == 'vod') {
      return _M3uKind.movie;
    }
    if (type == 'live' || type == 'tv' || type == 'channel') {
      return _M3uKind.live;
    }

    if (_episodeInfo(entry) != null) {
      return _M3uKind.series;
    }

    final group = entry.group.trim();
    if (_radioGroupPattern.hasMatch(group)) return _M3uKind.radio;
    if (_seriesGroupPattern.hasMatch(group)) return _M3uKind.series;
    if (_movieGroupPattern.hasMatch(group)) return _M3uKind.movie;
    if (_liveGroupPattern.hasMatch(group)) return _M3uKind.live;

    final pathSegments = Uri.tryParse(entry.url)
            ?.pathSegments
            .map((segment) => segment.toLowerCase())
            .toSet() ??
        const <String>{};
    if (pathSegments.contains('radio') || pathSegments.contains('audio')) {
      return _M3uKind.radio;
    }
    if (pathSegments.contains('series') ||
        pathSegments.contains('episode') ||
        pathSegments.contains('episodes')) {
      return _M3uKind.series;
    }
    if (pathSegments.contains('movie') ||
        pathSegments.contains('movies') ||
        pathSegments.contains('vod')) {
      return _M3uKind.movie;
    }
    if (pathSegments.contains('live')) return _M3uKind.live;

    if (_movieExtensionPattern.hasMatch(Uri.tryParse(entry.url)?.path ?? '')) {
      return _M3uKind.movie;
    }
    if (_yearPattern.hasMatch(entry.name)) return _M3uKind.movie;
    if (type == 'video') return _M3uKind.movie;
    return _M3uKind.live;
  }

  static List<Series> _groupSeries(List<_SeriesEntry> entries) {
    final grouped = <String, List<_SeriesEntry>>{};
    for (final item in entries) {
      final episode = _episodeInfo(item.entry);
      final showTitle = episode?.showTitle.isNotEmpty == true
          ? episode!.showTitle
          : _seriesName(item.entry);
      final key = _seriesKey(showTitle);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries.map((group) {
      final first = group.value.first.entry;
      final firstSeriesName = _seriesName(first);
      final firstEpisode = _episodeInfo(first);
      final title = _firstNonEmpty([
        first.attributes['series-name'],
        first.attributes['show-name'],
        firstEpisode?.showTitle,
        firstSeriesName,
      ]);
      final episodes = <Episode>[];
      var fallbackEpisodeNumber = 0;
      for (final item in group.value) {
        final parsed = _episodeInfo(item.entry);
        final seriesName = _seriesName(item.entry);
        final episodeTitle = _firstNonEmpty([
          parsed?.episodeTitle,
          item.entry.attributes['episode-title'],
          seriesName,
        ]);
        final url = item.entry.url;
        fallbackEpisodeNumber++;
        episodes.add(
          Episode(
            id: 'm3u-episode-${item.index}',
            title: episodeTitle,
            season: parsed?.season ?? 1,
            episodeNumber: parsed?.episodeNumber ?? fallbackEpisodeNumber,
            streamUrl: url,
          ),
        );
      }
      episodes.sort((a, b) {
        final seasonOrder = a.season.compareTo(b.season);
        return seasonOrder != 0
            ? seasonOrder
            : a.episodeNumber.compareTo(b.episodeNumber);
      });
      return Series(
        id: 'm3u-series-${base64Url.encode(utf8.encode(group.key)).replaceAll('=', '')}',
        title: title,
        description: '',
        coverUrl: first.logo,
        year: 0,
        genre: first.group,
        director: '',
        rating: 0,
        pegi: '',
        episodes: episodes,
        categoryId: first.group,
      );
    }).toList(growable: false);
  }

  static _EpisodeName? _parseEpisode(String name) {
    final match = _episodePattern.firstMatch(name) ??
        _alternateEpisodePattern.firstMatch(name) ??
        _labeledEpisodePattern.firstMatch(name);
    if (match == null) return null;
    return _EpisodeName(
      showTitle:
          match.group(1)!.trim().replaceAll(RegExp(r'[-._]+$'), '').trim(),
      season: int.tryParse(match.group(2)!) ?? 1,
      episodeNumber: int.tryParse(match.group(3)!) ?? 1,
      episodeTitle: (match.group(4) ?? '').trim().replaceAll(
            RegExp(r'^[-._ ]+'),
            '',
          ),
    );
  }

  static String _seriesName(_M3uEntry entry) {
    final displayName = entry.name;
    if (_hasEpisodePattern(displayName)) return displayName;
    final tvgName = entry.attributes['tvg-name'] ?? '';
    if (_hasEpisodePattern(tvgName)) return tvgName;
    return _firstNonEmpty([
      entry.attributes['series-name'],
      entry.attributes['show-name'],
      tvgName,
      displayName,
    ]);
  }

  static _EpisodeName? _episodeInfo(_M3uEntry entry) {
    final named = _parseEpisode(entry.name) ??
        _parseEpisode(entry.attributes['tvg-name'] ?? '');
    if (named != null) return named;

    final season = _positiveInt([
      entry.attributes['season'],
      entry.attributes['season-num'],
      entry.attributes['season_number'],
    ]);
    final episode = _positiveInt([
      entry.attributes['episode'],
      entry.attributes['episode-num'],
      entry.attributes['episode_num'],
      entry.attributes['episode-number'],
      entry.attributes['episode_number'],
    ]);
    if (episode == null ||
        (season == null &&
            entry.attributes['series-name'] == null &&
            entry.attributes['show-name'] == null)) {
      return null;
    }

    final showTitle = _firstNonEmpty([
      entry.attributes['series-name'],
      entry.attributes['show-name'],
      entry.attributes['tvg-name'],
    ]);
    return _EpisodeName(
      showTitle: showTitle,
      season: season ?? 1,
      episodeNumber: episode,
      episodeTitle: _firstNonEmpty([
        entry.attributes['episode-title'],
        entry.name,
      ]),
    );
  }

  static int? _positiveInt(Iterable<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final match = RegExp(r'\d+').firstMatch(value);
      final number = match == null ? null : int.tryParse(match.group(0)!);
      if (number != null && number > 0) return number;
    }
    return null;
  }

  static String _seriesKey(String title) =>
      title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static bool _hasEpisodePattern(String name) =>
      _episodePattern.hasMatch(name) ||
      _alternateEpisodePattern.hasMatch(name) ||
      _labeledEpisodePattern.hasMatch(name);
}

enum _M3uKind { live, radio, movie, series }

class _M3uEntry {
  const _M3uEntry({
    required this.name,
    required this.displayName,
    required this.logo,
    required this.group,
    required this.type,
    required this.attributes,
    required this.catchupMode,
    required this.catchupSource,
    required this.catchupDays,
    required this.timeshift,
    this.url = '',
  });

  final String name;
  final String displayName;
  final String logo;
  final String group;
  final String type;
  final Map<String, String> attributes;
  final String catchupMode;
  final String catchupSource;
  final int catchupDays;
  final int timeshift;
  final String url;

  _M3uEntry withUrl(String streamUrl) => _M3uEntry(
        name: name.isEmpty ? displayName : name,
        displayName: displayName,
        logo: logo,
        group: group,
        type: type,
        attributes: attributes,
        catchupMode: catchupMode,
        catchupSource: catchupSource,
        catchupDays: catchupDays,
        timeshift: timeshift,
        url: stream_helpers.requireStreamUrl(
          streamUrl,
          label: name.isEmpty ? displayName : name,
        ),
      );

  _M3uEntry withGroup(String groupTitle) => _M3uEntry(
        name: name,
        displayName: displayName,
        logo: logo,
        group: group.isNotEmpty ? group : groupTitle,
        type: type,
        attributes: attributes,
        catchupMode: catchupMode,
        catchupSource: catchupSource,
        catchupDays: catchupDays,
        timeshift: timeshift,
        url: url,
      );
}

class _SeriesEntry {
  const _SeriesEntry(this.entry, this.index);

  final _M3uEntry entry;
  final int index;
}

class _EpisodeName {
  const _EpisodeName({
    required this.showTitle,
    required this.season,
    required this.episodeNumber,
    required this.episodeTitle,
  });

  final String showTitle;
  final int season;
  final int episodeNumber;
  final String episodeTitle;
}
