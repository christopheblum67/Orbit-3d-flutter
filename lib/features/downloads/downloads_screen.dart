import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/widgets/cached_image.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';

/// Ã‰cran de gestion des tÃ©lÃ©chargements hors-ligne.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  final DownloadManager _downloadManager = DownloadManager();

  /// AffectÃ© dans `initState()`, donc avant le premier `build()`.
  ///
  /// Ne dÃ©pend pas de l'`await` de `init()` : `tasksStream` est un getter sur
  /// le singleton `DownloadManager`. Avant ce correctif, le champ Ã©tait `late`
  /// et affectÃ© APRÃˆS l'ouverture de Hive â€” or `_firstBuild()` appelle
  /// `initState()` puis `build()` dans le mÃªme frame, donc le premier rendu
  /// levait `LateInitializationError`.
  late final Stream<List<DownloadTask>> _tasksStream;

  /// DÃ©rivation mÃ©morisÃ©e.
  ///
  /// `StreamBuilder(stream: source.map(...))` construisait un NOUVEAU stream Ã 
  /// chaque `build`, donc le builder se rÃ©abonnait Ã  la source Ã  chaque
  /// reconstruction â€” donc perdait son Ã©tat et reprenait depuis le dÃ©but du
  /// flux Hive.
  late final Stream<int> _activeCountStream;

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _tasksStream = _downloadManager.tasksStream;
    _activeCountStream =
        _tasksStream.map((tasks) => tasks.where((t) => t.isActive).length);
    _initDownloadManager();
  }

  Future<void> _initDownloadManager() async {
    await _downloadManager.init();
    // Garde obligatoire : l'utilisateur peut Ãªtre restÃ© sur l'Ã©cran pendant
    // l'ouverture de Hive. `setState` sur un State dÃ©montÃ© est une exception.
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.downloads),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              return StreamBuilder<int>(
                stream: _activeCountStream,
                builder: (context, snapshot) {
                  final activeCount = snapshot.data ?? 0;
                  if (activeCount == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Chip(
                        label: Text(l.activeCountOngoing(activeCount)),
                        avatar: Icon(
                          Icons.download_for_offline,
                          size: 16,
                          color: scheme.onPrimaryContainer,
                        ),
                        backgroundColor: scheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
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
          // Tant que Hive n'est pas ouvert, le flux n'Ã©met rien : on affiche
          // le loader pour Ã©viter un "aucun tÃ©lÃ©chargement" trompeur.
          if (!_ready || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return EmptyState(
              icon: Icons.download_for_offline_outlined,
              title: l.noDownloads,
              message: l.downloadsEmptyHint,
              action: TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore),
                label: Text(l.explore),
              ),
            );
          }

          return DownloadList(tasks: tasks);
        },
      ),
    );
  }
}

/// Rang d'affichage d'un statut : actifs d'abord, puis terminÃ©s, puis Ã©chouÃ©s.
///
/// ExposÃ©e pour que l'Ã©cran Â« Mes contenus Â» trie ses sections de la mÃªme
/// faÃ§on, sans dupliquer une rÃ¨gle qui n'a de sens qu'Ã  un endroit.
int downloadStatusOrder(DownloadStatus status) {
  switch (status) {
    case DownloadStatus.downloading:
    case DownloadStatus.preparing:
      return 0;
    case DownloadStatus.queued:
      return 1;
    case DownloadStatus.paused:
      return 2;
    case DownloadStatus.completed:
      return 3;
    case DownloadStatus.failed:
      return 4;
    case DownloadStatus.cancelled:
      return 5;
  }
}

/// Liste de tÃ©lÃ©chargements, filtrable par l'appelant.
///
/// Extraite de l'Ã©cran pour Ãªtre rÃ©utilisÃ©e telle quelle par Â« Mes contenus Â» :
/// `DownloadTile` exige six callbacks, dont l'ouverture du contenu, qui
/// reposait sur du code privÃ©. Dupliquer cette logique aurait produit deux
/// listes qui divergent au premier correctif.
class DownloadList extends StatelessWidget {
  const DownloadList({super.key, required this.tasks});

  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context) {
    final manager = DownloadManager();
    final sorted = [...tasks]..sort((a, b) {
        final byStatus = downloadStatusOrder(a.status)
            .compareTo(downloadStatusOrder(b.status));
        if (byStatus != 0) return byStatus;
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView.builder(
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      padding: const EdgeInsets.all(16),
      addAutomaticKeepAlives: false,
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final task = sorted[index];
        return DownloadTile(
          task: task,
          onPause: () => manager.pause(task.id),
          onResume: () => manager.resume(task.id),
          onCancel: () => manager.cancel(task.id),
          onDelete: () => manager.delete(task.id),
          onRetry: () => manager.retry(task.id),
          onTap: () => openDownloadedContent(context, task),
        );
      },
    );
  }
}

