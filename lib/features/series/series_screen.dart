import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.series),
        actions: [
          IconButton(
            tooltip: l.searchSeries,
            icon: const Icon(Icons.tv),
            onPressed: () => context.push('/search?type=series'),
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
        child: seriesAsync.when(
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
                            .peekTvLight(s.title, year: s.year > 0 ? s.year : null)
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
                        child: _SeriesSearchField(
                          controller: _searchController,
                          hint: 'Rechercher une série ou un genre…',
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                      Expanded(
                        child: visibleSeries.isEmpty
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
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 160,
                                        childAspectRatio: 0.7,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
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
                                            if (wasFavorite) return;
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '« ${series.title} » ajouté aux favoris',
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
          },
          loading: () => const LoadingState(message: 'Chargement…'),
          error: (err, _) => ErrorState(
            icon: Icons.tv,
            title: l.seriesUnavailable,
            message: userFriendlyError(err),
            onRetry: () => ref.invalidate(seriesProvider),
          ),
        ),
      ),
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
        onTap: onOpen,
        onLongPress: onLongPress,
        isNew: series.isNew,
      ),
    );
  }
}

/// Champ de recherche large, avec police lisible pour la TV.
class _SeriesSearchField extends StatelessWidget {
  const _SeriesSearchField({
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
