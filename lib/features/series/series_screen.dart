import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(seriesProvider);
    final categoriesAsync = ref.watch(seriesCategoriesProvider);
    final hasSidebar =
        MediaQuery.sizeOf(context).width > 600 && categoriesAsync.hasValue;
    return Scaffold(
      appBar: AppBar(title: const Text('Séries')),
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
          final visibleSeries = _selectedCategoryId.isEmpty
              ? seriesList
              : seriesList
                  .where((s) => s.categoryId == _selectedCategoryId)
                  .toList();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasSidebar)
                _SeriesCategoryRail(
                  categories: [
                    const MediaCategory(id: '', name: 'Tous'),
                    ...categories,
                  ],
                  selectedId: _selectedCategoryId,
                  onSelected: (id) =>
                      setState(() => _selectedCategoryId = id),
                ),
              Expanded(
                child: visibleSeries.isEmpty
                    ? const EmptyState(
                        icon: Icons.tv,
                        title: 'Aucune série dans cette catégorie',
                        message: 'Aucune série ne correspond à cette catégorie.',
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

                                  return TvFocus(
                                    onActivate: onOpen,
                                    child: MediaCard(
                                      title: series.title,
                                      posterUrl: series.coverUrl,
                                      year: series.year,
                                      genre: series.genre,
                                      rating: series.rating,
                                      synopsis: series.description,
                                      ageLabel: series.pegiLabel,
                                      fallbackIcon: Icons.tv,
                                      onTap: onOpen,
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

class _SeriesCategoryRail extends StatelessWidget {
  const _SeriesCategoryRail({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<MediaCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Catégories',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          for (final category in categories)
            _CategoryTile(
              name: category.name,
              selected: category.id == selectedId,
              onTap: () => onSelected(category.id),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              selected ? Icons.folder_open : Icons.folder_outlined,
              size: 18,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
