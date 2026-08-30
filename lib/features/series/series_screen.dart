import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../core/widgets/widgets.dart';

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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                icon: Icons.auto_awesome,
                title: 'Séries',
                subtitle: '${seriesList.length} titres',
              ),
              const SizedBox(height: 8),
              for (final series in seriesList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChannelTile(
                    title: series.title,
                    subtitle: '${series.year} – ${series.genre}',
                    icon: Icons.tv,
                    imageUrl: series.coverUrl,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}