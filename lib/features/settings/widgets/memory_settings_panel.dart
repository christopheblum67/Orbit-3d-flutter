import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';

/// Panneau « Mémoire & Cache » intégré à l'onglet Réglages.
///
/// Chaque action est présentée comme une tuile sur fond de carte (AppCard),
/// dans le même style ergonomique TV que les autres réglages : icône,
/// libellé, sous-titre et bouton d'action à droite.
class MemorySettingsPanel extends ConsumerWidget {
  const MemorySettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final libraryManager = ref.read(mediaLibraryManagerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: scheme.primary),
              title: Text(
                l.memoryPanelTitle,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                l.memoryPanelHelp,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),

        // Option 1 : Vider les récemment regardés
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history, color: scheme.primary),
              title: Text(
                l.memoryHistoryTitle,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l.memoryHistoryHelp,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l.memoryClear),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final profileId = ref.read(currentProfileProvider)?.id ?? '';
                  await libraryManager.clearRecentlyWatched();
                  await ref.read(historyServiceProvider).clearAll();
                  await ref
                      .read(recentlyWatchedProvider.notifier)
                      .clearForCurrentProfile();
                  await ref
                      .read(playbackProgressServiceProvider)
                      .clearForProfile(profileId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.playHistoryCleared)),
                    );
                  }
                },
              ),
            ),
          ),
        ),

        // Option 2 : Purge du cache des vignettes
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.image, color: scheme.primary),
              title: Text(
                l.memoryImagesTitle,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l.memoryImagesHelp,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: Text(l.memoryPurge),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.coverCacheCleared)),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
