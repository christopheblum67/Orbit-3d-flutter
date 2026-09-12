import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/channel.dart';

/// Une carte de recommandation affichée pendant l'écran de démarrage.
class StartupRecommendation {
  final String title;
  final String category; // 'Film', 'Série', 'Radio', 'Replay', 'Multi-écran'
  final String posterUrl;
  final String reason;
  final double rating;
  final String id;
  final String? movieStreamUrl;
  final String? seriesId;
  final String? radioStreamUrl;
  final String? replayStreamUrl;

  const StartupRecommendation({
    required this.title,
    required this.category,
    required this.posterUrl,
    required this.reason,
    required this.rating,
    required this.id,
    this.movieStreamUrl,
    this.seriesId,
    this.radioStreamUrl,
    this.replayStreamUrl,
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

  factory StartupRecommendation.fromRadio(Channel radio, String reason) {
    return StartupRecommendation(
      title: radio.name,
      category: 'Radio',
      posterUrl: radio.logoUrl,
      reason: reason,
      rating: 0,
      id: 'radio_${radio.id}',
      radioStreamUrl: radio.streamUrl,
    );
  }

  factory StartupRecommendation.fromReplay(
      String title, String posterUrl, String reason, String streamUrl,
      {double rating = 0, String? id,}) {
    return StartupRecommendation(
      title: title,
      category: 'Replay',
      posterUrl: posterUrl,
      reason: reason,
      rating: rating,
      id: id ?? 'replay_${title.hashCode}',
      replayStreamUrl: streamUrl,
    );
  }
}
