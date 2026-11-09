import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/metadata_providers.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';

/// Enrichit au plus 30 films dépourvus de poster ou de note par passage.
/// Le cache TMDB permet de reprendre au passage suivant sans rejouer le réseau.
final vodGridEnrichmentsProvider =
    FutureProvider.autoDispose<Map<String, TmdbRankEntry>>((ref) async {
  ref.watch(tmdbApiKeyOverrideProvider);
  final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
  if (movies.isEmpty) return const <String, TmdbRankEntry>{};

  const maxEnrichmentsPerPass = 30;
  final tmdb = ref.watch(tmdbServiceProvider);
  if (!tmdb.hasApiKey) return const <String, TmdbRankEntry>{};

  final result = <String, TmdbRankEntry>{};
  var enriched = 0;
  for (final movie in movies) {
    final needsEnrichment = movie.posterUrl.isEmpty || movie.rating <= 0;
    if (!needsEnrichment) continue;
    if (enriched >= maxEnrichmentsPerPass) break;

    final entry = await tmdb.searchMovieLight(
      movie.title,
      year: movie.year > 0 ? movie.year : null,
    );
    enriched++;
    if (entry == null) continue;
    result[movie.id] = entry;
  }
  return result;
});

final enrichmentServiceProvider = Provider<MetadataEnrichmentService>((ref) {
  return MetadataEnrichmentService(
    api: ref.watch(apiServiceProvider),
    tmdb: ref.watch(tmdbServiceProvider),
    tvmaze: ref.watch(tvmazeServiceProvider),
    omdb: ref.watch(omdbServiceProvider),
  );
});

/// Le résultat reste en mémoire et la clé est l'objet Movie entier.
final movieDetailProvider =
    FutureProvider.family<MovieDetail, Movie>((ref, movie) async {
  ref.watch(tmdbApiKeyOverrideProvider);
  return ref.watch(enrichmentServiceProvider).enrichMovie(movie);
});

/// Comme pour les films, le résultat et la clé Series restent en mémoire.
final seriesDetailProvider =
    FutureProvider.family<SeriesDetail, Series>((ref, series) async {
  if (ref.watch(activeSubscriptionProvider)?.type == SubscriptionType.m3u) {
    return SeriesDetail.fromSeries(series, dataSource: 'm3u');
  }
  return ref.watch(enrichmentServiceProvider).enrichSeries(series);
});
