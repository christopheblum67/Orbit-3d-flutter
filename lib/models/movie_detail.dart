import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

/// Modèle enrichi pour les détails d'un film (VOD)
/// Étend les données Xtream avec métadonnées TMDB/TVmaze/OMDB/IA
class MovieDetail {
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
  final List<Actor> cast;
  final List<CrewMember> crew;

  // Nouvelles métadonnées enrichies
  final String imdbId;
  final int tmdbId;
  final int tvmazeId;
  final int runtime; // en minutes
  final List<String> keywords;
  final List<String> originCountry;
  final List<String> spokenLanguages;
  final int budget; // en USD
  final int revenue; // en USD
  final String status; // Released, Rumored, etc.
  final String? tagline;
  final int voteCount;
  final List<String> productionCompanies;
  final String? certification;
  final String? trailerUrl; // YouTube URL
  final String? backdropUrl;
  final String? originalLanguage;
  final String? originalTitle;
  final bool aiGenerated;
  final String dataSource; // 'tmdb', 'omdb', 'tvmaze', 'ai', 'xtream'

  MovieDetail({
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
    this.imdbId = '',
    this.tmdbId = 0,
    this.tvmazeId = 0,
    this.runtime = 0,
    this.keywords = const [],
    this.originCountry = const [],
    this.spokenLanguages = const [],
    this.budget = 0,
    this.revenue = 0,
    this.status = '',
    this.tagline,
    this.voteCount = 0,
    this.productionCompanies = const [],
    this.certification,
    this.trailerUrl,
    this.backdropUrl,
    this.originalLanguage,
    this.originalTitle,
    this.aiGenerated = false,
    this.dataSource = 'xtream',
  });

  /// Crée un MovieDetail à partir d'un Movie (données Xtream de base)
  factory MovieDetail.fromMovie(Movie movie) {
    return MovieDetail(
      id: movie.id,
      title: movie.title,
      description: movie.description,
      posterUrl: movie.posterUrl,
      year: movie.year,
      genre: movie.genre,
      director: movie.director,
      rating: movie.rating,
      pegi: movie.pegi,
      streamUrl: movie.streamUrl,
      categoryId: movie.categoryId,
      cast: movie.cast,
      crew: movie.crew,
      dataSource: 'xtream',
    );
  }

  /// Vérifie si des champs critiques manquent (pour déclencher les fallbacks)
  bool get needsEnrichment {
    return year == 0 ||
        genre.isEmpty ||
        director.isEmpty ||
        runtime == 0 ||
        cast.isEmpty ||
        imdbId.isEmpty;
  }

  /// Vérifie si le fallback IA est nécessaire (toutes APIs externes échouées)
  bool get needsAiFallback {
    return (year == 0 ||
            genre.isEmpty ||
            director.isEmpty ||
            runtime == 0 ||
            cast.isEmpty) &&
        !dataSource.startsWith('ai');
  }

  MovieDetail copyWith({
    String? id,
    String? title,
    String? description,
    String? posterUrl,
    int? year,
    String? genre,
    String? director,
    double? rating,
    String? pegi,
    String? streamUrl,
    String? categoryId,
    List<Actor>? cast,
    List<CrewMember>? crew,
    String? imdbId,
    int? tmdbId,
    int? tvmazeId,
    int? runtime,
    List<String>? keywords,
    List<String>? originCountry,
    List<String>? spokenLanguages,
    int? budget,
    int? revenue,
    String? status,
    String? tagline,
    int? voteCount,
    List<String>? productionCompanies,
    String? certification,
    String? trailerUrl,
    String? backdropUrl,
    String? originalLanguage,
    String? originalTitle,
    bool? aiGenerated,
    String? dataSource,
  }) {
    return MovieDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      director: director ?? this.director,
      rating: rating ?? this.rating,
      pegi: pegi ?? this.pegi,
      streamUrl: streamUrl ?? this.streamUrl,
      categoryId: categoryId ?? this.categoryId,
      cast: cast ?? this.cast,
      crew: crew ?? this.crew,
      imdbId: imdbId ?? this.imdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      tvmazeId: tvmazeId ?? this.tvmazeId,
      runtime: runtime ?? this.runtime,
      keywords: keywords ?? this.keywords,
      originCountry: originCountry ?? this.originCountry,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      budget: budget ?? this.budget,
      revenue: revenue ?? this.revenue,
      status: status ?? this.status,
      tagline: tagline ?? this.tagline,
      voteCount: voteCount ?? this.voteCount,
      productionCompanies: productionCompanies ?? this.productionCompanies,
      certification: certification ?? this.certification,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      originalTitle: originalTitle ?? this.originalTitle,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  @override
  String toString() {
    return 'MovieDetail(id: $id, title: $title, year: $year, tmdbId: $tmdbId, imdbId: $imdbId, dataSource: $dataSource, aiGenerated: $aiGenerated)';
  }

  String? get pegiLabel => ageBadgeLabel(pegi);
}
