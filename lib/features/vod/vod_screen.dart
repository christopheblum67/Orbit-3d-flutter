import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_search_field.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/core/services/affinity_sorter.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_toolbar_buttons.dart';
import 'package:orbit_3d_flutter/features/vod/vod_catalog_pipeline.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/catalog_db_provider.dart';
import 'package:orbit_3d_flutter/providers/category_change_provider.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  String _selectedCategoryId = '';
  SortMode _selectedSortMode = SortMode.recentlyAdded;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  CatalogPager<Movie>? _pager;
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

  /// Tri SQL équivalent, ou `null` quand le mode exige le chemin mémoire
  /// (affinité, reprise, durée).
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

  CatalogFilter _dbFilter(
    Set<String> hidden,
    Set<String> favIds,
    Set<String> recentIds,
  ) {
    return CatalogFilter(
      categoryId:
          (_selectedCategoryId == 'fav' || _selectedCategoryId == 'recent')
              ? ''
              : _selectedCategoryId,
      hiddenCategories: hidden,
      onlyIds: _selectedCategoryId == 'fav'
          ? favIds
          : _selectedCategoryId == 'recent'
              ? recentIds
              : null,
      query: _dbQuery,
    );
  }

  /// Prépare pager et compteurs pour l'état courant ; ne fait rien si la
  /// signature (abonnement, filtre, tri, révision) n'a pas changé.
  void _syncDb(
    String subKey,
    CatalogSort sort,
    CatalogFilter filter,
    Set<String> hidden,
    Set<String> favIds,
    Set<String> recentIds,
    int revision,
  ) {
    final signature = '$subKey|$revision|${sort.name}|${filter.categoryId}|'
        '${filter.query}|${catalogSetSignature(filter.onlyIds)}|'
        '${catalogSetSignature(hidden)}';
    if (signature != _dbSignature) {
      _dbSignature = signature;
      _pager?.invalidate();
      final pager = CatalogPager<Movie>(
        diagnosticKind: 'vod',
        fetch: (limit, offset) => CatalogDb.instance.queryMovies(
          subKey,
          filter: filter,
          sort: sort,
          limit: limit,
          offset: offset,
        ),
        fetchAfter: (limit, last) => CatalogDb.instance.queryMovies(
          subKey,
          filter: filter,
          sort: sort,
          limit: limit,
          after: last == null ? null : CatalogCursor.fromMovie(last),
        ),
        onChange: () {
          if (mounted) setState(() {});
        },
      );
      _pager = pager;
      if (_dbScroll.hasClients) _dbScroll.jumpTo(0);
      Future.microtask(pager.reset);
    }
    final countsSignature = '$subKey|$revision|${catalogSetSignature(hidden)}|'
        '${catalogSetSignature(favIds)}|${catalogSetSignature(recentIds)}';
    if (countsSignature != _dbCountsSignature) {
      _dbCountsSignature = countsSignature;
      unawaited(() async {
        final db = CatalogDb.instance;
        final counts = await db.categoryCounts(
          CatalogKind.vod,
          subKey,
          hiddenCategories: hidden,
        );
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        final fav = await db.count(
          CatalogKind.vod,
          subKey,
          filter: CatalogFilter(hiddenCategories: hidden, onlyIds: favIds),
        );
        final recent = await db.count(
          CatalogKind.vod,
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

  /// Pipeline catalogue mémoïsé.
  ///
  /// Le catalogue fait ~100 000 entrées. Tout ce travail tournait dans
  /// uild(), donc à chaque frappe au clavier (setState(_query)) :
  /// refiltrage par catégorie sur 100 000 films, 	oLowerCase() sur le titre ET
  /// le genre de chaque film (~200 000 allocations), une allocation de
  /// MediaItem par film filtré, puis un tri, une Map id'film et un map-back
  /// vers Movie. GridView.builder était bien virtualise, mais ce travail en
  /// amont annulait tout le benefice.
  ///
  /// La logique est extraite et testee dans VodCatalogPipeline.
  late final VodCatalogPipeline _pipeline = VodCatalogPipeline(
    sorter: (movies, mode) => _sortAndMapBack(movies, mode),
  );

  /// Tri des films puis retour aux Movie d'origine.
  List<Movie> _sortAndMapBack(List<Movie> source, String mode) {
    // Mode Affinité : on court-circuite le passage par MediaItem/applySort et on
    // trie directement les Movie par score matchmaking du profil courant.
    if (mode.startsWith('affinity')) {
      return _sortByAffinity(source);
    }
    final libraryManager = ref.read(mediaLibraryManagerProvider);
    final mediaItems = source
        .map(
          (m) => MediaItem(
            id: m.id,
            title: m.title,
            streamUrl: m.streamUrl,
            posterUrl: m.posterUrl,
            categoryId: m.categoryId,
            rating: m.rating,
            releaseYear: m.year,
            durationMinutes: 0, // Movie model doesn't have duration
            // Date d'ajout reelle du panel (champ Xtream dded) : avec
            // DateTime.now() tous les films avaient la meme date et le tri
            // « recemment ajoute » revenait a l'ordre de la liste source.
            addedDate: m.addedDate,
          ),
        )
        .toList();
    final sortedItems =
        libraryManager.applySort(mediaItems, _sortModeFrom(mode));
    // Index direct au lieu d'une Map de N entrees suivie d'un irstWhere
    // de repli : la Map etait reconstruite a chaque build puis reparcourue.
    final byId = <String, Movie>{
      for (final m in source)
        if (m.id.isNotEmpty) m.id: m,
    };
    final result = <Movie>[];
    for (final item in sortedItems) {
      final movie = byId[item.id];
      if (movie != null) {
        result.add(movie);
      } else if (source.isNotEmpty) {
        // Repli historique : un item trie sans film correspondant retombait
        // sur le premier film de la liste.
        result.add(source.first);
      }
    }
    return result;
  }

  /// Trie les films par affinité matchmaking (décroissante par défaut, ou
  /// croissante pour [SortMode.affinityAsc]).
  ///
  /// Réutilise la MÊME logique corrective que la tuile (badge) et l'onglet
  /// Matchmaking : `ProfileAffinityScorer` (formule `profileAffinityWithSignals`)
  /// sur le **vrai genre TMDB** quand il est connu, sinon le genre catalogue —
  /// que la formule corrige déjà via ses alias canoniques (« Horreur, Mystère,
  /// … »).
  ///
  /// Sans profil (ou sans genres favoris) l'affinité n'a aucun sens : on rend la
  /// liste telle quelle plutôt que de dégrader en tri par note.
  List<Movie> _sortByAffinity(List<Movie> source) {
    final scorer = ref.read(profileAffinityScorerProvider);
    if (scorer == null || scorer.favoriteGenres.isEmpty) return source;
    final enrichments = ref.read(vodGridEnrichmentsProvider).value ??
        const <String, TmdbRankEntry>{};
    // Lecture ONCE du service (et non par film) : le peek sur 100 000 films ne
    // doit pas refaire 100 000 lectures de provider.
    final tmdb = ref.read(tmdbAffinityServiceProvider);
    // Sens : « Affinité » = décroissant (les plus affins d'abord),
    // « Affinité (croissant) » = les moins affins d'abord.
    final descending = _selectedSortMode != SortMode.affinityAsc;
    return sortByAffinityDesc(
      source,
      descending: descending,
      score: (m) {
        final realGenre = _realGenreOf(tmdb, m, enrichments);
        final scoring = realGenre.isNotEmpty ? m.copyWith(genre: realGenre) : m;
        return scorer.percentForMovie(scoring).toDouble();
      },
      title: (m) => m.title,
    );
  }

  /// Vrai genre TMDB déjà résolu pour un film, lu **sans réseau** dans le cache
  /// Hive partagé. C'est EXACTEMENT la source du badge de tuile :
  /// `movieRealGenreProvider` passe par `searchMovieLight`, qui écrit la même
  /// clé (`tmdb:grid:<titre>:<année>`) dans la même boîte. Le tri et le badge
  /// affiché ne divergent donc plus. La carte d'enrichissement (`enrichments`,
  /// indexée par id) sert de repli.
  String _realGenreOf(
    TmdbService tmdb,
    Movie m,
    Map<String, TmdbRankEntry> enrichments,
  ) {
    final peek = tmdb
            .peekMovieLight(m.title, year: m.year > 0 ? m.year : null)
            ?.genreNames ??
        '';
    if (peek.isNotEmpty) return peek;
    return enrichments[m.id]?.genreNames ?? '';
  }

  /// Clé de tri transmise au pipeline (détermine l'égalité de son cache).
  ///
  /// Pour l'affinité, l'ordre dépend du profil courant (genres favoris, favoris,
  /// contenus vus, titres TMDB) : la clé embarque donc une signature de ce
  /// contexte. Les `hashCode` de `Set`/`List` en Dart sont calculés sur le
  /// contenu, ils changent dès que favoris ou historique évoluent — le cache du
  /// pipeline est alors invalidé et l'ordre recalculé.
  String _pipelineSortKey(SortMode mode) {
    if (mode != SortMode.affinity && mode != SortMode.affinityAsc) {
      return mode.name;
    }
    final scorer = ref.read(profileAffinityScorerProvider);
    if (scorer == null) return '${mode.name}|none';
    return '${mode.name}|${scorer.favoriteGenres.join('\u0001')}'
        '|${scorer.favoriteIds.hashCode}'
        '|${scorer.seenIds.hashCode}'
        '|${scorer.tmdbTitles.hashCode}';
  }

  static SortMode _sortModeFrom(String name) {
    if (name.startsWith('affinity')) {
      return name.startsWith('affinityAsc')
          ? SortMode.affinityAsc
          : SortMode.affinity;
    }
    return SortMode.values.firstWhere((m) => m.name == name);
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
    final moviesAsync = ref.watch(moviesProvider);
    final categoriesAsync = ref.watch(vodCategoriesProvider);
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);
    // Contexte d'affinité matchmaking : alimente le badge sur chaque tuile.
    final affinity = ref.watch(profileAffinityScorerProvider);
    // Catégories masquées pour l'abonnement actif (persistées par abonnement).
    final hiddenCategories =
        ref.watch(vodCategoryFilterProvider).hiddenVodCategoryIds;
    final enrichments = ref.watch(vodGridEnrichmentsProvider).value ?? const {};
    final dbSort = _dbSortFor(_selectedSortMode);
    final dbKeyAsync = ref.watch(catalogDbKeyProvider(CatalogKind.vod));
    final dbKey = dbKeyAsync.value;
    if (dbKey != null && dbSort != null) {
      final vodFavIds = favoriteEntries.values
          .where((e) => e.type == ContentType.vod)
          .map((e) => e.id)
          .toSet();
      final vodRecentIds = recentEntries.values
          .where((e) => e.type == ContentType.vod)
          .map((e) => e.id)
          .toSet();
      _syncDb(
        dbKey,
        dbSort,
        _dbFilter(hiddenCategories, vodFavIds, vodRecentIds),
        hiddenCategories,
        vodFavIds,
        vodRecentIds,
        ref.watch(catalogDbRevisionProvider),
      );
      final serverCategories = (categoriesAsync.value ?? <MediaCategory>[])
          .where((c) => !hiddenCategories.contains(c.id))
          .toList(growable: false);
      final rail = <MediaCategory>[
        MediaCategory(id: '', name: l.catalogAll, count: _dbTotal),
        MediaCategory(id: 'fav', name: l.favorites, count: _dbFavCount),
        MediaCategory(id: 'recent', name: l.recentlyWatched, count: _dbRecentCount),
        ..._withRealCounts(serverCategories, _dbCounts),
      ];
      return Scaffold(
        appBar: _buildAppBar(context, l),
        body: TvSafeArea(
          child: _layout(
            context,
            l,
            rail,
            List<Movie>.unmodifiable(_pager?.items ?? const <Movie>[]),
            enrichments,
            affinity,
            scrollController: _dbScroll,
            listLoading: !(_pager?.loaded ?? false),
          ),
        ),
      );
    }
    _pager?.invalidate();
    _pager = null;
    _dbSignature = '';
    _dbCountsSignature = '';
    return Scaffold(
      appBar: _buildAppBar(context, l),
      body: TvSafeArea(
        child: moviesAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return EmptyState(
              icon: Icons.movie_outlined,
              title: l.noMoviesAvailable,
              message: l.catalogNoMovies,
            );
          }
          final vodFavIds = favoriteEntries.values
              .where((e) => e.type == ContentType.vod)
              .map((e) => e.id)
              .toSet();
          final vodRecentIds = recentEntries.values
              .where((e) => e.type == ContentType.vod)
              .map((e) => e.id)
              .toSet();
          // Un seul passage sur le catalogue : categories, filtres, recherche
          // et tri sont memoises dans le pipeline.
          final catalog = _pipeline.apply(
            movies: movies,
            hiddenCategories: hiddenCategories,
            categoryId: _selectedCategoryId,
            favoriteIds: vodFavIds,
            recentIds: vodRecentIds,
            query: _query,
            sortMode: _pipelineSortKey(_selectedSortMode),
          );
          final visibleMovies = catalog.visibleMovies;
          final serverCategories = (categoriesAsync.value ?? <MediaCategory>[])
              .where((c) => !hiddenCategories.contains(c.id))
              .toList(growable: false);
          // Les compteurs du rail viennent du pipeline, qui les a déjà
          // calculés sur les films hors catégories masquées. On ne recompte
          // donc pas 100 000 films à chaque build.
          final categories = _withRealCounts(
            serverCategories,
            catalog.categoryCounts,
          );
          final railCategories = <MediaCategory>[
            MediaCategory(id: '', name: l.catalogAll, count: catalog.visibleCount),
            MediaCategory(
              id: 'fav',
              name: l.favorites,
              count: catalog.favoriteCount,
            ),
            MediaCategory(
              id: 'recent',
              name: l.recentlyWatched,
              count: catalog.recentCount,
            ),
            ...categories,
          ];

          return _layout(
            context, l, railCategories, visibleMovies, enrichments, affinity,
          );
        },
        loading: () => LoadingState(
          message: l.catalogLoading,
        ),
        error: (err, _) => ErrorState(
          icon: Icons.movie_outlined,
          title: l.moviesUnavailable,
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(moviesProvider),
        ),
      ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l) => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(l.films),
      );

  Widget _layout(
    BuildContext context,
    AppLocalizations l,
    List<MediaCategory> railCategories,
    List<Movie> visibleMovies,
    Map<String, TmdbRankEntry> enrichments,
    ProfileAffinityScorer? affinity, {
    ScrollController? scrollController,
    bool listLoading = false,
  }) {
    final subscription = ref.watch(activeSubscriptionProvider);
    final subscriptionId = subscription?.id;
    final changes = subscriptionId == null
        ? const CategoryChanges()
        : ref
                .watch(categoryIncreasesProvider((
                  subscriptionId: subscriptionId,
                  catalog: CategoryCatalog.movies,
                )))
                .value ??
            const CategoryChanges();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoriesRail(
          categories: railCategories,
          increasedCounts: changes.categories,
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
                        hint: l.catalogSearchMovies,
                        onChanged: _onQueryChanged,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: l.searchMovie,
                      style: catalogToolbarIconStyle(context),
                      icon: const Icon(Icons.movie_outlined),
                      onPressed: () => context.push('/search?type=vod'),
                    ),
                    SortToolbarButtons(
                      mode: _selectedSortMode,
                      onChanged: (mode) =>
                          setState(() => _selectedSortMode = mode),
                    ),
                    IconButton(
                      tooltip: l.catalogSort,
                      style: catalogToolbarIconStyle(context),
                      icon: const Icon(Icons.sort),
                      onPressed: _openSortDialog,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleMovies.isEmpty && listLoading
                    ? const Center(child: OrbitDelayedLoadingIndicator())
                    : visibleMovies.isEmpty
                        ? EmptyState(
                            icon: Icons.movie_outlined,
                            title: _selectedCategoryId == 'fav'
                                ? l.noFavoriteMovies
                                : _selectedCategoryId == 'recent'
                                    ? l.catalogNoRecentMovies
                                    : _selectedCategoryId.isEmpty
                                        ? l.catalogNoResults
                                        : l.catalogNoMoviesInCategory,
                            message: _selectedCategoryId == 'fav'
                                ? l.catalogMovieFavoriteHint
                                : _selectedCategoryId == 'recent'
                                    ? l.catalogRecentMoviesHint
                                    : _selectedCategoryId.isEmpty
                                        ? l.catalogMovieSearchEmpty
                                        : l.catalogMovieCategoryEmpty,
                          )
                        : GridView.builder(
                            controller: scrollController,
                            cacheExtent: 900,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            gridDelegate: mediaCardGridDelegate(
                              context,
                              childAspectRatio: 0.55,
                            ),
                            itemCount: visibleMovies.length,
                            itemBuilder: (context, index) {
                              final movie = visibleMovies[index];
                              return _VodTile(
                                key: scrollController == null
                                    ? null
                                    : ValueKey(movie.id),
                                movie: movie,
                                highlightTitle: changes.newIds.contains(
                                  movieChangeId(
                                    movie,
                                    isM3u: subscription?.type ==
                                        SubscriptionType.m3u,
                                  ),
                                ),
                                enrichment: enrichments[movie.id],
                                affinity: affinity,
                              );
                            },
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
    Map<String, int> countsByCategory,
  ) {
    return serverCategories
        .where((c) => c.id.isNotEmpty && (countsByCategory[c.id] ?? 0) > 0)
        .map((c) => c.copyWith(count: countsByCategory[c.id] ?? 0))
        .toList();
  }
}

class _VodPosterFallback extends ConsumerWidget {
  const _VodPosterFallback({
    required this.movie,
    required this.enrichment,
    required this.fallback,
  });

  final Movie movie;
  final TmdbRankEntry? enrichment;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xtream = ref.watch(movieXtreamPosterProvider(movie));
    Widget tmdb() => _VodTmdbPoster(
          movie: movie,
          enrichment: enrichment,
          fallback: fallback,
        );
    return xtream.when(
      loading: () => fallback,
      error: (error, stack) {
        logDiag('Recherche d’affiche Xtream indisponible.');
        return tmdb();
      },
      data: (url) {
        if (url == null || url.isEmpty || url == movie.posterUrl) return tmdb();
        return OrbitCachedImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => tmdb(),
        );
      },
    );
  }
}

class _VodTmdbPoster extends ConsumerWidget {
  const _VodTmdbPoster({
    required this.movie,
    required this.enrichment,
    required this.fallback,
  });

  final Movie movie;
  final TmdbRankEntry? enrichment;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = enrichment?.posterUrl ?? '';
    if (existing.isNotEmpty && existing != movie.posterUrl) {
      return _image(existing);
    }
    return ref.watch(movieTmdbPosterProvider(movie)).when(
          loading: () => fallback,
          error: (_, __) {
            logDiag('Recherche d’affiche TMDB indisponible.');
            return fallback;
          },
          data: (url) => url == null || url.isEmpty || url == movie.posterUrl
              ? fallback
              : _image(url),
        );
  }

  Widget _image(String url) => OrbitCachedImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
}

/// Tuile VOD : résout le **vrai genre** du film (TMDB) pour le badge d'affinité.
///
/// Le catalogue VOD ne porte pas le genre réel (Xtream ne l'expose pas dans
/// `get_vod_streams` : l'app y met le nom de catégorie). Un film rangé dans
/// « Récents » ne matcherait donc aucun genre favori et tomberait à 3 %. On
/// extrait la tuile dans un [ConsumerWidget] pour observer proprement
/// [movieRealGenreProvider] (un `ref.watch` dans un `itemBuilder` s'exécuterait
/// hors du build du widget parent).
class _VodTile extends ConsumerWidget {
  const _VodTile({
    super.key,
    required this.movie,
    required this.enrichment,
    required this.affinity,
    required this.highlightTitle,
  });

  final Movie movie;
  final TmdbRankEntry? enrichment;
  final ProfileAffinityScorer? affinity;
  final bool highlightTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realGenre = ref
        .watch(
          movieRealGenreProvider(
            MovieGenreQuery(
              id: movie.id,
              title: movie.title,
              year: movie.year,
              catalogGenre: movie.genre,
            ),
          ),
        )
        .value;
    final scoringMovie = (realGenre != null && realGenre != movie.genre)
        ? movie.copyWith(genre: realGenre)
        : movie;

    void onOpen() => context.push('/vod/detail', extra: movie);

    void onLongPress() {
      final notifier = ref.read(favoritesProvider.notifier);
      final wasFavorite = notifier.isFavorite(ContentType.vod, movie.id);
      notifier.toggle(
        FavoriteEntry(
          type: ContentType.vod,
          id: movie.id,
          title: movie.title,
          posterUrl: movie.posterUrl,
          subtitle: movie.year > 0 ? '${movie.year}' : movie.genre,
          streamUrl: movie.streamUrl,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              wasFavorite
                  ? AppLocalizations.of(context).removedFromFavorites(movie.title)
                  : AppLocalizations.of(context).addedToFavorites(movie.title),
            ),
            duration: const Duration(milliseconds: 1500),
          ),
        );
    }

    return TvFocus(
      onActivate: onOpen,
      child: MediaCard(
        ratingAboveAffinity: true,
        title: movie.title,
        highlightTitle: highlightTitle,
        posterUrl: movie.posterUrl,
        posterFallbackBuilder: (context, fallback) => _VodPosterFallback(
          movie: movie,
          enrichment: enrichment,
          fallback: fallback,
        ),
        year: movie.year > 0 ? movie.year : (enrichment?.year ?? 0),
        // Catégorie retirée de la tuile (comme sur les chaînes) : l'année et la
        // note suffisent, la ligne reste lisible.
        genre: '',
        rating: movie.rating > 0 ? movie.rating : (enrichment?.rating ?? 0),
        ageLabel: movie.pegiLabel,
        fallbackIcon: Icons.movie_outlined,
        // `contain` : l'affiche ne déborde plus de la tuile.
        posterFit: BoxFit.contain,
        posterPadding: const EdgeInsets.all(6),
        // Affinité personnelle du profil courant, calculée sur le genre réel.
        matchPercent: affinity?.percentForMovie(scoringMovie),
        voteCount: enrichment?.voteCount,
        overview: enrichment?.overview,
        favoriteOverlay: FavoriteToggle.overlay(
          entry: FavoriteEntry(
            type: ContentType.vod,
            id: movie.id,
            title: movie.title,
            posterUrl: movie.posterUrl,
            subtitle: movie.year > 0 ? '${movie.year}' : movie.genre,
            streamUrl: movie.streamUrl,
          ),
        ),
        focusable: false,
        showYear: false,
        titleFontSize: 11,
        onTap: onOpen,
        onLongPress: onLongPress,
        isNew: movie.isNew,
      ),
    );
  }
}

