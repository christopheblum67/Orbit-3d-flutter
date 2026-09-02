import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';

enum RecommendationKind { movie, series }

/// Élément de recommandation unifié (film ou série) pour le matchmaking.
class Recommendation {
  const Recommendation({
    required this.kind,
    this.movie,
    this.series,
  });

  final RecommendationKind kind;
  final Movie? movie;
  final Series? series;

  String get id => kind == RecommendationKind.movie ? movie!.id : series!.id;
  String get title =>
      kind == RecommendationKind.movie ? movie!.title : series!.title;
  String get description => kind == RecommendationKind.movie
      ? movie!.description
      : series!.description;
  String get posterUrl => kind == RecommendationKind.movie
      ? movie!.posterUrl
      : series!.coverUrl;
  int get year =>
      kind == RecommendationKind.movie ? movie!.year : series!.year;
  String get genre =>
      kind == RecommendationKind.movie ? movie!.genre : series!.genre;
  double get rating =>
      kind == RecommendationKind.movie ? movie!.rating : series!.rating;
  String? get pegiLabel => kind == RecommendationKind.movie
      ? movie!.pegiLabel
      : series!.pegiLabel;
}
