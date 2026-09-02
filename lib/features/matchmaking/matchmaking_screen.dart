import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 56, color: scheme.outline),
              const SizedBox(height: 12),
              const Text('Sélectionnez un profil pour voir ses recommandations'),
            ],
          ),
        ),
      );
    }

    final recommendationsAsync = ref.watch(matchmakingProvider(profile.id));
    final hasFavoriteGenres = profile.favoriteGenres.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pour vous · ${profile.firstName}'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(matchmakingProvider(profile.id)),
          ),
        ],
      ),
      body: recommendationsAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return _EmptyState(
              scheme: scheme,
              hasFavoriteGenres: hasFavoriteGenres,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
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

              return MediaCard(
                title: movie.title,
                posterUrl: movie.posterUrl,
                year: movie.year,
                genre: movie.genre,
                rating: movie.rating,
                synopsis: movie.description,
                ageLabel: movie.pegiLabel,
                fallbackIcon: Icons.movie_outlined,
                onTap: onOpen,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorWidget(err.toString()),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme, required this.hasFavoriteGenres});

  final ColorScheme scheme;
  final bool hasFavoriteGenres;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFavoriteGenres ? Icons.movie_filter : Icons.manage_search,
              size: 64,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasFavoriteGenres
                  ? 'Aucun contenu ne matche vos goûts pour l’instant'
                  : 'Pas encore de recommandations',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFavoriteGenres
                  ? 'Essayez d’actualiser ou élargissez vos genres favoris.'
                  : 'Ajoutez vos genres favoris dans votre profil pour voir des films correspondants.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('Modifier mes genres'),
              onPressed: () => context.go('/profiles'),
            ),
          ],
        ),
      ),
    );
  }
}
