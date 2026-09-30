import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/movie_compact.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';

/// Repository pour la récupération des détails complets d'un film.
///
/// Utilise la chaîne d'enrichissement : Xtream (get_vod_info) → TMDB → OMDB → TVmaze.
class MovieRepository implements MovieRepositoryInterface {
  const MovieRepository({
    required ApiService api,
    required MetadataEnrichmentService enrichment,
  })  : _api = api,
        _enrichment = enrichment;

  final ApiService _api;
  final MetadataEnrichmentService _enrichment;

  /// Récupère le film complet avec tous les détails (description, casting, streamUrl, etc.).
  @override
  Future<Movie> fetchDetail(String movieId) async {
    // On a besoin d'un objet Movie minimal avec l'ID pour appeler l'API
    final movie = Movie(
      id: movieId,
      title: '',
      description: '',
      posterUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      streamId: movieId,
    );

    final result = await _api.fetchMovieDetail(movie);
    return result;
  }

  /// Récupère plusieurs films complets en lot.
  @override
  Future<List<Movie>> fetchDetails(List<String> movieIds) async {
    final results = <Movie>[];
    for (final id in movieIds) {
      final movie = await fetchDetail(id);
      results.add(movie);
    }
    return results;
  }

  /// Récupère les détails enrichis complets (TMDB, OMDB, TVmaze, cast/crew).
  @override
  Future<MovieDetail> fetchEnrichedDetail(String movieId) async {
    // On a besoin d'un Movie minimal pour démarrer l'enrichissement
    final movie = Movie(
      id: movieId,
      title: '',
      description: '',
      posterUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      streamId: movieId,
    );

    return _enrichment.enrichMovie(movie);
  }
}

/// Interface pour l'injection de dépendances et les tests.
abstract class MovieRepositoryInterface {
  Future<Movie> fetchDetail(String movieId);
  Future<List<Movie>> fetchDetails(List<String> movieIds);
  Future<MovieDetail> fetchEnrichedDetail(String movieId);
}