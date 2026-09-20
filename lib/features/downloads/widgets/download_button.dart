import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Bouton de téléchargement hors-ligne pour un média VOD/série.
///
/// Réactif : indique l'état existant (queued/downloading/completed) pour ce
/// `mediaItemId` et permet de créer la tâche si elle n'existe pas encore.
class DownloadButton extends ConsumerStatefulWidget {
  const DownloadButton({
    super.key,
    required this.mediaItemId,
    required this.title,
    required this.streamUrl,
    this.posterUrl,
    this.contentType = 'vod',
    this.compact = false,
  });

  final String mediaItemId;
  final String title;
  final String streamUrl;
  final String? posterUrl;
  final String contentType;
  final bool compact;

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _busy = false;

  Future<void> _handleDownload() async {
    if (mounted && _busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await safeAsync<void>(
      () async {
        final manager = ref.read(downloadManagerProvider);
        await manager.init();
        await manager.createTask(
          mediaItemId: widget.mediaItemId,
          title: widget.title,
          streamUrl: widget.streamUrl,
          posterUrl: widget.posterUrl,
          contentType: widget.contentType,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text('« ${widget.title} » ajouté aux téléchargements'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      },
      context: 'DownloadButton.handleDownload',
    );
    if (result.isFailure) {
      final error = result.errorOrNull!.originalError ?? result.errorOrNull!;
      messenger.showSnackBar(
        SnackBar(content: Text(l.downloadFailed(error.toString()))),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tasks = ref.watch(downloadTasksStreamProvider).value;
    final related =
        tasks?.where((t) => t.mediaItemId == widget.mediaItemId).toList() ??
            const <DownloadTask>[];
    final active = related.isNotEmpty;
    final isDone =
        related.any((t) => t.status == DownloadStatus.completed);

    if (active) {
      return Tooltip(
        message: isDone ? 'Téléchargé' : 'Téléchargement en cours',
        child: IconButton(
          icon: Icon(
            isDone ? Icons.download_done : Icons.downloading,
            color: isDone ? Colors.green : scheme.primary,
          ),
          onPressed: null,
        ),
      );
    }

    return Tooltip(
      message: 'Télécharger hors-ligne',
      child: _busy
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: _handleDownload,
            ),
    );
  }
}