/// Ouvre le contenu d'un tÃ©lÃ©chargement terminÃ©.
///
/// Les routes `/live/detail` et `/replay/detail` n'existent pas : y naviguer
/// depuis une liste ne pouvait donc rien ouvrir. On renvoie vers l'accueil
/// plutÃ´t que de pousser une route inconnue.
void openDownloadedContent(BuildContext context, DownloadTask task) {
  final id = task.mediaItemId;
  final seriesId = task.seriesId;
  final season = task.seasonNumber;
  final episode = task.episodeNumber;

  switch (task.contentType) {
    case 'vod':
      context.go('/vod/detail', extra: {'id': id});
    case 'series':
      if (seriesId != null && season != null && episode != null) {
        // L'Ã©cran de dÃ©tail d'Ã©pisode gÃ¨re l'extra, on garde l'existant.
        context.go(
          '/episode/detail',
          extra: {
            'seriesId': seriesId,
            'season': season,
            'episode': episode,
          },
        );
      } else if (seriesId != null) {
        context.go(
          '/series/detail?id=${Uri.encodeComponent(seriesId)}',
        );
      }
    // Aucun tÃ©lÃ©chargement Live ni Replay n'est possible : le gestionnaire
    // refuse les playlists HLS. Le cas reste traitÃ© pour ne pas rester muet si
    // un fichier direct se glisse dans la liste un jour.
    case 'live':
      context.go('/live');
    case 'replay':
      context.go('/replay');
    default:
      context.go('/home');
  }
}

/// Lance la lecture **directe** d'un fichier tÃ©lÃ©chargÃ© (hors-ligne).
/// N'utilise pas le flux rÃ©seau â€” passe par le lecteur interne avec le chemin local.
void playDownloadedContent(BuildContext context, DownloadTask task) {
  if (!task.isFileExists) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fichier introuvable : ${task.localPath}')),
    );
    return;
  }
  context.go('/player', extra: {
    'url': task.localPath,
    'title': task.title,
    'isLocalFile': true,
    'headers': task.headers,
    'posterUrl': task.posterUrl,
  });
}

/// Tuile d'un tÃ©lÃ©chargement avec progression et actions.
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
    final l = AppLocalizations.of(context);

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
                        ? CachedImage(
                            imageUrl: task.posterUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _posterFallback(context),
                          )
                        : _posterFallback(context),
                  ),
                ),
                const SizedBox(width: 12),
                // Titre + mÃ©tadonnÃ©es
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
            // Actions secondaires pour terminÃ©s/Ã©chouÃ©s
            if (task.isCompleted || task.isFailed) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (task.isCompleted) ...[
                    FilledButton.icon(
                      onPressed: () => playDownloadedContent(context, task),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(l.play),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.isFailed)
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l.retry),
                    ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l.cancel),
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
      child: Icon(
        Icons.movie_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }
}

/// Chip de statut colorÃ©.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    final (label, color, icon) = switch (status) {
      DownloadStatus.downloading => (
          l.downloadStatusDownloading,
          scheme.primary,
          Icons.download_for_offline
        ),
      DownloadStatus.preparing => (
          l.downloadStatusPreparing,
          scheme.primary,
          Icons.hourglass_top
        ),
      DownloadStatus.paused => (
          l.downloadStatusPaused,
          scheme.secondary,
          Icons.pause_circle
        ),
      DownloadStatus.completed => (
          l.downloadStatusCompleted,
          Colors.green,
          Icons.check_circle,
        ),
      DownloadStatus.failed => (
          l.downloadStatusFailed,
          scheme.error,
          Icons.error
        ),
      DownloadStatus.cancelled => (
          l.downloadStatusCancelled,
          scheme.outline,
          Icons.cancel,
        ),
      DownloadStatus.queued => (
          l.downloadStatusQueued,
          scheme.secondary,
          Icons.schedule,
        ),
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
    final l = AppLocalizations.of(context);

    if (task.status == DownloadStatus.downloading) {
      return IconButton(
        onPressed: onPause,
        icon: Icon(Icons.pause, color: scheme.primary),
        tooltip: l.pauseDownload,
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
            tooltip: l.cancel,
          ),
        ],
      );
    } else if (task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.preparing) {
      return IconButton(
        onPressed: onCancel,
        icon: Icon(Icons.cancel, color: scheme.error),
        tooltip: l.cancel,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Barre de progression animÃ©e.
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
          valueColor: AlwaysStoppedAnimation<Color>(
            fraction >= 1.0
                ? Colors.green
                : (isPaused
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary),
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          '${(fraction * 100).toStringAsFixed(1)}% â€¢ ${_formatBytes(progress.bytesDownloaded)} / ${_formatBytes(progress.totalBytes)}',
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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}




