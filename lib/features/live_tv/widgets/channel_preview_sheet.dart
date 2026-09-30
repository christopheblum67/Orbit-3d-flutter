import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/core/widgets/cached_image.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Aperçu d'une chaîne avant de lancer la lecture.
///
/// L'app lançait directement le flux : un appui sur une tuile de la grille
/// lançait la lecture immédiatement. Deux problèmes, un sur le fond, un sur le
/// geste :
///
///  - le flux part avant que l'utilisateur ait vu *quelle* chaîne il a
///    sélectionnée (la tuile ne montre qu'un logo, pas le programme) ;
///  - un appui-mal.Lock sur la grille figeait la télé, sans retour.
///
/// L'aperçu sert les deux : il affiche le logo, le programme en cours et le
/// suivant, et réserve le lancement au bouton explicite.
class ChannelPreviewSheet extends ConsumerWidget {
  const ChannelPreviewSheet({
    super.key,
    required this.channel,
    required this.onWatch,
  });

  final Channel channel;

  /// Déclenche la lecture. Recevra le context parent pour une navigation.
  final VoidCallback onWatch;

  static Future<void> show(
    BuildContext context, {
    required Channel channel,
    required VoidCallback onWatch,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ChannelPreviewSheet(
        channel: channel,
        onWatch: onWatch,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // EPG de la chaîne : même chemin que la grille, donc même source de vérité.
    // `primaryEpgChannelId` évite de demander le replay d'une chaîne sans EPG.
    final epgAsync = ref.watch(
      channelEpgProvider(channel.primaryEpgChannelId),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : logo + nom de la chaîne ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 56,
                  child: channel.logoUrl.isEmpty
                      ? Icon(
                          Icons.live_tv,
                          size: 32,
                          color: scheme.onSurfaceVariant,
                        )
                      : Padding(
                          // Un logo de chaîne est un wordmark large : `contain`
                          // avec une marge évite le rognage de `cover`, qui le
                          // faisait déborder.
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: CachedImage(
                            imageUrl: channel.logoUrl,
                            width: 96,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (channel.groupLabel.isNotEmpty)
                        Text(
                          channel.groupLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context)
                      .closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Programme en cours / suivant ───────────────────────────────
            Flexible(
              child: epgAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _noEpg(context, l),
                data: (programs) {
                  if (programs.isEmpty) return _noEpg(context, l);
                  final now = DateTime.now();
                  final current = epgCurrentProgram(programs, now);
                  final next = epgNextProgram(programs, now);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current != null) ...[
                        _ProgramBlock(program: current, now: now, live: true),
                        const SizedBox(height: 14),
                      ],
                      if (next != null)
                        _ProgramBlock(program: next, now: now, live: false),
                      if (current == null && next == null)
                        _noEpg(context, l),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Bouton de lancement ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.watchLive),
                onPressed: () {
                  // On ferme d'abord : la feuille est modale, elle masquerait
                  // le lecteur qui s'ouvre par-dessus.
                  Navigator.of(context).maybePop();
                  onWatch();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noEpg(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.noProgramInfoAvailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloc d'un programme : titre, créneau, résumé.
class _ProgramBlock extends StatelessWidget {
  const _ProgramBlock({
    required this.program,
    required this.now,
    required this.live,
  });

  final EPGProgram program;
  final DateTime now;
  final bool live;

  static const _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String _hhmm(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// « 20:00 » si même jour, sinon « 12 sept. 20:00 ».
  String _stamp(DateTime d) {
    final l = d.toLocal();
    if (l.year == now.year && l.month == now.month && l.day == now.day) {
      return _hhmm(l);
    }
    return '${l.day} ${_months[l.month - 1]} ${_hhmm(l)}';
  }

  /// Progression du programme en cours, pour la barre de contexte.
  double _progress() {
    final total = program.end.difference(program.start).inSeconds;
    if (total <= 0) return 0;
    final done = now.difference(program.start).inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (live) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DIRECT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                '${_stamp(program.start)} - ${_stamp(program.end)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          program.title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (program.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            program.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (live) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress(),
              minHeight: 3,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}
