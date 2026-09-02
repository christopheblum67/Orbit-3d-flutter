import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

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
  });

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
      episodes: (map['episodes'] as List<dynamic>? ?? [])
          .map((e) => Episode.fromMap(e as Map<String, dynamic>))
          .toList(),
      categoryId: map['category_id']?.toString() ?? '',
    );
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
  final String streamUrl;

  Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    required this.streamUrl,
  });

  factory Episode.fromMap(Map<String, dynamic> map) {
    final rawSeason = map['season'];
    final rawEp = map['episode'] ?? map['episode_num'];
    return Episode(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      season: int.tryParse('$rawSeason') ?? 0,
      episodeNumber: int.tryParse('$rawEp') ?? 0,
      streamUrl: map['url']?.toString() ?? '',
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
