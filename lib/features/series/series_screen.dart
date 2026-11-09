import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_search_field.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/core/services/affinity_sorter.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_toolbar_buttons.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/catalog_db_provider.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  String _selectedCategoryId = '';
  SortMode _selectedSortMode = SortMode.recentlyAdded;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  CatalogPager<Series>? _pager;
  final ScrollController _dbScroll = ScrollController();
  String _dbSignature = '';
  String _dbCountsSignature = '';
  Map<String, int> _dbCounts = const {};
  int _dbTotal = 0;
  int _dbFavCount = 0;
  int _dbRecentCount = 0;
  Timer? _queryDebounce;
  String _dbQuery = '';

  @override
  void initState() {
    super.initState();
    _dbScroll.addListener(() {
      final p = _pager;
      if (p == null || !_dbScroll.hasClients) return;
      if (_dbScroll.position.extentAfter < 1200) p.loadMore();
    });
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _pager?.invalidate();
    _dbScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static CatalogSort? _dbSortFor(SortMode m) {
    switch (m) {
      case SortMode.nameAsc:
        return CatalogSort.title;
      case SortMode.nameDesc:
        return CatalogSort.titleDesc;
      case SortMode.ratingDesc:
        return CatalogSort.rating;
      case SortMode.ratingAsc:
        return CatalogSort.ratingAsc;
      case SortMode.yearDesc:
        return CatalogSort.year;
      case SortMode.yearAsc:
        return CatalogSort.yearAsc;
      case SortMode.recentlyAdded:
        return CatalogSort.recentlyAdded;
      case SortMode.recentlyAddedAsc:
        return CatalogSort.recentlyAddedAsc;
      default:
        return null;
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _dbQuery = _query);
    });
  }

  void _syncDb(
    String subKey,
    CatalogSort sort,
    Set<String> hidden,
    Set<String> favIds,
    Set<String> recentIds,
    int revision,
  ) {
    final special =
        _selectedCategoryId == 'fav' || _selectedCategoryId == 'recent';
    final filter = CatalogFilter(
      categoryId: special ? '' : _selectedCategoryId,
      hiddenCategories: hidden,
      onlyIds: _selectedCategoryId == 'fav'
          ? favIds
          : _selectedCategoryId == 'recent'
              ? recentIds
              : null,
      query: _dbQuery,
    );
    final signature = '$subKey|$revision|${sort.name}|${filter.categoryId}|'
        '${filter.query}|${filter.onlyIds?.length}|${hidden.length}';
    if (signature != _dbSignature) {
      _dbSignature = signature;
      _pager?.invalidate();
      final pager = CatalogPager<Series>(
        diagnosticKind: 'series',
        fetch: (limit, offset) => CatalogDb.instance.querySeries(
          subKey,
          filter: filter,
          sort: sort,
          limit: limit,
          offset: offset,
        ),
        onChange: () {
          if (mounted) setState(() {});
        },
      );
      _pager = pager;
      if (_dbScroll.hasClients) _dbScroll.jumpTo(0);
      Future.microtask(pager.reset);
    }
    final countsSignature =
        '$subKey|$revision|${hidden.length}|${favIds.length}|${recentIds.length}';
    if (countsSignature != _dbCountsSignature) {
      _dbCountsSignature = countsSignature;
      unawaited(() async {
        final db = CatalogDb.instance;
        final counts = await db.categoryCounts(
          CatalogKind.series,
          subKey,
          hiddenCategories: hidden,
        );
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        final fav = await db.count(
          CatalogKind.series,
          subKey,
          filter: CatalogFilter(hiddenCategories: hidden, onlyIds: favIds),
        );
        final recent = await db.count(
          CatalogKind.series,
          subKey,
          filter: CatalogFilter(hiddenCategories: hidden, onlyIds: recentIds),
        );
        if (!mounted || countsSignature != _dbCountsSignature) return;
        setState(() {
          _dbCounts = counts;
          _dbTotal = total;
          _dbFavCount = fav;
          _dbRecentCount = recent;
        });
      }());
    }
  }

  void _openSortDialog() {
    SortOptionsDialogTV.show(
      context,
      currentMode: _selectedSortMode,
      withAffinity: true,
      onSortSelected: (newMode) => setState(() => _selectedSortMode = newMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final seriesAsync = ref.watch(seriesProvider);
    final categoriesAsync = ref.watch(seriesCategoriesProvider);
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);
    // Contexte d'affinité matchmaking : alimente le badge sur chaque tuile.
    final affinity = ref.watch(profileAffinityScorerProvider);
    // Catégories masquées pour l'abonnement actif (persistées par abonnement).
    final hiddenCategories =
        ref.watch(vodCategoryFilterProvider).hiddenSeriesCategoryIds;
    final dbSort = _dbSortFor(_selectedSortMode);
    final dbKeyAsync = ref.watch(catalogDbKeyProvider(CatalogKind.series));
    final dbKey = dbKeyAsync.value;
    if (dbKey != null && dbSort != null) {
      final favIds = favoriteEntries.values
          .where((e) => e.type == ContentType.series)
          .map((e) => e.id)
          .toSet();
      final recentIds = recentEntries.values
          .where((e) => e.type == ContentType.series)
          .map((e) => e.id)
          .toSet();
      _syncDb(
        dbKey,
        dbSort,
        hiddenCategories,
        favIds,
        recentIds,
        ref.watch(catalogDbRevisionProvider),
      );
      final serverCategories = (categoriesAsync.value ?? <MediaCategory>[])
          .where((c) => !hiddenCategories.contains(c.id))
          .toList(growable: false);
      final rail = <MediaCategory>[
        MediaCategory(id: '', name: 'Tous', count: _dbTotal),
        MediaCategory(id: 'fav', name: 'Favoris', count: _dbFavCount),
        MediaCategory(id: 'recent', name: 'Récemment', count: _dbRecentCount),
        ...serverCategories
            .where((c) => c.id.isNotEmpty && (_dbCounts[c.id] ?? 0) > 0)
            .map((c) => c.copyWith(count: _dbCounts[c.id] ?? 0)),
      ];
      return Scaffold(
        body: _layout(
          context,
          l,
          rail,
          List<Series>.unmodifiable(_pager?.items ?? const <Series>[]),
          affinity,
          scrollController: _dbScroll,
          listLoading: !(_pager?.loaded ?? false),
        ),
      );
    }
    if (dbKeyAsync.isLoading && !dbKeyAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _pager?.invalidate();
    _pager = null;
    _dbSignature = '';
    _dbCountsSignature = '';
    return Scaffold(
      body: seriesAsync.when(
        data: (seriesList) {
          if (seriesList.isEmpty) {
            return EmptyState(
              icon: Icons.tv,
              title: l.noSeriesAvailable,
              message: 'La bibliothèque de séries est vide pour le moment.',
            );
          }
          final serverCategories = (categoriesAsync.value ?? <MediaCategory>[])
              .where((c) => !hiddenCategories.contains(c.id))
              .toList(growable: false);
          // Liste filtrée par catégories masquées. Nommée différemment de
          // `visibleSeries` (plus bas) qui ne fait que réordonner le tri.
          final categoryVisibleSeries = hiddenCategories.isEmpty
              ? seriesList
              : seriesList
                  .where((s) => !hiddenCategories.contains(s.categoryId))
                  .toList(growable: false);
          final categories = _withRealCounts(
            serverCategories,
            categoryVisibleSeries.map((s) => s.categoryId),
          );
          final seriesFavIds = favoriteEntries.values
              .where((e) => e.type == ContentType.series)
              .map((e) => e.id)
              .toSet();
          final seriesRecentIds = recentEntries.values
              .where((e) => e.type == ContentType.series)
              .map((e) => e.id)
              .toSet();
          final railCategories = <MediaCategory>[
            MediaCategory(
              id: '',
              name: 'Tous',
              count: categoryVisibleSeries.length,
            ),
            MediaCategory(
              id: 'fav',
              name: 'Favoris',
              count: categoryVisibleSeries
                  .where((s) => seriesFavIds.contains(s.id))
                  .length,
            ),
            MediaCategory(
              id: 'recent',
              name: 'Récemment',
              count: categoryVisibleSeries
                  .where((s) => seriesRecentIds.contains(s.id))
                  .length,
            ),
            ...categories,
          ];
          final q = _query.trim().toLowerCase();
          final List<Series> filteredSeries;
          if (_selectedCategoryId == 'fav') {
            final favIds = favoriteEntries.values
                .where((e) => e.type == ContentType.series)
                .map((e) => e.id)
                .toSet();
            filteredSeries = categoryVisibleSeries
                .where((s) => favIds.contains(s.id))
                .toList();
          } else if (_selectedCategoryId == 'recent') {
            final recentIds = recentEntries.values
                .where((e) => e.type == ContentType.series)
                .map((e) => e.id)
                .toSet();
            filteredSeries = categoryVisibleSeries
                .where((s) => recentIds.contains(s.id))
                .toList();
          } else if (_selectedCategoryId.isEmpty) {
            filteredSeries = categoryVisibleSeries;
          } else {
            filteredSeries = categoryVisibleSeries
                .where((s) => s.categoryId == _selectedCategoryId)
                .toList();
          }
          final queryFiltered = q.isEmpty
              ? filteredSeries
              : filteredSeries
                  .where(
                    (s) =>
                        s.title.toLowerCase().contains(q) ||
                        s.genre.toLowerCase().contains(q),
                  )
                  .toList();
          final List<Series> visibleSeries;
          if (_selectedSortMode == SortMode.affinity ||
              _selectedSortMode == SortMode.affinityAsc) {
            // Tri par affinité : réutilise la logique corrective du matchmaking
            // (ProfileAffinityScorer → profileAffinityWithSignals). Le genre réel
            // TMDB est lu **sans réseau** dans le cache Hive partagé (même source
            // que le badge de tuile, écrit par `searchTvLight`) ; faute de cache,
            // on part du genre catalogue, que la formule corrige déjà via ses
            // alias canoniques (« Horreur, Mystère, … »). Sans profil ni genres
            // favoris, l'affinité n'a pas de sens : on rend la liste filtrée
            // telle quelle plutôt que de dégrader en tri par note.
            final scorer = ref.read(profileAffinityScorerProvider);
            if (scorer == null || scorer.favoriteGenres.isEmpty) {
              visibleSeries = queryFiltered;
            } else {
              final tmdb = ref.read(tmdbAffinityServiceProvider);
              final descending = _selectedSortMode != SortMode.affinityAsc;
              visibleSeries = sortByAffinityDesc(
                queryFiltered,
                descending: descending,
                score: (s) {
                  final realGenre = tmdb
                          .peekTvLight(
                            s.title,
                            year: s.year > 0 ? s.year : null,
                          )
                          ?.genreNames ??
                      '';
                  final scoring =
                      realGenre.isNotEmpty ? s.withGenre(realGenre) : s;
                  return scorer.percentForSeries(scoring).toDouble();
                },
                title: (s) => s.title,
              );
            }
          } else {
            final libraryManager = ref.read(mediaLibraryManagerProvider);
            final mediaItems = queryFiltered
                .map(
                  (s) => MediaItem(
                    id: s.id,
                    title: s.title,
                    streamUrl: '', // Series n'ont pas de streamUrl direct
                    posterUrl: s.coverUrl,
                    categoryId: s.categoryId,
                    rating: s.rating,
                    releaseYear: s.year,
                    durationMinutes: 0,
                    // Date d'ajout réelle du panel (champ Xtream `added`) : voir
                    // le même correctif côté Films.
                    addedDate: s.addedDate,
                  ),
                )
                .toList();
            final sortedItems =
                libraryManager.applySort(mediaItems, _selectedSortMode);
            final seriesById = <String, Series>{
              for (final s in queryFiltered)
                if (s.id.isNotEmpty) s.id: s,
            };
            visibleSeries = sortedItems.map<Series>((item) {
              return seriesById[item.id] ??
                  queryFiltered.firstWhere(
                    (s) => s.id == item.id,
                    orElse: () => queryFiltered.first,
                  );
            }).toList();
          }
          return _layout(context, l, railCategories, visibleSeries, affinity);
        },
        loading: () => const LoadingState(
          message:
              'Chargement du catalogue en cours…\nMerci de patienter quelques secondes.',
        ),
        error: (err, _) => ErrorState(
          icon: Icons.tv,
          title: l.seriesUnavailable,
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(seriesProvider),
        ),
      ),
    );
  }

  Widget _layout(
    BuildContext context,
    AppLocalizations l,
    List<MediaCategory> railCategories,
    List<Series> visibleSeries,
    ProfileAffinityScorer? affinity, {
    ScrollController? scrollController,
    bool listLoading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoriesRail(
          categories: railCategories,
          selectedId: _selectedCategoryId,
          focusSelectedOnMount: ref.read(tvModeNotifierProvider).enabled,
          onSelected: (id) => setState(() => _selectedCategoryId = id),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: DpadSearchField(
                        controller: _searchController,
                        hint: 'Rechercher une série ou un genre…',
                        onChanged: _onQueryChanged,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: l.searchSeries,
                      icon: const Icon(Icons.tv),
                      onPressed: () =>
                          context.push('/search?type=series'),
                    ),
                    SortToolbarButtons(
                      mode: _selectedSortMode,
                      onChanged: (mode) =>
                          setState(() => _selectedSortMode = mode),
                    ),
                    IconButton(
                      tooltip: 'Trier',
                      icon: const Icon(Icons.sort),
                      onPressed: _openSortDialog,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleSeries.isEmpty && listLoading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleSeries.isEmpty
                    ? EmptyState(
                        icon: Icons.tv,
                        title: _selectedCategoryId == 'fav'
                            ? 'Aucune série favorite'
                            : _selectedCategoryId == 'recent'
                                ? 'Aucune série récente'
                                : 'Aucun résultat',
                        message: _selectedCategoryId == 'fav'
                            ? 'Appuie sur le cœur d\'une série pour la '
                                'retrouver ici.'
                            : _selectedCategoryId == 'recent'
                                ? 'Les séries regardées s\'afficheront ici.'
                                : 'Aucune série ne correspond à cette '
                                    'recherche.',
                      )
                    : CustomScrollView(
                        controller: scrollController,
                        scrollCacheExtent: const ScrollCacheExtent.pixels(900),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SectionHeader(
                              icon: Icons.auto_awesome,
                              title: l.series,
                              subtitle: '${visibleSeries.length} titres',
                            ),
                          ),
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverGrid(
                              gridDelegate: mediaCardGridDelegate(
                                context,
                                childAspectRatio: 0.62,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final series = visibleSeries[index];
                                  void onOpen() {
                                    context.push(
                                      '/series/detail?id=${Uri.encodeComponent(series.id)}'
                                      '&title=${Uri.encodeComponent(series.title)}',
                                    );
                                  }

                                  void onLongPress() {
                                    final notifier = ref
                                        .read(favoritesProvider.notifier);
                                    final wasFavorite =
                                        notifier.isFavorite(
                                      ContentType.series,
                                      series.id,
                                    );
                                    notifier.toggle(
                                      FavoriteEntry(
                                        type: ContentType.series,
                                        id: series.id,
                                        title: series.title,
                                        posterUrl: series.coverUrl,
                                        subtitle: series.year > 0
                                            ? '${series.year}'
                                            : series.genre,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            wasFavorite
                                                ? '« ${series.title} » retiré des favoris'
                                                : '« ${series.title} » ajouté aux favoris',
                                          ),
                                          duration: const Duration(
                                            milliseconds: 1500,
                                          ),
                                        ),
                                      );
                                  }

                                  return _SeriesTile(
                                    series: series,
                                    affinity: affinity,
                                    onOpen: onOpen,
                                    onLongPress: onLongPress,
                                  );
                                },
                                childCount: visibleSeries.length,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<MediaCategory> _withRealCounts(
    List<MediaCategory> serverCategories,
    Iterable<String> itemCategoryIds,
  ) {
    final counts = <String, int>{};
    for (final id in itemCategoryIds) {
      if (id.isNotEmpty) counts[id] = (counts[id] ?? 0) + 1;
    }
    return serverCategories
        .where((c) => c.id.isNotEmpty && (counts[c.id] ?? 0) > 0)
        .map((c) => c.copyWith(count: counts[c.id] ?? 0))
        .toList();
  }
}

/// Tuile de la grille Séries, extraite pour observer proprement
/// [seriesRealGenreProvider].
///
/// Même logique que `_VodTile` : `get_series` ne porte pas le genre réel
/// (Xtream y met le nom de catégorie), donc une série sans genre catalogué ne
/// matcherait aucun genre favori et retomberait au seul bonus de note. On
/// résout le genre TMDB (TV) à la demande — une requête `searchTvLight`,
/// mise en cache Hive 24 h.
class _SeriesTile extends ConsumerWidget {
  const _SeriesTile({
    required this.series,
    required this.affinity,
    required this.onOpen,
    required this.onLongPress,
  });

  final Series series;
  final ProfileAffinityScorer? affinity;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realGenre = ref
        .watch(
          seriesRealGenreProvider(
            SeriesGenreQuery(
              id: series.id,
              title: series.title,
              year: series.year,
              catalogGenre: series.genre,
            ),
          ),
        )
        .value;
    final scoringSeries = (realGenre != null && realGenre != series.genre)
        ? Series(
            id: series.id,
            title: series.title,
            description: series.description,
            coverUrl: series.coverUrl,
            year: series.year,
            genre: realGenre,
            director: series.director,
            rating: series.rating,
            pegi: series.pegi,
            episodes: series.episodes,
            categoryId: series.categoryId,
            addedDate: series.addedDate,
          )
        : series;

    return TvFocus(
      onActivate: onOpen,
      child: MediaCard(
        ratingAboveAffinity: true,
        title: series.title,
        posterUrl: series.coverUrl,
        year: series.year,
        // Catégorie retirée de la tuile (comme sur les chaînes) :
        // l'année et la note suffisent, la ligne reste lisible.
        genre: '',
        rating: series.rating,
        ageLabel: series.pegiLabel,
        fallbackIcon: Icons.tv,
        // `contain` : l'affiche ne déborde plus de la tuile.
        posterFit: BoxFit.contain,
        posterPadding: const EdgeInsets.all(6),
        // Affinité personnelle du profil courant (module matchmaking).
        matchPercent: affinity?.percentForSeries(scoringSeries),
        favoriteOverlay: FavoriteToggle.overlay(
          entry: FavoriteEntry(
            type: ContentType.series,
            id: series.id,
            title: series.title,
            posterUrl: series.coverUrl,
            subtitle: series.year > 0 ? '${series.year}' : series.genre,
          ),
        ),
        focusable: false,
        showYear: false,
        titleFontSize: 11,
        onTap: onOpen,
        onLongPress: onLongPress,
        isNew: series.isNew,
      ),
    );
  }
}

/// Champ de recherche large, avec police lisible pour la TV.
