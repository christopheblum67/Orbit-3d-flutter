import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  String _selectedCategoryId = '';

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(moviesProvider);
    final categoriesAsync = ref.watch(vodCategoriesProvider);
    final hasSidebar =
        MediaQuery.sizeOf(context).width > 600 && categoriesAsync.hasValue;
    return Scaffold(
      appBar: AppBar(title: const Text('Films (VOD)')),
      body: moviesAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return const EmptyState(
              icon: Icons.movie_outlined,
              title: 'Aucun film disponible',
              message: 'La bibliothèque VOD est vide pour le moment.',
            );
          }
          final categories =
              categoriesAsync.value ?? _categoriesFromMovies(movies);
          final visibleMovies = _selectedCategoryId.isEmpty
              ? movies
              : movies
                  .where((movie) => movie.categoryId == _selectedCategoryId)
                  .toList();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasSidebar)
                _CategoryRail(
                  categories: [
                    const MediaCategory(id: '', name: 'Tous'),
                    ...categories,
                  ],
                  selectedId: _selectedCategoryId,
                  onSelected: (id) =>
                      setState(() => _selectedCategoryId = id),
                ),
              Expanded(
                child: visibleMovies.isEmpty
                    ? EmptyState(
                        icon: Icons.movie_outlined,
                        title: _selectedCategoryId.isEmpty
                            ? 'Aucun film disponible'
                            : 'Aucun film dans cette catégorie',
                        message: _selectedCategoryId.isEmpty
                            ? 'La bibliothèque VOD est vide pour le moment.'
                            : 'Aucun film ne correspond à cette catégorie.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: visibleMovies.length,
                        itemBuilder: (context, index) {
                          final movie = visibleMovies[index];
                          void onOpen() {
                            context.push(
                              '/player?url=${Uri.encodeComponent(movie.streamUrl)}&title=${Uri.encodeComponent(movie.title)}',
                            );
                          }

                          return TvFocus(
                            onActivate: onOpen,
                            child: MediaCard(
                              title: movie.title,
                              posterUrl: movie.posterUrl,
                              year: movie.year,
                              genre: movie.genre,
                              rating: movie.rating,
                              synopsis: movie.description,
                              ageLabel: movie.pegiLabel,
                              fallbackIcon: Icons.movie_outlined,
                              onTap: onOpen,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.movie_outlined,
          title: 'Films indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(moviesProvider),
        ),
      ),
    );
  }

  static List<MediaCategory> _categoriesFromMovies(List<Movie> movies) {
    final map = <String, List<String>>{};
    for (final movie in movies) {
      final id = movie.categoryId;
      final name = movie.genre.trim();
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

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
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

