import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/metadata_providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/search_index_service.dart';
import 'package:orbit_3d_flutter/services/search_service.dart';

/// Index plein-texte local du catalogue (VOD + Séries + Live).
final searchIndexServiceProvider = Provider<SearchIndexService>(
  (ref) => SearchIndexService(),
);

final Provider<SearchService> searchServiceProvider =
    Provider<SearchService>((ref) {
  final subscriptionId = ref.watch(activeSubscriptionProvider)?.id;
  ref.watch(favoritesProvider);
  final service = SearchService(
    api: ref.watch(apiServiceProvider),
    tmdb: ref.watch(tmdbServiceProvider),
    tvmaze: ref.watch(tvmazeServiceProvider),
    loadFavorites: () async {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return <FavoriteEntry>[];
      return ref.read(favoritesProvider).values.toList();
    },
    loadRecentlyWatched: () async {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return <RecentEntry>[];
      return ref
          .read(recentlyWatchedServiceProvider)
          .loadForProfile(profile.id);
    },
    loadCatalogue: () async {
      if (!ref.mounted ||
          subscriptionId == null ||
          ref.read(activeSubscriptionProvider)?.id != subscriptionId) {
        return null;
      }
      final movieState = ref.read(moviesProvider);
      final seriesState = ref.read(seriesProvider);
      final channelState = ref.read(liveChannelsProvider);
      if (movieState.isLoading ||
          seriesState.isLoading ||
          channelState.isLoading ||
          movieState.hasError ||
          seriesState.hasError ||
          channelState.hasError) {
        return null;
      }
      final movies = movieState.value ?? const <Movie>[];
      final series = seriesState.value ?? const <Series>[];
      final channels = channelState.value ?? const <Channel>[];
      return SearchCatalogue(
        movies: movies,
        series: series,
        channels: channels,
      );
    },
    subscriptionId: subscriptionId,
  );
  void refreshSearch<T>(AsyncValue<T>? previous, AsyncValue<T> next) {
    service.invalidateCatalogueCache();
    ref.invalidate(searchProvider);
    ref.invalidate(searchFilteredProvider);
  }

  ref.listen(moviesProvider, refreshSearch);
  ref.listen(seriesProvider, refreshSearch);
  ref.listen(liveChannelsProvider, refreshSearch);
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
