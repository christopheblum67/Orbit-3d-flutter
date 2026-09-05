import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';
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
    final moviesAsync = ref.watch(moviesProvider);
    final categoriesAsync = ref.watch(vodCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Films (VOD)'),
        actions: [
          IconButton(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            onPressed: _openSortDialog,
          ),
        ],
      ),
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
          final q = _query.trim().toLowerCase();
          final filteredMovies = _selectedCategoryId.isEmpty
              ? movies
              : movies
                  .where((movie) => movie.categoryId == _selectedCategoryId)
                  .toList();
          final queryFiltered = q.isEmpty
              ? filteredMovies
              : filteredMovies
                  .where(
                    (m) =>
                        m.title.toLowerCase().contains(q) ||
                        m.genre.toLowerCase().contains(q),
                  )
                  .toList();
          final libraryManager = ref.read(mediaLibraryManagerProvider);
          final mediaItems = queryFiltered
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
                  addedDate: DateTime.now(),
                ),
              )
              .toList();
          final sortedItems =
              libraryManager.applySort(mediaItems, _selectedSortMode);
          final movieById = <String, Movie>{
            for (final m in queryFiltered)
              if (m.id.isNotEmpty) m.id: m,
          };
          final visibleMovies = sortedItems.map<Movie>((item) {
            return movieById[item.id] ??
                queryFiltered.firstWhere(
                  (m) => m.id == item.id,
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
                              title: _selectedCategoryId.isEmpty
                                  ? 'Aucun résultat'
                                  : 'Aucun film dans cette catégorie',
                              message: _selectedCategoryId.isEmpty
                                  ? 'Aucun film ne correspond à cette recherche.'
                                  : 'Aucun film ne correspond à cette catégorie.',
                            )
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                  context.push('/vod/detail', extra: movie);
                                }

                                void onLongPress() {
                                  ref
                                      .read(favoritesServiceProvider)
                                      .addFavorite('movie', movie.id);
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '« ${movie.title} » ajouté aux favoris'),
                                        duration:
                                            const Duration(milliseconds: 1500),
                                      ),
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
                                    ageLabel: movie.pegiLabel,
                                    fallbackIcon: Icons.movie_outlined,
                                    onTap: onOpen,
                                    onLongPress: onLongPress,
                                  ),
                                );
                              },
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
