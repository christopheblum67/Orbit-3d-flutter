import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';

/// Une carte de recommandation affichée pendant l'écran de démarrage.
class StartupRecommendation {
  final String title;
  final String category; // 'Film' ou 'Série'
  final String posterUrl;
  final String reason;
  final double rating;
  final String id;
  final String? movieStreamUrl;
  final String? seriesId;

  const StartupRecommendation({
    required this.title,
    required this.category,
    required this.posterUrl,
    required this.reason,
    required this.rating,
    required this.id,
    this.movieStreamUrl,
    this.seriesId,
  });

  factory StartupRecommendation.fromMovie(Movie movie, String reason) {
    return StartupRecommendation(
      title: movie.title,
      category: 'Film',
      posterUrl: movie.posterUrl,
      reason: reason,
      rating: movie.rating,
      id: movie.id,
      movieStreamUrl: movie.streamUrl,
    );
  }

  factory StartupRecommendation.fromSeries(Series series, String reason) {
    return StartupRecommendation(
      title: series.title,
      category: 'Série',
      posterUrl: series.coverUrl,
      reason: reason,
      rating: series.rating,
      id: series.id,
      seriesId: series.id,
    );
  }
}