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
    final names =
        genreIds.map((id) => _genres[id]).whereType<String>().toList();
    return names.take(2).join(' / ');
  }

  /// **Tous** les genres résolus en français, joints par « , » (ex :
  /// « Horreur, Mystère, Science-fiction »).
  ///
  /// Contrairement à [genreLabel] (2 genres max, pour l'affichage compact), la
  /// liste complète est destinée au scoring d'affinité : plus de genres
  /// augmentent la probabilité de rejoindre les genres favoris du profil.
  String get genreNames {
    final names = genreIds.map((id) => _genres[id]).whereType<String>();
    return names.join(', ');
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

  /// Conversions tolérantes : la réponse TMDB transite par le cache Hive (non
  /// typé) et par des panels qui sérialisent les nombres en chaînes. Les casts
  /// stricts makesaient échouer tout le classement FlixPatrol, donc le signal
  /// « recommandation » du matchmaking de groupe.
  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static double _asDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static String _asStr(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return '$v';
  }

  static List<int> _asIntList(Object? v) {
    if (v is! List) return const <int>[];
    final out = <int>[];
    for (final e in v) {
      final i = _asInt(e);
      if (i > 0) out.add(i);
    }
    return out;
  }

  factory TmdbRankEntry.fromMovieJson(Map<String, dynamic> json) {
    return TmdbRankEntry(
      tmdbId: _asInt(json['id']),
      title: _asStr(json['title']),
      posterPath: _asStr(json['poster_path']),
      backdropPath: _asStr(json['backdrop_path']),
      year: _parseYear(_asStr(json['release_date'])),
      rating: _asDouble(json['vote_average']),
      voteCount: _asInt(json['vote_count']),
      overview: _asStr(json['overview']),
      isTv: false,
      popularity: _asDouble(json['popularity']),
      genreIds: _asIntList(json['genre_ids']),
    );
  }

  factory TmdbRankEntry.fromTvJson(Map<String, dynamic> json) {
    return TmdbRankEntry(
      tmdbId: _asInt(json['id']),
      title: _asStr(json['name']),
      posterPath: _asStr(json['poster_path']),
      backdropPath: _asStr(json['backdrop_path']),
      year: _parseYear(_asStr(json['first_air_date'])),
      rating: _asDouble(json['vote_average']),
      voteCount: _asInt(json['vote_count']),
      overview: _asStr(json['overview']),
      isTv: true,
      popularity: _asDouble(json['popularity']),
      genreIds: _asIntList(json['genre_ids']),
    );
  }

  static int _parseYear(String? date) {
    if (date == null || date.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(date);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}
