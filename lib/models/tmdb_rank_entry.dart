/// Entrée légère d'un classement TMDB (films/séries populaires/tendances).
/// Utilisée dans l'onglet FlixPatrol de Parcourir.
class TmdbRankEntry {
  final int tmdbId;
  final String title;
  final String posterPath;
  final String backdropPath;
  final int year;
  final double rating;
  final int voteCount;
  final String overview;
  final bool isTv;
  final double popularity;

  const TmdbRankEntry({
    required this.tmdbId,
    required this.title,
    required this.posterPath,
    this.backdropPath = '',
    this.year = 0,
    this.rating = 0,
    this.voteCount = 0,
    this.overview = '',
    this.isTv = false,
    this.popularity = 0,
  });

  static const String _imageBase = 'https://image.tmdb.org/t/p';

  String get posterUrl =>
      posterPath.isNotEmpty ? '$_imageBase/w342$posterPath' : '';

  String get backdropUrl =>
      backdropPath.isNotEmpty ? '$_imageBase/w780$backdropPath' : '';

  factory TmdbRankEntry.fromMovieJson(Map<String, dynamic> json) {
    return TmdbRankEntry(
      tmdbId: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String? ?? '',
      year: _parseYear(json['release_date']),
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      overview: json['overview'] as String? ?? '',
      isTv: false,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    );
  }

  factory TmdbRankEntry.fromTvJson(Map<String, dynamic> json) {
    return TmdbRankEntry(
      tmdbId: json['id'] as int? ?? 0,
      title: json['name'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String? ?? '',
      year: _parseYear(json['first_air_date']),
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      overview: json['overview'] as String? ?? '',
      isTv: true,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    );
  }

  static int _parseYear(String? date) {
    if (date == null || date.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(date);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}
