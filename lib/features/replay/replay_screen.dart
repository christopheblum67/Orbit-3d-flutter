import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/sort_options_dialog.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  String _selectedCategoryId = '';
  SortMode _selectedSortMode = SortMode.nameAsc;

  void _openSortDialog() {
    SortOptionsDialogTV.show(
      context,
      currentMode: _selectedSortMode,
      onSortSelected: (newMode) => setState(() => _selectedSortMode = newMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final replaysAsync = ref.watch(replaysProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay'),
        actions: [
          IconButton(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            onPressed: _openSortDialog,
          ),
        ],
      ),
      body: replaysAsync.when(
        data: (replays) {
          if (replays.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 56, color: Colors.grey,),
                  SizedBox(height: 16),
                  Text(
                    'Aucun replay disponible',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les replays n\'apparaissent ici quand ils sont proposés par ton abonnement.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final categories = _categoriesFromReplays(replays);
          final filteredReplays = _selectedCategoryId.isEmpty
              ? replays
              : replays
                  .where((r) => r.categoryId == _selectedCategoryId)
                  .toList();
          final libraryManager = ref.read(mediaLibraryManagerProvider);
          final mediaItems = filteredReplays.map((r) => MediaItem(
            id: r.id,
            title: r.title,
            streamUrl: r.streamUrl,
            posterUrl: '', // ReplayItem doesn't have posterUrl
            categoryId: r.categoryId,
            rating: 0.0,
            releaseYear: 0,
            durationMinutes: 0,
            addedDate: DateTime.now(),
          ),).toList();
          final sortedItems = libraryManager.applySort(mediaItems, _selectedSortMode);
          final visibleReplays = sortedItems.map((item) => replays.firstWhere((r) => r.id == item.id)).toList();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (categories.isNotEmpty)
                CategoriesRail(
                  categories: [
                    const MediaCategory(id: '', name: 'Tous'),
                    ...categories,
                  ],
                  selectedId: _selectedCategoryId,
                  onSelected: (id) =>
                      setState(() => _selectedCategoryId = id),
                ),
              Expanded(
                child: visibleReplays.isEmpty
                    ? const Center(child: Text('Aucun replay dans cette catégorie'))
                    : ListView.builder(
                        itemCount: visibleReplays.length,
                        itemBuilder: (context, index) {
                          final replay = visibleReplays[index];
                          return ListTile(
                            leading: const Icon(Icons.replay),
                            title: Text(replay.title),
                            subtitle: Text(
                              '${replay.startTime} - ${replay.endTime}',
                            ),
                            onTap: () {
                              context.push(
                                '/player?url=${Uri.encodeComponent(replay.streamUrl)}&title=${Uri.encodeComponent(replay.title)}&type=replay',
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.replay,
          title: 'Replays indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(replaysProvider),
        ),
      ),
    );
  }

  static List<MediaCategory> _categoriesFromReplays(List<ReplayItem> replays) {
    final map = <String, String>{};
    for (final replay in replays) {
      final id = replay.categoryId;
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => id);
    }
    return [
      for (final entry in map.entries) MediaCategory(id: entry.key, name: entry.value),
    ];
  }
}
