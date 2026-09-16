import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';

/// Écran de gestion des téléchargements hors-ligne.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  final DownloadManager _downloadManager = DownloadManager();
  late Stream<List<DownloadTask>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _initDownloadManager();
  }

  Future<void> _initDownloadManager() async {
    await _downloadManager.init();
    setState(() {
      _tasksStream = _downloadManager.tasksStream;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Téléchargements'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              return StreamBuilder<int>(
                stream: _tasksStream
                    .map((tasks) => tasks.where((t) => t.isActive).length),
                builder: (context, snapshot) {
                  final activeCount = snapshot.data ?? 0;
                  if (activeCount == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Chip(
                        label: Text('$activeCount en cours'),
                        avatar: Icon(Icons.download_for_offline,
                            size: 16, color: scheme.onPrimaryContainer),
                        backgroundColor: scheme.primaryContainer,
                        labelStyle: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DownloadTask>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return EmptyState(
              icon: Icons.download_for_offline_outlined,
              title: 'Aucun téléchargement',
              message:
                  'Ajoutez des contenus depuis les détails d\'un film ou d\'une série.',
              action: TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore),
                label: const Text('Explorer'),
              ),
            );
          }

          // Trier: actifs d'abord, puis terminés, puis échoués
          final sortedTasks = [...tasks]..sort((a, b) {
              final aOrder = _statusOrder(a.status);
              final bOrder = _statusOrder(b.status);
              if (aOrder != bOrder) return aOrder.compareTo(bOrder);
              return b.createdAt.compareTo(a.createdAt);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              return DownloadTile(
                task: sortedTasks[index],
                onPause: () => _downloadManager.pause(sortedTasks[index].id),
                onResume: () => _downloadManager.resume(sortedTasks[index].id),
                onCancel: () => _downloadManager.cancel(sortedTasks[index].id),
                onDelete: () => _downloadManager.delete(sortedTasks[index].id),
                onRetry: () => _downloadManager.retry(sortedTasks[index].id),
                onTap: () => _openContent(sortedTasks[index]),
              );
            },
          );
        },
      ),
    );
  }

  int _statusOrder(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.preparing:
        return 0;
      case DownloadStatus.paused:
        return 1;
      case DownloadStatus.completed:
        return 2;
      case DownloadStatus.failed:
        return 3;
      case DownloadStatus.cancelled:
        return 4;
      case DownloadStatus.queued:
        return 4;
    }
  }

  void _openContent(DownloadTask task) {
    // TODO: Naviguer vers le contenu approprié selon le type
    // context.go('/vod/detail', extra: movie) etc.
  }
}

/// Tuile d'un téléchargement avec progression et actions.
class DownloadTile extends ConsumerWidget {
  const DownloadTile({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onDelete,
    required this.onRetry,
    required this.onTap,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne principale: affiche + titre + statut
            Row(
              children: [
                // Poster/Afficher
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 90,
                    child: task.posterUrl != null && task.posterUrl!.isNotEmpty
                        ? Image.network(
                            task.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _posterFallback(context),
                          )
                        : _posterFallback(context),
                  ),
                ),
                const SizedBox(width: 12),
                // Titre + métadonnées
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      if (task.episodeTitle != null) ...[
                        Text(
                          task.episodeTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                      ],
                      _StatusChip(status: task.status),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions principales
                _ActionButtons(
                  task: task,
                  onPause: onPause,
                  onResume: onResume,
                  onCancel: onCancel,
                ),
              ],
            ),
            // Barre de progression
            if (!task.isCompleted && !task.isFailed && !task.isCancelled) ...[
              const SizedBox(height: 12),
              _ProgressBar(
                progress: task.progress,
                isPaused: task.status == DownloadStatus.paused,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.progress.formattedSpeed,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    task.progress.formattedRemaining,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            // Actions secondaires pour terminés/échoués
            if (task.isCompleted || task.isFailed) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (task.isFailed)
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Réessayer'),
                    ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _posterFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.movie_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant, size: 32),
    );
  }
}

/// Chip de statut coloré.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, color, icon) = switch (status) {
      DownloadStatus.downloading => (
          'Téléchargement',
          scheme.primary,
          Icons.download_for_offline
        ),
      DownloadStatus.preparing => (
          'Préparation',
          scheme.primary,
          Icons.hourglass_top
        ),
      DownloadStatus.paused => (
          'En pause',
          scheme.secondary,
          Icons.pause_circle
        ),
      DownloadStatus.completed => ('Terminé', Colors.green, Icons.check_circle),
      DownloadStatus.failed => ('Échec', scheme.error, Icons.error),
      DownloadStatus.cancelled => ('Annulé', scheme.outline, Icons.cancel),
      DownloadStatus.queued => ('En file', scheme.secondary, Icons.schedule),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutons d'action principaux.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (task.status == DownloadStatus.downloading) {
      return IconButton(
        onPressed: onPause,
        icon: Icon(Icons.pause, color: scheme.primary),
        tooltip: 'Mettre en pause',
      );
    } else if (task.status == DownloadStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onResume,
            icon: Icon(Icons.play_arrow, color: scheme.primary),
            tooltip: 'Reprendre',
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.cancel, color: scheme.error),
            tooltip: 'Annuler',
          ),
        ],
      );
    } else if (task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.preparing) {
      return IconButton(
        onPressed: onCancel,
        icon: Icon(Icons.cancel, color: scheme.error),
        tooltip: 'Annuler',
      );
    }
    return const SizedBox.shrink();
  }
}

/// Barre de progression animée.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, this.isPaused = false});

  final DownloadProgress progress;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = progress.fraction.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: fraction,
          backgroundColor: scheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(fraction >= 1.0
              ? Colors.green
              : (isPaused
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          '${(fraction * 100).toStringAsFixed(1)}% • ${_formatBytes(progress.bytesDownloaded)} / ${_formatBytes(progress.totalBytes)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
