import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/core/widgets/cached_image.dart';

/// Écran Catch-up (rattrapage) pour une chaîne spécifique.
///
/// Affiche :
/// - Header avec logo/nom de la chaîne
/// - Barre horizontale de dates (7-14 jours glissants)
/// - Liste verticale des programmes EPG du jour sélectionné
///   avec titre, horaire, description complète, et bouton Replay si disponible.
class CatchUpScreen extends ConsumerWidget {
  const CatchUpScreen({
    super.key,
    required this.channel,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Programmes passés + à venir via l'EPG COMPLET de la chaîne
    // (`get_simple_data_table`), source du rattrapage multi-jours.
    final catchUpAsync = ref.watch(channelCatchUpProvider(channel.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141C),
        leading: TvFocus(
          onActivate: () => context.pop(),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        title: Row(
          children: [
            if (channel.logoUrl.isNotEmpty)
              CachedImage(
                imageUrl: channel.logoUrl,
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.tv, color: Colors.white70, size: 28),
              )
            else
              const Icon(Icons.tv, color: Colors.white70, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: catchUpAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return Center(
              child: Text(
                l.noProgramInfoAvailable,
                style: const TextStyle(color: Colors.white38, fontSize: 16),
              ),
            );
          }
          // Grouper par date (clé yyyy-MM-dd)
          final byDate = <String, List<EPGProgram>>{};
          for (final p in programs) {
            final key = _dateKey(p.start);
            (byDate[key] ??= <EPGProgram>[]).add(p);
          }
          // Trier les dates : plus récent d'abord
          final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
          // Date sélectionnée par défaut : aujourd'hui si présent, sinon la plus récente
          final now = DateTime.now();
          final todayKey = _dateKey(now);
          final defaultDate = dates.contains(todayKey)
              ? todayKey
              : (dates.isNotEmpty ? dates.first : null);

          return _CatchUpContent(
            channel: channel,
            byDate: byDate,
            dates: dates,
            initialDateKey: defaultDate,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFriendlyError(e))),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Contenu avec état (date sélectionnée)
class _CatchUpContent extends ConsumerStatefulWidget {
  const _CatchUpContent({
    required this.channel,
    required this.byDate,
    required this.dates,
    this.initialDateKey,
  });

  final Channel channel;
  final Map<String, List<EPGProgram>> byDate;
  final List<String> dates;
  final String? initialDateKey;

  @override
  ConsumerState<_CatchUpContent> createState() => _CatchUpContentState();
}

class _CatchUpContentState extends ConsumerState<_CatchUpContent> {
  late String? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _selectedDateKey = widget.initialDateKey;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDateKey == null || widget.dates.isEmpty) {
      return const SizedBox.shrink();
    }

    final programs = widget.byDate[_selectedDateKey!] ?? [];
    final now = DateTime.now();

    return Column(
      children: [
        // Barre de dates horizontale (scrollable)
        _DatePickerBar(
          availableDateKeys: widget.dates,
          selectedDateKey: _selectedDateKey!,
          onDateSelected: (key) => setState(() => _selectedDateKey = key),
        ),
        // Liste des programmes
        Expanded(
          child: programs.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).noProgramInfoAvailable,
                    style: const TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
              : FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: programs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final program = programs[index];
                      final replayable = isReplayableProgram(
                        program,
                        now: now,
                        channelSupportsReplay: widget.channel.supportsReplay,
                      );
                      return TvFocus(
                        autofocus: index == 0,
                        onActivate: replayable ? () => _playReplay(program) : null,
                        child: _ProgramTile(
                          program: program,
                          channel: widget.channel,
                          replayable: replayable,
                          onReplayTap:
                              replayable ? () => _playReplay(program) : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _playReplay(EPGProgram program) async {
    final sub = ref.read(activeSubscriptionProvider);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (sub == null ||
        sub.type != SubscriptionType.xtream ||
        sub.baseUrl == null ||
        sub.username == null ||
        sub.password == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Replay indisponible : non pris en charge par cet abonnement (M3U).',),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Un seul constructeur d'URL de replay pour toute l'application.
    //
    // Cet écran construisait l'URL lui-même, au format
    // `/streaming/timeshift.php?...`, alors que le Replay passait par
    // `replayStreamUrl`, qui essaie d'abord le `catchup-source` du panel puis la
    // convention `/timeshift/...`. Deux formats pour la même chose, dont un seul
    // fonctionne sur ce panel : le rattrapage depuis l'EPG échouait là où le
    // Replay aboutissait.
    final url = ref.read(apiServiceProvider).replayStreamUrl(
          channel: widget.channel,
          baseUrl: sub.baseUrl!,
          username: sub.username!,
          password: sub.password!,
          startEpoch: program.start.millisecondsSinceEpoch ~/ 1000,
          endEpoch: program.end.millisecondsSinceEpoch ~/ 1000,
        );

    if (url.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(userFriendlyError(Exception('URL replay invalide'))),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    context.pushNamed(
      'player',
      extra: {
        'streamUrl': url,
        'title': '${program.title} (replay)',
        'contentType': 'replay',
        'channelId': widget.channel.id,
      },
    );
  }
}

/// Barre horizontale scrollable de boutons de date (JJ MMM)
class _DatePickerBar extends StatelessWidget {
  const _DatePickerBar({
    required this.availableDateKeys,
    required this.selectedDateKey,
    required this.onDateSelected,
  });

  final List<String> availableDateKeys;
  final String selectedDateKey;
  final ValueChanged<String> onDateSelected;

  @override
  Widget build(BuildContext context) {
    if (availableDateKeys.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: availableDateKeys.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final key = availableDateKeys[index];
            final parts = key.split('-');
            final day = int.tryParse(parts[2]) ?? 1;
            final month = int.tryParse(parts[1]) ?? 1;
            final isSelected = key == selectedDateKey;
            final label = '$day ${_monthShortFr(month)}';
            return TvFocus(
              autofocus: index == 0 && !isSelected,
              onActivate: () => onDateSelected(key),
              child: ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onDateSelected(key),
                selectedColor: const Color(0xFF6EE7B7),
                backgroundColor: const Color(0xFF1A1D26),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.white12,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          },
        ),
      ),
    );
  }

  String _monthShortFr(int m) {
    const months = [
      '',
      'JANV',
      'FÉVR',
      'MARS',
      'AVR',
      'MAI',
      'JUIN',
      'JUIL',
      'AOÛT',
      'SEPT',
      'OCT',
      'NOV',
      'DÉC',
    ];
    return months[m];
  }
}

/// Tuile programme : titre, horaire, description, badge replay + bouton
class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.program,
    required this.channel,
    required this.replayable,
    this.onReplayTap,
  });

  final EPGProgram program;
  final Channel channel;
  final bool replayable;
  final VoidCallback? onReplayTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final timeStr = '${_fmt(program.start)} - ${_fmt(program.end)}';
    final catColor = program.categoryColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + badge catégorie + badge replay
          Row(
            children: [
              Expanded(
                child: Text(
                  program.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (program.categoryDisplayName.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    program.categoryDisplayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,),
                  ),
                ),
              if (replayable) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EE7B7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REPLAY',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Horaire
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(timeStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),),
            ],
          ),
          // Description
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              program.description,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13, height: 1.4,),
            ),
          ],
          // Bouton Replay
          if (replayable && onReplayTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l.epgStartReplay),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6EE7B7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),),
                ),
                onPressed: onReplayTap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
