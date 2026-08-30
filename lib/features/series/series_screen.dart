import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../core/widgets/widgets.dart';
import '../../services/user_friendly_error.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesProvider);
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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SectionHeader(
                  icon: Icons.auto_awesome,
                  title: 'Séries',
                  subtitle: '${seriesList.length} titres',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final series = seriesList[index];
                      return MediaCard(
                        title: series.title,
                        posterUrl: series.coverUrl,
                        year: series.year,
                        genre: series.genre,
                        rating: series.rating,
                        synopsis: series.description,
                        ageLabel: series.pegiLabel,
                        fallbackIcon: Icons.tv,
                      );
                    },
                    childCount: seriesList.length,
                  ),
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
}