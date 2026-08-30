import '../services/stream_helpers.dart' as stream_helpers;

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
  });

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      posterUrl: map['poster'] ?? '',
      year: map['year'] ?? 0,
      genre: map['genre'] ?? '',
      director: map['director'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      pegi: map['pegi'] ?? '',
      streamUrl: map['url'] ?? '',
    );
  }

  Movie copyWith({String? streamUrl}) {
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
    );
  }

  String requireStreamUrl() => stream_helpers.requireStreamUrl(streamUrl, label: title);
}
