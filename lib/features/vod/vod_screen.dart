import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/tv_focus.dart';
import '../../core/widgets/widgets.dart';

class VodScreen extends ConsumerWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}