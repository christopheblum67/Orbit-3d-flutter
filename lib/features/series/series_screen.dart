import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../models/series.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Séries')),
      body: seriesAsync.when(
        data: (seriesList) => ListView.builder(
          itemCount: seriesList.length,
          itemBuilder: (context, index) {
            final series = seriesList[index];
            return ListTile(
              leading: series.coverUrl.isNotEmpty
                  ? Image.network(series.coverUrl, width: 50, height: 70, fit: BoxFit.cover)
                  : const Icon(Icons.tv),
              title: Text(series.title),
              subtitle: Text('${series.year} - ${series.genre}'),
              onTap: () {
                // TODO: ouvrir le détail de la série avec les épisodes
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
