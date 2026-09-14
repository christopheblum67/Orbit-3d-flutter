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
  final List<int> genreIds; // IDs des genres TMDB

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
    this.genreIds = const [],
  });

  static const String _imageBase = 'https://image.tmdb.org/t/p';

  String get posterUrl =>
      posterPath.isNotEmpty ? '$_imageBase/w342$posterPath' : '';

  String get backdropUrl =>
      backdropPath.isNotEmpty ? '$_imageBase/w780$backdropPath' : '';

  /// Genres TMDB (id → nom fr) pour films et séries.
  static const Map<int, String> _genres = {
    28: 'Action',
    12: 'Aventure',
    16: 'Animation',
    35: 'Comédie',
    80: 'Crime',
    99: 'Documentaire',
    18: 'Drame',
    10751: 'Familial',
    14: 'Fantastique',
    36: 'Histoire',
    27: 'Horreur',
    10402: 'Musique',
    9648: 'Mystère',
    10749: 'Romance',
    878: 'Science-fiction',
    10770: 'Téléfilm',
    53: 'Thriller',
    10752: 'Guerre',
    37: 'Western',
    10759: 'Action & Aventure',
    10762: 'Enfants',
    10763: 'Actualités',
    10764: 'Téléréalité',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Feuilleton',
    10767: 'Talk-show',
    10768: 'Guerre & Politique',
  };

  /// Genres résolus en français (au plus 2) depuis `genreIds`.
  String get genreLabel {
    final names = genreIds
        .map((id) => _genres[id])
        .whereType<String>()
        .toList();
    return names.take(2).join(' / ');
  }

  /// Nombre de votes formaté (ex: 2.5K).
  String get voteCountLabel {
    if (voteCount <= 0) return '';
    if (voteCount >= 1000) {
      final k = voteCount / 1000;
      return k >= 100 ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$voteCount';
  }

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
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
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
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }

  static int _parseYear(String? date) {
    if (date == null || date.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(date);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}
