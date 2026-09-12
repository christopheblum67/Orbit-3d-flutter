import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

/// Nombre maximal d'éléments affichés par grille (Films / Séries).
const int kBrowseGridCap = 50;

enum _BrowseTab { films, series, flixpatrol }

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  _BrowseTab _tab = _BrowseTab.films;
  String _selectedCategoryId = '';
  SortMode _selectedSortMode = SortMode.recentlyAdded;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSortDialog() {
    SortOptionsDialogTV.show(
      context,
      currentMode: _selectedSortMode,
      onSortSelected: (newMode) => setState(() => _selectedSortMode = newMode),
    );
  }

  void _selectTab(_BrowseTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _selectedCategoryId = '';
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenus'),
        actions: [
          if (_tab != _BrowseTab.flixpatrol)
            IconButton(
              tooltip: 'Trier',
              icon: const Icon(Icons.sort),
              onPressed: _openSortDialog,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrowseTabBar(
            selected: _tab,
            onSelected: _selectTab,
            colors: scheme,
          ),
          Expanded(
            child: switch (_tab) {
              _BrowseTab.flixpatrol => const FlixPatrolView(),
              _BrowseTab.films => _buildMovieView(),
              _BrowseTab.series => _buildSeriesView(),
            },
          ),
        ],
      ),
    );
  }

  // ==================== FILMS ====================

  Widget _buildMovieView() {
    final moviesAsync = ref.watch(moviesProvider);
    final categoriesAsync = ref.watch(vodCategoriesProvider);
    return moviesAsync.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const EmptyState(
            icon: Icons.movie_outlined,
            title: 'Aucun film disponible',
            message: 'La bibliothèque VOD est vide pour le moment.',
          );
        }
        final filtered = _filterMovies(movies);
        return _buildContent(
          icon: Icons.movie_outlined,
          title: 'Films',
          categories:
              categoriesAsync.value ?? _categoriesFromMovies(movies),
          items: filtered,
          isSeries: false,
          allItems: movies,
        );
      },
      loading: () => const LoadingState(message: 'Chargement…'),
      error: (err, _) => ErrorState(
        icon: Icons.movie_outlined,
        title: 'Films indisponibles',
        message: userFriendlyError(err),
        onRetry: () => ref.invalidate(moviesProvider),
      ),
    );
  }

  List<Movie> _filterMovies(List<Movie> movies) {
    final favIds = ref
        .read(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.vod)
        .map((e) => e.id)
        .toSet();
    final recentIds = ref
        .read(recentlyWatchedProvider)
        .values
        .where((e) => e.type == ContentType.vod)
        .map((e) => e.id)
        .toSet();
    final q = _query.trim().toLowerCase();
    return movies.where((m) {
      switch (_selectedCategoryId) {
        case 'fav':
          if (!favIds.contains(m.id)) return false;
        case 'recent':
          if (!recentIds.contains(m.id)) return false;
        case '':
          break;
        default:
          if (m.categoryId != _selectedCategoryId) return false;
      }
      if (q.isEmpty) return true;
      return m.title.toLowerCase().contains(q) ||
          m.genre.toLowerCase().contains(q);
    }).toList();
  }

  // ==================== SÉRIES ====================

  Widget _buildSeriesView() {
    final seriesAsync = ref.watch(seriesProvider);
    final categoriesAsync = ref.watch(seriesCategoriesProvider);
    return seriesAsync.when(
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return const EmptyState(
            icon: Icons.tv,
            title: 'Aucune série disponible',
            message: 'La bibliothèque de séries est vide pour le moment.',
          );
        }
        final filtered = _filterSeries(seriesList);
        return _buildContent(
          icon: Icons.tv,
          title: 'Séries',
          categories:
              categoriesAsync.value ?? _categoriesFromSeries(seriesList),
          items: filtered,
          isSeries: true,
          allItems: seriesList,
        );
      },
      loading: () => const LoadingState(message: 'Chargement…'),
      error: (err, _) => ErrorState(
        icon: Icons.tv,
        title: 'Séries indisponibles',
        message: userFriendlyError(err),
        onRetry: () => ref.invalidate(seriesProvider),
      ),
    );
  }

  List<Series> _filterSeries(List<Series> seriesList) {
    final favIds = ref
        .read(favoritesProvider)
        .values
        .where((e) => e.type == ContentType.series)
        .map((e) => e.id)
        .toSet();
    final recentIds = ref
        .read(recentlyWatchedProvider)
        .values
        .where((e) => e.type == ContentType.series)
        .map((e) => e.id)
        .toSet();
    final q = _query.trim().toLowerCase();
    return seriesList.where((s) {
      switch (_selectedCategoryId) {
        case 'fav':
          if (!favIds.contains(s.id)) return false;
        case 'recent':
          if (!recentIds.contains(s.id)) return false;
        case '':
          break;
        default:
          if (s.categoryId != _selectedCategoryId) return false;
      }
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          s.genre.toLowerCase().contains(q);
    }).toList();
  }

  // ==================== CONTENU COMMUN (rail + grille) ====================

  /// [items] est déjà filtré (catégorie + recherche). On trie, on plafonne à
  /// [kBrowseGridCap] et on rend la grille de tuiles focusables.
  Widget _buildContent({
    required IconData icon,
    required String title,
    required List<MediaCategory> categories,
    required List<dynamic> items,
    required bool isSeries,
    required List<dynamic> allItems,
  }) {
    final libraryManager = ref.read(mediaLibraryManagerProvider);
    final mediaItems = items
        .map((e) => _toMediaItem(e, isSeries: isSeries))
        .toList();
    final sortedItems = libraryManager.applySort(mediaItems, _selectedSortMode);
    final capped = sortedItems.take(kBrowseGridCap).toList();

    final byId = <String, dynamic>{
      for (final e in items)
        if (e.id.isNotEmpty) e.id: e,
    };
    final visible = capped
        .map<dynamic>((item) => byId[item.id] ?? items.first)
        .toList();

    final contentType = isSeries ? ContentType.series : ContentType.vod;
    final favIds = ref
        .read(favoritesProvider)
        .values
        .where((e) => e.type == contentType)
        .map((e) => e.id)
        .toSet();
    final recentIds = ref
        .read(recentlyWatchedProvider)
        .values
        .where((e) => e.type == contentType)
        .map((e) => e.id)
        .toSet();
    final railCategories = <MediaCategory>[
      MediaCategory(id: '', name: 'Tous', count: allItems.length),
      MediaCategory(
        id: 'fav',
        name: 'Favoris',
        count: allItems.where((e) => favIds.contains(e.id)).length,
      ),
      MediaCategory(
        id: 'recent',
        name: 'Récemment',
        count: allItems.where((e) => recentIds.contains(e.id)).length,
      ),
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
                child: _BrowseSearchField(
                  controller: _searchController,
                  hint: isSeries
                      ? 'Rechercher une série ou un genre…'
                      : 'Rechercher un film ou un genre…',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? EmptyState(
                        icon: icon,
                        title: _selectedCategoryId == 'fav'
                            ? isSeries
                                ? 'Aucune série favorite'
                                : 'Aucun film favori'
                            : _selectedCategoryId == 'recent'
                                ? isSeries
                                    ? 'Aucune série récente'
                                    : 'Aucun film récent'
                                : 'Aucun résultat',
                        message: _selectedCategoryId == 'fav'
                            ? 'Appuie longuement sur un élément pour le '
                                'retrouver ici.'
                            : _selectedCategoryId == 'recent'
                                ? 'Les contenus regardés s\'afficheront ici.'
                                : 'Aucun contenu ne correspond à cette '
                                    'recherche.',
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SectionHeader(
                              icon: icon,
                              title: title,
                              subtitle:
                                  '${visible.length} titres (sur ${items.length})',
                            ),
                          ),
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 0.55,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildCard(visible[index], isSeries),
                                childCount: visible.length,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_selectedCategoryId == 'recent')
                _UniversalCategoryRail(
                  categories: _universalCategories(),
                  onSelected: _selectUniversalCategory,
                ),
            ],
          ),
        ),
      ],
    );
  }

  MediaItem _toMediaItem(dynamic e, {required bool isSeries}) {
    if (isSeries) {
      final s = e as Series;
      return MediaItem(
        id: s.id,
        title: s.title,
        streamUrl: '',
        posterUrl: s.coverUrl,
        categoryId: s.categoryId,
        rating: s.rating,
        releaseYear: s.year,
        durationMinutes: 0,
        addedDate: DateTime.now(),
      );
    }
    final m = e as Movie;
    return MediaItem(
      id: m.id,
      title: m.title,
      streamUrl: m.streamUrl,
      posterUrl: m.posterUrl,
      categoryId: m.categoryId,
      rating: m.rating,
      releaseYear: m.year,
      durationMinutes: 0,
      addedDate: DateTime.now(),
    );
  }

  Widget _buildCard(dynamic item, bool isSeries) {
    final type = isSeries ? ContentType.series : ContentType.vod;

    void onOpen() {
      if (isSeries) {
        final s = item as Series;
        context.push(
          '/series/detail?id=${Uri.encodeComponent(s.id)}'
          '&title=${Uri.encodeComponent(s.title)}',
        );
      } else {
        context.push('/vod/detail', extra: item as Movie);
      }
    }

    void onLongPress() {
      final notifier = ref.read(favoritesProvider.notifier);
      final title = isSeries
          ? (item as Series).title
          : (item as Movie).title;
      final poster = isSeries
          ? (item as Series).coverUrl
          : (item as Movie).posterUrl;
      final year = isSeries
          ? (item as Series).year
          : (item as Movie).year;
      final genre = isSeries
          ? (item as Series).genre
          : (item as Movie).genre;
      final wasFavorite = notifier.isFavorite(type, item.id);
      notifier.toggle(
        FavoriteEntry(
          type: type,
          id: item.id,
          title: title,
          posterUrl: poster,
          subtitle: year > 0 ? '$year' : genre,
        ),
      );
      if (wasFavorite) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('« $title » ajouté aux favoris'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
    }

    final cardTitle = isSeries
        ? (item as Series).title
        : (item as Movie).title;
    final poster = isSeries
        ? (item as Series).coverUrl
        : (item as Movie).posterUrl;
    final year = isSeries
        ? (item as Series).year
        : (item as Movie).year;
    final genre = isSeries
        ? (item as Series).genre
        : (item as Movie).genre;
    final rating = isSeries
        ? (item as Series).rating
        : (item as Movie).rating;
    final ageLabel = isSeries
        ? (item as Series).pegiLabel
        : (item as Movie).pegiLabel;
    final isNew = isSeries
        ? (item as Series).isNew
        : (item as Movie).isNew;

    return TvFocus(
      onActivate: onOpen,
      child: MediaCard(
        title: cardTitle,
        posterUrl: poster,
        year: year,
        genre: genre,
        rating: rating,
        ageLabel: ageLabel,
        fallbackIcon: isSeries ? Icons.tv : Icons.movie_outlined,
        favoriteOverlay: FavoriteToggle.overlay(
          entry: FavoriteEntry(
            type: type,
            id: item.id,
            title: cardTitle,
            posterUrl: poster,
            subtitle: year > 0 ? '$year' : genre,
          ),
        ),
        onTap: onOpen,
        onLongPress: onLongPress,
        isNew: isNew,
      ),
    );
  }

  // ==================== HELPERS ====================

  static List<MediaCategory> _categoriesFromMovies(List<Movie> movies) {
    return _categoriesFrom(movies.map((m) => (m.categoryId, m.genre)));
  }

  /// Catégories « universelles » : fusion des catégories films + séries
  /// (dédupliquées par id), servies sous la grille « Récemment ».
  List<MediaCategory> _universalCategories() {
    final vod = ref.watch(vodCategoriesProvider);
    final series = ref.watch(seriesCategoriesProvider);
    final movies = ref.watch(moviesProvider).value ?? const <Movie>[];
    final seriesList =
        ref.watch(seriesProvider).value ?? const <Series>[];

    final vodList = vod.value ?? _categoriesFromMovies(movies);
    final seriesCats = series.value ?? _categoriesFromSeries(seriesList);
    final merged = <String, MediaCategory>{};
    void add(MediaCategory c) {
      if (c.id.isEmpty) return;
      final existing = merged[c.id];
      merged[c.id] = existing == null
          ? c
          : MediaCategory(
              id: c.id,
              name: existing.name,
              count: existing.count + c.count,
            );
    }

    for (final c in [...vodList, ...seriesCats]) {
      add(c);
    }
    return merged.values.toList();
  }

  /// Sélectionne une catégorie depuis le rail universel : dans l'onglet courant
  /// si elle y existe, sinon on bascule sur l'autre onglet.
  void _selectUniversalCategory(MediaCategory cat) {
    final currentCats = _tab == _BrowseTab.series
        ? (ref.read(seriesCategoriesProvider).value ??
            const <MediaCategory>[])
        : (ref.read(vodCategoriesProvider).value ??
            const <MediaCategory>[]);
    if (currentCats.any((c) => c.id == cat.id)) {
      setState(() => _selectedCategoryId = cat.id);
    } else {
      setState(() {
        _tab = _tab == _BrowseTab.series
            ? _BrowseTab.films
            : _BrowseTab.series;
        _selectedCategoryId = cat.id;
        _query = '';
      });
    }
  }

  static List<MediaCategory> _categoriesFromSeries(List<Series> seriesList) {
    return _categoriesFrom(seriesList.map((s) => (s.categoryId, s.genre)));
  }

  static List<MediaCategory> _categoriesFrom(
    Iterable<(String, String)> items,
  ) {
    final map = <String, List<String>>{};
    final counts = <String, int>{};
    for (final (id, name) in items) {
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => []).add(name);
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return map.entries.map((e) {
      return MediaCategory(
        id: e.key,
        name: e.value.where((n) => n.isNotEmpty).join(', '),
        count: counts[e.key] ?? 0,
      );
    }).toList();
  }
}

