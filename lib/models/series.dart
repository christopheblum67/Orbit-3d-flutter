import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/models/movie.dart';

class Series {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final int year;
  final String genre;
  final String director;
  final double rating;
  final String pegi;
  final List<Episode> episodes;
  final String categoryId;

  // Date d'ajout (Xtream: `added` en secondes Unix)
  final DateTime? addedDate;

  Series({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.rating,
    required this.pegi,
    required this.episodes,
    this.categoryId = '',
    this.addedDate,
  });

  bool get isNew {
    if (addedDate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(addedDate!);
    return diff.inDays <= 30;
  }

  factory Series.fromMap(Map<String, dynamic> map) {
    final rawRating = map['rating'];
    final parsedRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse('$rawRating') ?? 0;
    var parsedYear = 0;
    final rawYear = map['year'] ?? map['releaseDate'] ?? map['air_date'];
    if (rawYear != null) {
      final yearStr = '$rawYear';
      final digits = yearStr.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        parsedYear = int.tryParse(digits.substring(0, 4)) ?? 0;
      }
    }
    DateTime? parseAdded(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000,
              isUtc: true,);
        }
      }
      return null;
    }

    return Series(
      id: map['series_id']?.toString() ?? map['id']?.toString() ?? '',
      title: map['name']?.toString() ?? map['title']?.toString() ?? '',
      description: firstNonEmpty([
        map['plot'],
        map['overview'],
        map['description'],
        map['synopsis'],
      ]),
      coverUrl: firstNonEmpty([
        map['cover'],
        map['poster'],
        map['backdrop_path'],
        map['stream_icon'],
      ]),
      year: parsedYear,
      genre: _joined(map['genre']),
      director: _joined(map['director']),
      rating: parsedRating,
      pegi: firstNonEmpty([
        map['pegi'],
        map['age'],
        map['mpaa'],
        map['contentRating'],
        map['us_certification'],
      ]),
      episodes: parseEpisodes(map['episodes']),
      categoryId: map['category_id']?.toString() ?? '',
      addedDate: parseAdded(map['added']),
    );
  }

  /// `get_series` ne renvoie pas `episodes` (seulement `get_series_info`), et
  /// certains panels renvoient un type inattendu. On ne fait pas echouer la
  /// serie entiere pour une liste d'episodes illisible.
  static List<Episode> parseEpisodes(dynamic raw) {
    if (raw is! List) return <Episode>[];
    final out = <Episode>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(Episode.fromMap(Map<String, dynamic>.from(e)));
        } catch (_) {
          // episode invalide ignore
        }
      }
    }
    return out;
  }

  static String _joined(Object? value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .where((e) => e != null && '$e'.trim().isNotEmpty)
          .map((e) => '$e')
          .join(', ');
    }
    return '$value';
  }

  String? get pegiLabel => ageBadgeLabel(pegi);
}

class Episode {
  final String id;
  final String title;
  final int season;
  final int episodeNumber;
  final String _streamId;

  Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    String? streamId,
    String? streamUrl,
  }) : _streamId = streamUrl ?? streamId ?? '';

  factory Episode.fromMap(Map<String, dynamic> map) {
    final rawSeason = map['season'];
    final rawEp = map['episode'] ?? map['episode_num'];
    return Episode(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      season: int.tryParse('$rawSeason') ?? 0,
      episodeNumber: int.tryParse('$rawEp') ?? 0,
      streamId: map['url']?.toString() ?? '',
    );
  }

  String get streamUrl {
    final ref = _streamId;
    if (ref.isEmpty) return '';
    // URL déjà complète (M3U, timeshift) : on ne la reconstruit pas.
    if (ref.startsWith('http')) return ref;
    return buildStreamUrlGlobal(
      streamId: ref,
      type: 'series',
    ) ?? '';
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
