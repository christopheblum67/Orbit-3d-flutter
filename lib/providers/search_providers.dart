import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/metadata_providers.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/search_index_service.dart';
import 'package:orbit_3d_flutter/services/search_service.dart';

/// Index plein-texte local du catalogue (VOD + Séries + Live).
final searchIndexServiceProvider = Provider<SearchIndexService>(
  (ref) => SearchIndexService(),
);

final searchServiceProvider = Provider<SearchService>((ref) {
  final service = SearchService(
    api: ref.watch(apiServiceProvider),
    tmdb: ref.watch(tmdbServiceProvider),
    tvmaze: ref.watch(tvmazeServiceProvider),
    loadFavorites: () async {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return <FavoriteEntry>[];
      return ref.read(favoritesServiceProvider).loadForProfile(profile.id);
    },
    loadRecentlyWatched: () async {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return <RecentEntry>[];
      return ref
          .read(recentlyWatchedServiceProvider)
          .loadForProfile(profile.id);
    },
    loadCatalogue: () async {
      final movies = ref.read(moviesProvider).value ?? const <Movie>[];
      final series = ref.read(seriesProvider).value ?? const <Series>[];
      final channels =
          ref.read(liveChannelsProvider).value ?? const <Channel>[];
      return SearchCatalogue(
        movies: movies,
        series: series,
        channels: channels,
      );
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Clé normalisée pour éviter une entrée de cache par frappe.
String searchQueryKey(String query) =>
    query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final searchProvider = FutureProvider.autoDispose
    .family<UnifiedSearchResult, String>((ref, query) async {
  final normalized = searchQueryKey(query);
  if (normalized.length < 2) return UnifiedSearchResult.empty();
  final filter = ref.watch(vodCategoryFilterProvider);
  return ref.watch(searchServiceProvider).search(
        normalized,
        hiddenVodCategoryIds: filter.hiddenVodCategoryIds.toList(),
        hiddenSeriesCategoryIds: filter.hiddenSeriesCategoryIds.toList(),
      );
});

final searchFilteredProvider = FutureProvider.autoDispose.family<
    UnifiedSearchResult,
    ({
      String query,
      SearchType? filterType,
      String? categoryId
    })>((ref, params) async {
  final normalized = searchQueryKey(params.query);
  if (normalized.length < 2) return UnifiedSearchResult.empty();
  final filter = ref.watch(vodCategoryFilterProvider);
  return ref.watch(searchServiceProvider).search(
        normalized,
        filterType: params.filterType,
        categoryId: params.categoryId,
        hiddenVodCategoryIds: filter.hiddenVodCategoryIds.toList(),
        hiddenSeriesCategoryIds: filter.hiddenSeriesCategoryIds.toList(),
      );
});

final searchSuggestionsProvider = StreamProvider.autoDispose
    .family<List<SearchSuggestion>, String>((ref, query) async* {
  if (query.trim().length < 2) {
    yield [];
    return;
  }
  yield* ref.watch(searchServiceProvider).suggestions(query);
});
