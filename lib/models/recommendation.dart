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

  /// Construit une recommandation à partir des seules métadonnées d'une tuile
  /// (modèles compacts), sans exiger un `Movie`/`Series` complet.
  ///
  /// L'identifiant et l'année permettent aussi d'appliquer les signaux
  /// d'historique et les genres des classements TMDB.
  factory Recommendation.fromMetadata({
    required RecommendationKind kind,
    required String title,
    String id = '',
    int year = 0,
    String genre = '',
    double rating = 0,
    String description = '',
  }) {
    return kind == RecommendationKind.movie
        ? Recommendation(
            kind: kind,
            movie: Movie(
              id: id,
              title: title,
              description: description,
              posterUrl: '',
              year: year,
              genre: genre,
              director: '',
              rating: rating,
              pegi: '',
              streamId: '',
            ),
          )
        : Recommendation(
            kind: kind,
            series: Series(
              id: id,
              title: title,
              description: description,
              coverUrl: '',
              year: year,
              genre: genre,
              director: '',
              rating: rating,
              pegi: '',
              episodes: const [],
            ),
          );
  }

  String get id => kind == RecommendationKind.movie ? movie!.id : series!.id;
  String get title =>
      kind == RecommendationKind.movie ? movie!.title : series!.title;
  String get description => kind == RecommendationKind.movie
      ? movie!.description
      : series!.description;
  String get posterUrl =>
      kind == RecommendationKind.movie ? movie!.posterUrl : series!.coverUrl;
  int get year => kind == RecommendationKind.movie ? movie!.year : series!.year;
  String get genre =>
      kind == RecommendationKind.movie ? movie!.genre : series!.genre;

  /// Catégorie Xtream du contenu (utilisée pour exclure les catégories
  /// masquées par l'utilisateur du scoring matchmaking).
  String get categoryId =>
      kind == RecommendationKind.movie ? movie!.categoryId : series!.categoryId;
  double get rating =>
      kind == RecommendationKind.movie ? movie!.rating : series!.rating;
  String? get pegiLabel =>
      kind == RecommendationKind.movie ? movie!.pegiLabel : series!.pegiLabel;

  DateTime? get addedDate =>
      kind == RecommendationKind.movie ? movie!.addedDate : series!.addedDate;

  bool get isNew =>
      kind == RecommendationKind.movie ? movie!.isNew : series!.isNew;
}
