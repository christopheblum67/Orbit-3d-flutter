import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
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

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(seriesProvider);
    final categoriesAsync = ref.watch(seriesCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Séries'),
        actions: [
          IconButton(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            onPressed: _openSortDialog,
          ),
        ],
      ),
      body: seriesAsync.when(
        data: (seriesList) {
          if (seriesList.isEmpty) {
            return const EmptyState(
              icon: Icons.tv,
              title: 'Aucune série disponible',
              message: 'La bibliothèque de séries est vide pour le moment.',
            );
          }
          final categories = categoriesAsync.value ??
              _categoriesFromSeries(seriesList);
          final q = _query.trim().toLowerCase();
          final filteredSeries = _selectedCategoryId.isEmpty
              ? seriesList
              : seriesList
                  .where((s) => s.categoryId == _selectedCategoryId)
                  .toList();
          final queryFiltered = q.isEmpty
              ? filteredSeries
              : filteredSeries
                  .where(
                    (s) =>
                        s.title.toLowerCase().contains(q) ||
                        s.genre.toLowerCase().contains(q),
                  )
                  .toList();
          final libraryManager = ref.read(mediaLibraryManagerProvider);
          final mediaItems = queryFiltered.map((s) => MediaItem(
            id: s.id,
            title: s.title,
            streamUrl: '', // Series n'ont pas de streamUrl direct
            posterUrl: s.coverUrl,
            categoryId: s.categoryId,
            rating: s.rating,
            releaseYear: s.year,
            durationMinutes: 0,
            addedDate: DateTime.now(),
          ),).toList();
          final sortedItems = libraryManager.applySort(mediaItems, _selectedSortMode);
          final seriesById = <String, Series>{
            for (final s in queryFiltered)
              if (s.id.isNotEmpty) s.id: s,
          };
          final visibleSeries = sortedItems.map<Series>((item) {
            return seriesById[item.id] ?? queryFiltered.firstWhere(
              (s) => s.id == item.id,
              orElse: () => queryFiltered.first,
            );
          }).toList();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CategoriesRail(
                categories: [
                  const MediaCategory(id: '', name: 'Tous'),
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
                      child: _SeriesSearchField(
                        controller: _searchController,
                        hint: 'Rechercher une série ou un genre…',
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    Expanded(
                      child: visibleSeries.isEmpty
                          ? const EmptyState(
                              icon: Icons.tv,
                              title: 'Aucun résultat',
                              message: 'Aucune série ne correspond à cette recherche.',
                            )
                          : CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: SectionHeader(
                                    icon: Icons.auto_awesome,
                                    title: 'Séries',
                                    subtitle:
                                        '${visibleSeries.length} titres',
                                  ),
                                ),
                                SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 200,
                                      childAspectRatio: 0.62,
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
                                          ref
                                              .read(favoritesServiceProvider)
                                              .addFavorite('series', series.id);
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '« ${series.title} » ajouté aux favoris',
                                                ),
                                                duration:
                                                    const Duration(milliseconds: 1500),
                                              ),
                                            );
                                        }

                                        return TvFocus(
                                          onActivate: onOpen,
                                          child: MediaCard(
                                            title: series.title,
                                            posterUrl: series.coverUrl,
                                            year: series.year,
                                            genre: series.genre,
                                            rating: series.rating,
                                            ageLabel: series.pegiLabel,
                                            fallbackIcon: Icons.tv,
                                            onTap: onOpen,
                                            onLongPress: onLongPress,
                                          ),
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
          title: 'Séries indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(seriesProvider),
        ),
      ),
    );
  }

  static List<MediaCategory> _categoriesFromSeries(List<Series> seriesList) {
    final map = <String, List<String>>{};
    for (final series in seriesList) {
      final id = series.categoryId;
      final name = series.genre.trim();
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => []).add(name);
    }
    return map.entries.map((e) {
      final names = e.value.where((n) => n.isNotEmpty).toSet().toList();
      return MediaCategory(
        id: e.key,
        name: names.isEmpty ? e.key : names.join(', '),
      );
    }).toList();
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

