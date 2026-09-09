import 'package:flutter/material.dart';
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
  SortMode _selectedSortMode = SortMode.nameAsc;
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
              _BrowseTab.flixpatrol => const _FlixPatrolPlaceholder(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoriesRail(
          categories: [
            const MediaCategory(id: '', name: 'Tous'),
            const MediaCategory(id: 'fav', name: 'Favoris'),
            const MediaCategory(id: 'recent', name: 'Récemment'),
            ...categories,
          ],
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
    final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];
    final seriesList =
        ref.watch(seriesProvider).valueOrNull ?? const <Series>[];

    final vodList = vod.value ?? _categoriesFromMovies(movies);
    final seriesCats = series.value ?? _categoriesFromSeries(seriesList);
    final merged = <String, MediaCategory>{
      for (final c in [...vodList, ...seriesCats])
        if (c.id.isNotEmpty) c.id: c,
    };
    return merged.values.toList();
  }

  /// Sélectionne une catégorie depuis le rail universel : dans l'onglet courant
  /// si elle y existe, sinon on bascule sur l'autre onglet.
  void _selectUniversalCategory(MediaCategory cat) {
    final currentCats = _tab == _BrowseTab.series
        ? (ref.read(seriesCategoriesProvider).valueOrNull ??
            const <MediaCategory>[])
        : (ref.read(vodCategoriesProvider).valueOrNull ??
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
    final map = <String, Set<String>>{};
    for (final (id, name) in items) {
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => {}).add(name);
    }
    return map.entries.map((e) {
      return MediaCategory(
        id: e.key,
        name: e.value.where((n) => n.isNotEmpty).join(', '),
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

/// Emplacement réservé pour FlixPatrol (classements populaires).
class _FlixPatrolPlaceholder extends StatelessWidget {
  const _FlixPatrolPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'FlixPatrol',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Classements des films & séries les plus regardés '
              'arrivent bientôt.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Bientôt disponible',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                        child: Text(
                          cat.name,
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