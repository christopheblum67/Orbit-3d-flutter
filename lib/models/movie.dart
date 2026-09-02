import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class Movie {
  final String id;
  final String title;
  final String description;
  final String posterUrl;
  final int year;
  final String genre;
  final String director;
  final double rating;
  final String pegi;
  final String streamUrl;
  final String categoryId;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.rating,
    required this.pegi,
    required this.streamUrl,
    this.categoryId = '',
  });

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: firstNonEmpty([
        map['plot'],
        map['overview'],
        map['description'],
        map['synopsis'],
      ]),
      posterUrl: firstNonEmpty([
        map['poster'],
        map['stream_icon'],
        map['cover'],
        map['backdrop_path'],
      ]),
      year: map['year'] ?? 0,
      genre: map['genre'] ?? '',
      director: map['director'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      pegi: firstNonEmpty([
        map['pegi'],
        map['age'],
        map['mpaa'],
        map['us_certification'],
        map['contentRating'],
      ]),
      streamUrl: map['url'] ?? '',
      categoryId: map['category_id']?.toString() ?? '',
    );
  }

  Movie copyWith({String? streamUrl, String? categoryId}) {
    return Movie(
      id: id,
      title: title,
      description: description,
      posterUrl: posterUrl,
      year: year,
      genre: genre,
      director: director,
      rating: rating,
      pegi: pegi,
      streamUrl: streamUrl ?? this.streamUrl,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);

  String? get pegiLabel => ageBadgeLabel(pegi);
}
