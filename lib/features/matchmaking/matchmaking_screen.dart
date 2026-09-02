import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(
            child:
                Text('Sélectionnez un profil pour voir ses recommandations'),),
      );
    }

    final recommendationsAsync = ref.watch(matchmakingProvider(profile.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Pour vous')),
      body: recommendationsAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'Pas encore de recommandations. Ajoutez vos genres favoris dans votre profil.',),
              ),
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
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
    );
  }
}
