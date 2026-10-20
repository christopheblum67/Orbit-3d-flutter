import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
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
    final peek = tmdb.peekMovieLight(m.title, year: m.year > 0 ? m.year : null)
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
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.filmsVod),
        actions: [
          IconButton(
            tooltip: l.searchMovie,
            icon: const Icon(Icons.movie_outlined),
            onPressed: () => context.push('/search?type=vod'),
          ),
          SortToolbarButtons(
            mode: _selectedSortMode,
            onChanged: (mode) => setState(() => _selectedSortMode = mode),
          ),
          IconButton(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            onPressed: _openSortDialog,
          ),
        ],
      ),
      body: TvSafeArea(
        child: moviesAsync.when(
          data: (movies) {
            if (movies.isEmpty) {
              return EmptyState(
                icon: Icons.movie_outlined,
                title: l.noMoviesAvailable,
                message: 'La bibliothèque VOD est vide pour le moment.',
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
              MediaCategory(id: '', name: 'Tous', count: catalog.visibleCount),
              MediaCategory(
                  id: 'fav', name: 'Favoris', count: catalog.favoriteCount,),
              MediaCategory(
                  id: 'recent', name: 'Récemment', count: catalog.recentCount,),
              ...categories,
            ];
  
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategoriesRail(
                  categories: railCategories,
                  selectedId: _selectedCategoryId,
                  onSelected: (id) => setState(() => _selectedCategoryId = id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _SearchField(
                          controller: _searchController,
                          hint: 'Rechercher un film ou un genre…',
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                      Expanded(
                        child: visibleMovies.isEmpty
                            ? EmptyState(
                                icon: Icons.movie_outlined,
                                title: _selectedCategoryId == 'fav'
                                    ? l.noFavoriteMovies
                                    : _selectedCategoryId == 'recent'
                                        ? 'Aucun film récent'
                                        : _selectedCategoryId.isEmpty
                                            ? 'Aucun résultat'
                                            : 'Aucun film dans cette catégorie',
                                message: _selectedCategoryId == 'fav'
                                    ? 'Appuie sur le cœur d\'un film pour le retrouver ici.'
                                    : _selectedCategoryId == 'recent'
                                        ? 'Les films regardés s\'afficheront ici.'
                                        : _selectedCategoryId.isEmpty
                                            ? 'Aucun film ne correspond à cette recherche.'
                                            : 'Aucun film ne correspond à cette catégorie.',
                              )
                            : FocusTraversalGroup(
                                policy: OrderedTraversalPolicy(),
                                child: GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    16,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 160,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: visibleMovies.length,
                                  itemBuilder: (context, index) {
                                    final movie = visibleMovies[index];
                                    return _VodTile(
                                      movie: movie,
                                      enrichment: enrichments[movie.id],
                                      affinity: affinity,
                                      autofocus: index == 0,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const LoadingState(message: 'Chargement…'),
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
    required this.movie,
    required this.enrichment,
    required this.affinity,
    this.autofocus = false,
  });

  final Movie movie;
  final TmdbRankEntry? enrichment;
  final ProfileAffinityScorer? affinity;
  final bool autofocus;

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
      if (wasFavorite) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('« ${movie.title} » ajouté aux favoris'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
    }

    return TvFocus(
      autofocus: autofocus,
      onActivate: onOpen,
      child: MediaCard(
        title: movie.title,
        posterUrl: movie.posterUrl.isNotEmpty
            ? movie.posterUrl
            : (enrichment?.posterUrl ?? ''),
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
        onTap: onOpen,
        onLongPress: onLongPress,
        isNew: movie.isNew,
      ),
    );
  }
}

/// Champ de recherche large, avec police lisible pour la TV.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 16,
        ),
        prefixIcon: const Icon(Icons.search, size: 24),
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
