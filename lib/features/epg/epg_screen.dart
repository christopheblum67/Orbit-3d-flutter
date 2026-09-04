import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/core/widgets/error_state.dart';
import 'package:orbit_3d_flutter/core/widgets/loading_state.dart';

class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> {
  @override
  Widget build(BuildContext context) {
    final epgMode = ref.watch(advancedSettingsProvider).epgDisplayMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Guide TV (EPG)')),
      body: switch (epgMode) {
        EpgDisplayMode.grid2D => const _EpgGrid2D(),
        EpgDisplayMode.grid3D => const _EpgGrid3DPlaceholder(),
      },
    );
  }
}

class _EpgGrid2D extends ConsumerWidget {
  const _EpgGrid2D();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(child: Text('Aucune chaîne disponible'));
        }
        return ListView.separated(
          itemCount: channels.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _ChannelRow(channel: channels[index]),
        );
      },
      loading: () =>
          const LoadingState(message: 'Chargement des chaînes…'),
      error: (err, _) => ErrorState(
        icon: Icons.tv_off_rounded,
        title: 'Chaînes indisponibles',
        message: 'Impossible de charger les chaînes.',
        onRetry: () => ref.invalidate(liveChannelsProvider),
      ),
    );
  }
}

class _ChannelRow extends ConsumerWidget {
  const _ChannelRow({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final programsAsync =
        ref.watch(channelEpgProvider(channel.epgChannelId));

    return Container(
      height: 60,
      color: scheme.surface,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            width: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: programsAsync.when(
              data: (programs) {
                if (programs.isEmpty) {
                  return Center(
                    child: Text(
                      '—',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final now = DateTime.now();
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: programs.length,
                  itemBuilder: (context, i) {
                    final p = programs[i];
                    final isCurrent =
                        p.start.isBefore(now) && p.end.isAfter(now);
                    final durationMin =
                        p.end.difference(p.start).inMinutes;
                    final blockWidth =
                        (durationMin * 3.0).clamp(80.0, 400.0);
                    return Container(
                      width: blockWidth,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 6,
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatTime(p.start)} - ${_formatTime(p.end)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpgGrid3DPlaceholder extends StatelessWidget {
  const _EpgGrid3DPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_in_ar_rounded,
            size: 80,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'EPG 3D bientôt disponible',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le guide TV en vue immersive arrive prochainement.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

class OrbitPainter extends CustomPainter {
  final int selectedIndex;
  final List<EPGProgram> programs;
  final Color ringColor;
  final Color accentColor;
  final Color textColor;
  final Color activeTextColor;

  OrbitPainter({
    required this.selectedIndex,
    required this.programs,
    required this.ringColor,
    required this.accentColor,
    required this.textColor,
    required this.activeTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (programs.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..color = ringColor;
    final activeRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = accentColor;

    canvas.drawCircle(center, radius, ringPaint);
    // Arc actif
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (2 * math.pi / programs.length) * selectedIndex,
      2 * math.pi / programs.length,
      false,
      activeRingPaint,
    );

    for (int i = 0; i < programs.length; i++) {
      final angle = (2 * math.pi / programs.length) * i - math.pi / 2;
      final labelPos = Offset(
        center.dx + math.cos(angle) * (radius + 20),
        center.dy + math.sin(angle) * (radius + 20),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: programs[i].title.length > 15
              ? programs[i].title.substring(0, 15)
              : programs[i].title,
          style: TextStyle(
            color: i == selectedIndex ? activeTextColor : textColor,
            fontSize: 12,
            fontWeight:
                i == selectedIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.programs != programs ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.activeTextColor != activeTextColor;
  }
}
