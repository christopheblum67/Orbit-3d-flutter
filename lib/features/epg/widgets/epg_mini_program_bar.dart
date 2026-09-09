import 'package:flutter/material.dart';
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
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.now,
      builder: (context, now, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: controller.targetedChannel,
          builder: (context, channelName, _) {
            final programs =
                channelName == null ? const <EPGProgram>[] : (epgData[channelName] ?? const <EPGProgram>[]);
            final current = _currentProgram(programs, now);
            final next = _nextProgram(programs, now);
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
                        ? const Text(
                            'Sélectionnez une chaîne pour voir son programme',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
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
                                          : 'Aucun programme en cours',
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

EPGProgram? _currentProgram(List<EPGProgram> programs, DateTime now) {
  for (final p in programs) {
    if (!p.start.isAfter(now) && p.end.isAfter(now)) return p;
  }
  return null;
}

EPGProgram? _nextProgram(List<EPGProgram> programs, DateTime now) {
  EPGProgram? next;
  for (final p in programs) {
    if (p.start.isAfter(now)) {
      if (next == null || p.start.isBefore(next.start)) next = p;
    }
  }
  return next;
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
