# EPG — grille : 5. timeline, gestes et en-têtes

> **Partie 3/4**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_timeline.dart`, `lib/features/epg/widgets/epg_timeline_controller.dart`, `lib/features/epg/widgets/epg_scroll_gesture.dart`, `lib/features/epg/widgets/epg_headbar.dart`, `lib/features/epg/widgets/epg_mini_program_bar.dart`, `lib/features/epg/widgets/epg_preview_header.dart`

### 5.4 `epg_headbar` — barre de titre/filtres — suite 2/2

`lib/features/epg/widgets/epg_headbar.dart` · lignes 401–536

#### `lib/features/epg/widgets/epg_headbar.dart` · lignes 401–536 · partie 1/1

```dart
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Boutons d'action rapides (Favori, Enregistrement, Rappel, Info)
class _ActionButtonsWidget extends StatelessWidget {
  final bool isFavorite;
  final bool isRecording;
  final bool hasReminder;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onRecordToggle;
  final VoidCallback? onReminderToggle;
  final VoidCallback? onInfo;

  const _ActionButtonsWidget({
    required this.isFavorite,
    required this.isRecording,
    required this.hasReminder,
    this.onFavoriteToggle,
    this.onRecordToggle,
    this.onReminderToggle,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          activeColor: Colors.redAccent,
          label: l.epgActionFavorite,
          isActive: isFavorite,
          onTap: onFavoriteToggle,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.fiber_manual_record,
          activeColor: Colors.redAccent,
          label: l.epgActionRecording,
          isActive: isRecording,
          onTap: onRecordToggle,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: hasReminder
              ? Icons.notifications_active
              : Icons.notifications_none,
          activeColor: scheme.tertiary,
          label: l.epgActionReminder,
          isActive: hasReminder,
          onTap: onReminderToggle,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.info_outline,
          activeColor: scheme.primary,
          label: 'Info',
          isActive: false,
          onTap: onInfo,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.activeColor,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.5 `epg_mini_program_bar` — aperçu programme survolé

`lib/features/epg/widgets/epg_mini_program_bar.dart` · lignes 1–139

#### `lib/features/epg/widgets/epg_mini_program_bar.dart` · lignes 1–139 · partie 1/1

```dart
import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';

/// Mini-lecteur programme sous la frise : affiche le programme en cours de la
/// chaîne ciblée + barre de progression (now dans start→stop).
///
/// Mise à jour chaque minute : le [ValueNotifier] `now` écouté provient du
/// controller partagé (un seul timer déjà actif dans la grille).
class EpgMiniProgramBar extends StatelessWidget {
  final EpgTimelineController controller;
  final Map<String, List<EPGProgram>> epgData;
  final double height;

  const EpgMiniProgramBar({
    super.key,
    required this.controller,
    required this.epgData,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.now,
      builder: (context, now, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: controller.targetedChannel,
          builder: (context, channelName, _) {
            final programs = channelName == null
                ? const <EPGProgram>[]
                : (epgData[channelName] ?? const <EPGProgram>[]);
            final current = epgCurrentProgram(programs, now);
            final next = epgNextProgram(programs, now);
            return Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF13151B),
                border: Border(
                  bottom: BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chrome_reader_mode,
                    color: Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: channelName == null
                        ? Text(
                            l.epgSelectChannelHint,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12,),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8B5CF6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      current != null
                                          ? '${current.title}  '
                                              '${_fmt(current.start)} - ${_fmt(current.end)}'
                                          : l.epgNoCurrentProgram,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (next != null)
                                    Text(
                                      '· ${next.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: current == null
                                    ? null
                                    : _progress(current, now),
                                minHeight: 3,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

double _progress(EPGProgram program, DateTime now) {
  final start = program.start;
  final end = program.end;
  final duration = end.difference(start).inSeconds;
  if (duration <= 0) return 0;
  final elapsed = now.difference(start).inSeconds;
  return (elapsed / duration).clamp(0.0, 1.0);
}

String _fmt(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';
```
