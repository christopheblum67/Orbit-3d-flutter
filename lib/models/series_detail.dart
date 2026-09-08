import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/cast.dart';

/// Modèle enrichi pour les détails d'une série
/// Étend les données Xtream avec métadonnées TVmaze/TMDB/IA
class SeriesDetail {
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

  // Nouvelles métadonnées enrichies
  final String imdbId;
  final int tvmazeId;
  final int tmdbId;
  final int runtime; // en minutes par épisode
  final List<String> keywords;
  final List<String> networks; // réseaux d'origine (ex: HBO, Netflix)
  final String status; // Running, Ended, Canceled
  final String firstAirDate; // YYYY-MM-DD
  final String? lastAirDate;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final String? originalLanguage;
  final String? originalName;
  final Map<int, List<Actor>> guestStarsPerSeason; // season -> guest stars
  final List<Actor> cast; // Distribution principale
  final bool aiGenerated;
  final String dataSource; // 'tvmaze', 'tmdb', 'ai', 'xtream'

  SeriesDetail({
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
    this.imdbId = '',
    this.tvmazeId = 0,
    this.tmdbId = 0,
    this.runtime = 0,
    this.keywords = const [],
    this.networks = const [],
    this.status = '',
    this.firstAirDate = '',
    this.lastAirDate,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.originalLanguage,
    this.originalName,
    this.guestStarsPerSeason = const {},
    this.cast = const [],
    this.aiGenerated = false,
    this.dataSource = 'xtream',
  });

  /// Crée un SeriesDetail à partir d'un Series (données Xtream de base)
  factory SeriesDetail.fromSeries(Series series) {
    return SeriesDetail(
      id: series.id,
      title: series.title,
      description: series.description,
      coverUrl: series.coverUrl,
      year: series.year,
      genre: series.genre,
      director: series.director,
      rating: series.rating,
      pegi: series.pegi,
      episodes: series.episodes,
      categoryId: series.categoryId,
      numberOfSeasons: series.episodes.map((e) => e.season).toSet().length,
      numberOfEpisodes: series.episodes.length,
      cast: const [],
      dataSource: 'xtream',
    );
  }

  /// Vérifie si des champs critiques manquent
  bool get needsEnrichment {
    return year == 0 ||
        genre.isEmpty ||
        networks.isEmpty ||
        runtime == 0 ||
        firstAirDate.isEmpty ||
        status.isEmpty;
  }

  /// Vérifie si le fallback IA est nécessaire
  bool get needsAiFallback {
    return needsEnrichment && !dataSource.startsWith('ai');
  }

  SeriesDetail copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    int? year,
    String? genre,
    String? director,
    double? rating,
    String? pegi,
    List<Episode>? episodes,
    String? categoryId,
    String? imdbId,
    int? tvmazeId,
    int? tmdbId,
    int? runtime,
    List<String>? keywords,
    List<String>? networks,
    String? status,
    String? firstAirDate,
    String? lastAirDate,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    String? originalLanguage,
    String? originalName,
    Map<int, List<Actor>>? guestStarsPerSeason,
    List<Actor>? cast,
    bool? aiGenerated,
    String? dataSource,
  }) {
    return SeriesDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      director: director ?? this.director,
      rating: rating ?? this.rating,
      pegi: pegi ?? this.pegi,
      episodes: episodes ?? this.episodes,
      categoryId: categoryId ?? this.categoryId,
      imdbId: imdbId ?? this.imdbId,
      tvmazeId: tvmazeId ?? this.tvmazeId,
      tmdbId: tmdbId ?? this.tmdbId,
      runtime: runtime ?? this.runtime,
      keywords: keywords ?? this.keywords,
      networks: networks ?? this.networks,
      status: status ?? this.status,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      lastAirDate: lastAirDate ?? this.lastAirDate,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      originalName: originalName ?? this.originalName,
      guestStarsPerSeason: guestStarsPerSeason ?? this.guestStarsPerSeason,
      cast: cast ?? this.cast,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  /// Récupère les guest stars pour une saison donnée
  List<Actor> getGuestStarsForSeason(int season) {
    return guestStarsPerSeason[season] ?? [];
  }

  @override
  String toString() {
    return 'SeriesDetail(id: $id, title: $title, seasons: $numberOfSeasons, episodes: $numberOfEpisodes, tvmazeId: $tvmazeId, dataSource: $dataSource, aiGenerated: $aiGenerated)';
  }

  String? get pegiLabel => ageBadgeLabel(pegi);
}