/// Barre d'onglets Films / Séries / FlixPatrol, navigable au D-pad (◀▶).
class _BrowseTabBar extends StatelessWidget {
  const _BrowseTabBar({
    required this.selected,
    required this.onSelected,
    required this.colors,
  });

  final _BrowseTab selected;
  final ValueChanged<_BrowseTab> onSelected;
  final ColorScheme colors;

  static const _tabs = [
    (id: _BrowseTab.films, label: 'Films', icon: Icons.movie_outlined),
    (id: _BrowseTab.series, label: 'Séries', icon: Icons.tv),
    (id: _BrowseTab.flixpatrol, label: 'FlixPatrol', icon: Icons.leaderboard),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (final tab in _tabs) ...[
            Expanded(
              child: TvFocus(
                onActivate: () => onSelected(tab.id),
                child: _BrowseTabPill(
                  label: tab.label,
                  icon: tab.icon,
                  selected: tab.id == selected,
                  color: colors.primary,
                ),
              ),
            ),
            if (tab.id != _tabs.last.id) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _BrowseTabPill extends StatelessWidget {
  const _BrowseTabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? color
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? color : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? color : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Classements populaires TMDB (équivalent FlixPatrol) : films + séries.
class FlixPatrolView extends ConsumerStatefulWidget {
  const FlixPatrolView({super.key});

  @override
  ConsumerState<FlixPatrolView> createState() => FlixPatrolViewState();
}

class FlixPatrolViewState extends ConsumerState<FlixPatrolView> {
  _RankSource _movieMode = _RankSource.popular;
  _RankSource _tvMode = _RankSource.popular;

  static const List<_RankSource> _movieSources = [
    _RankSource.popular,
    _RankSource.nowPlaying,
    _RankSource.topRated,
    _RankSource.upcoming,
    _RankSource.trending,
  ];

  static const List<_RankSource> _tvSources = [
    _RankSource.popular,
    _RankSource.onTheAir,
    _RankSource.airingToday,
    _RankSource.topRated,
    _RankSource.trending,
  ];

  FutureProvider<List<TmdbRankEntry>> _providerFor(bool isTv, _RankSource source) {
    if (isTv) {
      switch (source) {
        case _RankSource.popular:
          return flixPatrolTvProvider;
        case _RankSource.onTheAir:
          return flixPatrolOnTheAirTvProvider;
        case _RankSource.airingToday:
          return flixPatrolAiringTodayTvProvider;
        case _RankSource.topRated:
          return flixPatrolTopRatedTvProvider;
        case _RankSource.trending:
          return flixPatrolTrendingTvProvider;
        default:
          return flixPatrolTvProvider;
      }
    } else {
      switch (source) {
        case _RankSource.popular:
          return flixPatrolMoviesProvider;
        case _RankSource.nowPlaying:
          return flixPatrolNowPlayingMoviesProvider;
        case _RankSource.topRated:
          return flixPatrolTopRatedMoviesProvider;
        case _RankSource.upcoming:
          return flixPatrolUpcomingMoviesProvider;
        case _RankSource.trending:
          return flixPatrolTrendingMoviesProvider;
        default:
          return flixPatrolMoviesProvider;
      }
    }
  }

  void _setMovieMode(_RankSource mode) {
    if (mode == _movieMode) return;
    setState(() => _movieMode = mode);
  }

  void _setTvMode(_RankSource mode) {
    if (mode == _tvMode) return;
    setState(() => _tvMode = mode);
  }

  Future<void> _openEntry(TmdbRankEntry entry) async {
    // Tente de retrouver le même titre dans le catalogue de l'abonnement
    // actif pour permettre la lecture (sinon on reste sur le classement).
    final normalized = entry.title.trim().toLowerCase();
    if (entry.isTv) {
      final series = ref.read(seriesProvider).value ?? const <Series>[];
      Series? match;
      for (final s in series) {
        if (s.title.trim().toLowerCase() == normalized) {
          match = s;
          break;
        }
      }
      if (match != null) {
        context.push(
          '/series/detail?id=${Uri.encodeComponent(match.id)}'
          '&title=${Uri.encodeComponent(match.title)}',
        );
        return;
      }
    } else {
      final movies = ref.read(moviesProvider).value ?? const <Movie>[];
      Movie? match;
      for (final m in movies) {
        if (m.title.trim().toLowerCase() == normalized) {
          match = m;
          break;
        }
      }
      if (match != null) {
        context.push('/vod/detail', extra: match);
        return;
      }
    }
    // Pas dans le catalogue : on affiche une fiche d'info TMDB légère.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (_) => _RankEntrySheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Classements populaires',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildRankList(
                  title: 'Films',
                  isTv: false,
                  sources: _movieSources,
                  selected: _movieMode,
                  onSelected: _setMovieMode,
                ),
              ),
              Expanded(
                child: _buildRankList(
                  title: 'Séries',
                  isTv: true,
                  sources: _tvSources,
                  selected: _tvMode,
                  onSelected: _setTvMode,
                ),
              ),
            ],
          ),
        ),
        const _TmdbAttributionFooter(),
      ],
    );
  }

  Widget _buildRankList({
    required String title,
    required bool isTv,
    required List<_RankSource> sources,
    required _RankSource selected,
    required ValueChanged<_RankSource> onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final available = sources.where((s) => s.isAvailableFor(isTv)).toList();
    final provider = _providerFor(isTv, selected);
    final async = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SectionHeader(
            icon: isTv ? Icons.tv : Icons.movie_outlined,
            title: title,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: available.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final src = available[index];
              final isSelected = src == selected;
              return TvFocus(
                onActivate: () => onSelected(src),
                child: Material(
                  color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => onSelected(src),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        src.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? scheme.onPrimary : scheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: async.when(
            data: (entries) => entries.isEmpty
                ? const EmptyState(
                    icon: Icons.leaderboard_outlined,
                    title: 'Aucun classement',
                    message:
                        'Les tendances TMDB ne sont pas disponibles. '
                        'Ajoutez une clé API TMDB dans Réglages '
                        '(ou TMDB_API_KEY dans .env).',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _RankCard(
                        entry: entry,
                        rank: index + 1,
                        onOpen: () => _openEntry(entry),
                      );
                    },
                  ),
            loading: () => const LoadingState(message: 'Chargement…'),
            error: (err, _) => ErrorState(
              icon: isTv ? Icons.tv : Icons.movie_outlined,
              title: 'Classement indisponible',
              message: userFriendlyError(err),
              onRetry: () => ref.invalidate(provider),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pied d'attribution exigée par TMDB.
class _TmdbAttributionFooter extends StatelessWidget {
  const _TmdbAttributionFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        );
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        'Classements populaires · Données © TMDB — This product uses the '
        'TMDB API but is not endorsed or certified by TMDB.',
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

enum _RankSource {
  popular('Populaire', '/movie/popular', '/tv/popular'),
  nowPlaying('En salle', '/movie/now_playing', null),
  topRated('Mieux notés', '/movie/top_rated', '/tv/top_rated'),
  upcoming('À venir', '/movie/upcoming', null),
  trending('Tendance de la semaine', '/trending/movie/week', '/trending/tv/week'),
  onTheAir('En diffusion', null, '/tv/on_the_air'),
  airingToday('Diffusion aujourd\'hui', null, '/tv/airing_today');

  const _RankSource(this.label, this.moviePath, this.tvPath);
  final String label;
  final String? moviePath;
  final String? tvPath;

  String? pathFor(bool isTv) => isTv ? tvPath : moviePath;
  bool isAvailableFor(bool isTv) => pathFor(isTv) != null;
}

/// Carte d'un élément du classement, avec numéro de rang et note TMDB.
class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.entry,
    required this.rank,
    required this.onOpen,
  });

  final TmdbRankEntry entry;
  final int rank;
  final VoidCallback onOpen;

  Color _rankColor(ThemeData theme) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor(Theme.of(context));
    return TvFocus(
      onActivate: onOpen,
      child: MediaCard(
        title: entry.title,
        posterUrl: entry.posterUrl,
        year: entry.year,
        genre: '',
        rating: entry.rating,
        ageLabel: null,
        fallbackIcon: entry.isTv ? Icons.tv : Icons.movie_outlined,
        onTap: onOpen,
        topBadge: Container(
          alignment: Alignment.center,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: rankColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            '$rank',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

/// Fiche d'information légère pour un élément du classement non présent
/// dans le catalogue de l'abonnement actif.
class _RankEntrySheet extends StatelessWidget {
  const _RankEntrySheet({required this.entry});

  final TmdbRankEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 165,
                      child: entry.posterUrl.isNotEmpty
                          ? OrbitCachedImage(
                              imageUrl: entry.posterUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                entry.isTv
                                    ? Icons.tv
                                    : Icons.movie_outlined,
                                color: scheme.primary,
                              ),
                            )
                          : Icon(
                              entry.isTv ? Icons.tv : Icons.movie_outlined,
                              color: scheme.primary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (entry.year > 0)
                              _infoChip(context, '${entry.year}'),
                            _infoChip(
                              context,
                              '★ ${entry.rating.toStringAsFixed(1)}',
                            ),
                            _infoChip(
                              context,
                              '${_formatCount(entry.voteCount)} votes',
                            ),
                            _infoChip(
                              context,
                              entry.isTv ? 'Série' : 'Film',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.overview.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Synopsis',
                  style:
                      textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.overview,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cette œuvre n\'est pas présente dans votre '
                        'abonnement actif. Découvrez-la sur l\'une des '
                        'plateformes référencées par TMDB.',
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}

/// Rail horizontal des catégories fusionnées films + séries, affiché sous la
/// grille « Récemment » pour parcourir toutes les catégories.
class _UniversalCategoryRail extends StatelessWidget {
  const _UniversalCategoryRail({
    required this.categories,
    required this.onSelected,
  });

  final List<MediaCategory> categories;
  final ValueChanged<MediaCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Explorer par catégorie',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return TvFocus(
                  onActivate: () => onSelected(cat),
                  child: Material(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => onSelected(cat),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints:
                            const BoxConstraints(maxWidth: 220),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: cat.name),
                              if (cat.count > 0)
                                TextSpan(
                                  text: ' (${cat.count})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de recherche large, avec police lisible pour la TV.
class _BrowseSearchField extends StatelessWidget {
  const _BrowseSearchField({
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