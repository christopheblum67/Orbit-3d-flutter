import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Panneau « Mémoire & Cache » intégré à l'onglet Réglages.
///
/// Chaque action est présentée comme une tuile sur fond de carte (AppCard),
/// dans le même style ergonomique TV que les autres réglages : icône,
/// libellé, sous-titre et bouton d'action à droite.
class MemorySettingsPanel extends ConsumerWidget {
  const MemorySettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: const Text(
                'Gestion de la Mémoire & Cache',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Libérez de l\'espace et nettoyez les données locales.',
                style: TextStyle(fontSize: 11, color: Colors.white38),
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
              title: const Text(
                'Vider l\'historique des vues',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Efface la liste des récemment regardés et les positions de reprise.',
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Effacer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  await libraryManager.clearRecentlyWatched();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Historique de lecture effacé.')),
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
              title: const Text(
                'Nettoyer le cache des pochettes',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Libère l\'espace disque occupé par les vignettes VOD/EPG stockées localement.',
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('Purger'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache des pochettes purgé.')),
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