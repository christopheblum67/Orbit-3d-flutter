import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/series_compact.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';

/// Repository pour la récupération des détails complets d'une série.
///
/// Utilise la chaîne d'enrichissement : Xtream (get_series_info) → TVmaze → TMDB → OMDB.
class SeriesRepository implements SeriesRepositoryInterface {
  const SeriesRepository({
    required ApiService api,
    required MetadataEnrichmentService enrichment,
  })  : _api = api,
        _enrichment = enrichment;

  final ApiService _api;
  final MetadataEnrichmentService _enrichment;

  /// Récupère la série complète avec tous les détails (épisodes, description, etc.).
  @override
  Future<Series> fetchDetail(String seriesId) async {
    return _api.fetchSeriesInfo(seriesId);
  }

  /// Récupère plusieurs séries complètes en lot.
  @override
  Future<List<Series>> fetchDetails(List<String> seriesIds) async {
    final results = <Series>[];
    for (final id in seriesIds) {
      final series = await fetchDetail(id);
      results.add(series);
    }
    return results;
  }

  /// Récupère les détails enrichis complets (TVmaze, TMDB, OMDB, cast/guest stars).
  @override
  Future<SeriesDetail> fetchEnrichedDetail(String seriesId) async {
    final series = Series(
      id: seriesId,
      title: '',
      description: '',
      coverUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      episodes: [],
      categoryId: '',
    );

    return _enrichment.enrichSeries(series);
  }
}

/// Interface pour l'injection de dépendances et les tests.
abstract class SeriesRepositoryInterface {
  Future<Series> fetchDetail(String seriesId);
  Future<List<Series>> fetchDetails(List<String> seriesIds);
  Future<SeriesDetail> fetchEnrichedDetail(String seriesId);
}