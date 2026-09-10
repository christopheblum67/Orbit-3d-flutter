/// Entrée légère d'un classement Trakt (films/séries populaires/tendances).
/// Utilisée dans l'onglet FlixPatrol de Parcourir.
class TraktRankEntry {
  final int traktId;
  final int tmdbId;
  final String imdbId;
  final String slug;
  final String title;
  final String posterUrl;
  final String backdropUrl;
  final int year;
  final double rating;
  final int voteCount;
  final String overview;
  final bool isTv;
  final int watchers;
  final List<String> genres;
  final int runtime;
  final String certification;
  final String tagline;
  final String trailerUrl;
  final String network;

  const TraktRankEntry({
    this.traktId = 0,
    this.tmdbId = 0,
    this.imdbId = '',
    this.slug = '',
    required this.title,
    this.posterUrl = '',
    this.backdropUrl = '',
    this.year = 0,
    this.rating = 0,
    this.voteCount = 0,
    this.overview = '',
    this.isTv = false,
    this.watchers = 0,
    this.genres = const [],
    this.runtime = 0,
    this.certification = '',
    this.tagline = '',
    this.trailerUrl = '',
    this.network = '',
  });

  factory TraktRankEntry.fromMovieJson(Map<String, dynamic> json) =>
      _fromMediaJson(json, isTv: false, watchers: 0);

  factory TraktRankEntry.fromShowJson(Map<String, dynamic> json) =>
      _fromMediaJson(json, isTv: true, watchers: 0);

  factory TraktRankEntry.fromTrendingMovieJson(Map<String, dynamic> wrapper) {
    final movie = Map<String, dynamic>.from(wrapper['movie'] as Map? ?? {});
    return _fromMediaJson(
      movie,
      isTv: false,
      watchers: wrapper['watchers'] as int? ?? 0,
    );
  }

  factory TraktRankEntry.fromTrendingShowJson(Map<String, dynamic> wrapper) {
    final show = Map<String, dynamic>.from(wrapper['show'] as Map? ?? {});
    return _fromMediaJson(
      show,
      isTv: true,
      watchers: wrapper['watchers'] as int? ?? 0,
    );
  }

  static TraktRankEntry _fromMediaJson(
    Map<String, dynamic> json, {
    required bool isTv,
    required int watchers,
  }) {
    final ids = Map<String, dynamic>.from(json['ids'] as Map? ?? {});
    final images = Map<String, dynamic>.from(json['images'] as Map? ?? {});
    final posters = (images['poster'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final fanarts = (images['fanart'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .map((g) => g.toString())
        .where((g) => g.isNotEmpty)
        .toList();
    final dateStr = json[isTv ? 'first_aired' : 'released'] as String?;

    return TraktRankEntry(
      traktId: ids['trakt'] as int? ?? 0,
      tmdbId: ids['tmdb'] as int? ?? 0,
      imdbId: ids['imdb'] as String? ?? '',
      slug: ids['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      posterUrl: posters.isNotEmpty ? posters.first : '',
      backdropUrl: fanarts.isNotEmpty ? fanarts.first : '',
      year: _parseYear(dateStr),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      voteCount: json['votes'] as int? ?? 0,
      overview: json['overview'] as String? ?? '',
      isTv: isTv,
      watchers: watchers,
      genres: genres,
      runtime: json['runtime'] as int? ?? 0,
      certification: json['certification'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      trailerUrl: json['trailer'] as String? ?? '',
      network: json['network'] as String? ?? '',
    );
  }

  static int _parseYear(String? date) {
    if (date == null || date.isEmpty) return 0;
    final match = RegExp(r'^(\d{4})').firstMatch(date);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}