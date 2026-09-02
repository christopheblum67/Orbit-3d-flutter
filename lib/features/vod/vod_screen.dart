import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  String _selectedGenre = '';

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(moviesProvider);
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
          final genres = <String>{
            for (final movie in movies)
              if (movie.genre.trim().isNotEmpty) movie.genre.trim(),
          }.toList()
            ..sort();
          final visibleMovies = _selectedGenre.isEmpty
              ? movies
              : movies
                  .where((movie) => movie.genre.trim() == _selectedGenre)
                  .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GenreFilterBar(
                genres: genres,
                selectedGenre: _selectedGenre,
                onSelected: (genre) => setState(() => _selectedGenre = genre),
              ),
              Expanded(
                child: visibleMovies.isEmpty
                    ? const EmptyState(
                        icon: Icons.movie_outlined,
                        title: 'Aucun film dans cette catégorie',
                        message: 'Aucun film ne correspond à ce filtre.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
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
}

class _GenreFilterBar extends StatelessWidget {
  const _GenreFilterBar({
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  final List<String> genres;
  final String selectedGenre;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _GenreChip(
            label: 'Tous',
            selected: selectedGenre.isEmpty,
            scheme: scheme,
            onTap: () => onSelected(''),
          ),
          for (final genre in genres) ...[
            const SizedBox(width: 8),
            _GenreChip(
              label: genre,
              selected: selectedGenre == genre,
              scheme: scheme,
              onTap: () => onSelected(genre),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHigh,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
