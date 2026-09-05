import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'cast.dart';

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
  
  // Nouvelles données de casting
  final List<Actor> cast;
  final List<CrewMember> crew;

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
    this.cast = const [],
    this.crew = const [],
  });

  factory Movie.fromMap(Map<String, dynamic> map) {
    final castList = (map['cast'] as List<dynamic>? ?? [])
        .map((e) => Actor.fromMap(e as Map<String, dynamic>))
        .toList();
    final crewList = (map['crew'] as List<dynamic>? ?? [])
        .map((e) => CrewMember.fromMap(e as Map<String, dynamic>))
        .toList();
    castList.sort((a, b) => a.order.compareTo(b.order));
    crewList.sort((a, b) {
      final deptCompare = a.department.compareTo(b.department);
      if (deptCompare != 0) return deptCompare;
      return a.order.compareTo(b.order);
    });

    return Movie(
      id: map['id']?.toString() ?? map['stream_id']?.toString() ?? '',
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
      cast: castList,
      crew: crewList,
    );
  }

  Movie copyWith({
    String? streamUrl,
    String? categoryId,
    List<Actor>? cast,
    List<CrewMember>? crew,
  }) {
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
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);

  String? get pegiLabel => ageBadgeLabel(pegi);
}
