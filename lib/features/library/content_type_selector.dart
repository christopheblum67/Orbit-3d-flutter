import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/downloads/downloads_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Sélecteur du type de contenu, commun aux deux onglets.
///
/// Un-segment horizontal plutôt qu'une seconde barre d'onglets : imbriquer des
/// `TabBar` dans un `TabBarView` fonctionne, mais deux barres d'onglets
/// superposees se disputent la meme place verticale et l'une mange la hauteur
/// de l'autre. Le choix reste explicite et lisible, avec le compte par type.
class ContentTypeSelector extends StatelessWidget {
  const ContentTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.counts = const {},
  });

  final ContentType selected;
  final ValueChanged<ContentType> onChanged;
  final Map<ContentType, int> counts;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = <ContentType, String>{
      ContentType.live: l.liveTv,
      ContentType.vod: l.films,
      ContentType.series: l.series,
      ContentType.replay: l.replay,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final type in ContentType.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected == type,
                onSelected: (_) => onChanged(type),
                avatar: Icon(_iconFor(type), size: 18),
                label: Text(_withCount(labels[type] ?? '', counts[type] ?? 0)),
              ),
            ),
        ],
      ),
    );
  }

  static String _withCount(String label, int count) =>
      count > 0 ? '$label ($count)' : label;

  static IconData _iconFor(ContentType type) {
    switch (type) {
      case ContentType.live:
        return Icons.live_tv;
      case ContentType.vod:
        return Icons.movie;
      case ContentType.series:
        return Icons.tv;
      case ContentType.replay:
        return Icons.replay;
    }
  }
}

/// Téléchargements filtrés par type de contenu.
///
/// `DownloadTask.contentType` est une chaîne libre ('vod', 'series', 'live',
/// 'replay') : elle vient d'un appel externe au typage, on la compare donc avec
/// la même tolérance everywhere plutôt que de la caster en `ContentType` et
/// risquer une exception sur une valeur inattendue.
class DownloadsSection extends ConsumerWidget {
  const DownloadsSection({super.key, required this.type});

  final ContentType type;

  static const Map<ContentType, String> _keys = {
    ContentType.live: 'live',
    ContentType.vod: 'vod',
    ContentType.series: 'series',
    ContentType.replay: 'replay',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tasks =
        ref.watch(downloadTasksStreamProvider).value ?? const <DownloadTask>[];

    final wanted = _keys[type]!;
    final mine = tasks.where((t) => t.contentType == wanted).toList();
    if (mine.isEmpty) {
      return _Empty(icon: Icons.download_outlined, message: l.noDownloads);
    }
    return DownloadList(tasks: mine);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
