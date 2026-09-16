import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Barre de progression personnalisée avec affichage du temps actuel / total
class TimeProgressBar extends StatefulWidget {
  const TimeProgressBar({
    super.key,
    required this.controller,
    this.allowScrubbing = true,
    this.colors = const VideoProgressColors(
      playedColor: Colors.white,
      bufferedColor: Colors.white30,
      backgroundColor: Colors.white24,
    ),
    this.height = 4,
    this.textStyle,
  });

  final VideoPlayerController controller;
  final bool allowScrubbing;
  final VideoProgressColors colors;
  final double height;
  final TextStyle? textStyle;

  @override
  State<TimeProgressBar> createState() => _TimeProgressBarState();
}

class _TimeProgressBarState extends State<TimeProgressBar> {
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double dragValue = 0;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideoChange);
    position = widget.controller.value.position;
    duration = widget.controller.value.duration;
  }

  void _onVideoChange() {
    if (!mounted) return;
    final value = widget.controller.value;
    if (duration != value.duration) {
      setState(() => duration = value.duration);
    }
    if (!isDragging && position != value.position) {
      setState(() => position = value.position);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onVideoChange);
    super.dispose();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ?? const TextStyle(color: Colors.white70, fontSize: 11);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Temps actuel / total
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position), style: style),
              Text(formatDuration(duration), style: style),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Barre de progression
        GestureDetector(
          onHorizontalDragStart: widget.allowScrubbing
              ? (details) {
                  isDragging = true;
                }
              : null,
          onHorizontalDragUpdate: widget.allowScrubbing
              ? (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localPos = renderBox.globalToLocal(details.globalPosition);
                  final ratio = (localPos.dx / renderBox.size.width).clamp(0.0, 1.0);
                  setState(() {
                    dragValue = ratio;
                    position = Duration(milliseconds: (duration.inMilliseconds * ratio).round());
                  });
                }
              : null,
          onHorizontalDragEnd: widget.allowScrubbing
              ? (details) {
                  isDragging = false;
                  final targetMs = (duration.inMilliseconds * dragValue).round();
                  widget.controller.seekTo(Duration(milliseconds: targetMs));
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  // Fond
                  Container(
                    color: widget.colors.backgroundColor,
                  ),
                  // Buffer
                  if (widget.controller.value.buffered.isNotEmpty)
                    FractionallySizedBox(
                      widthFactor: widget.controller.value.buffered.first.end.inMilliseconds /
                          duration.inMilliseconds,
                      child: Container(color: widget.colors.bufferedColor),
                    ),
                  // Progression
                  FractionallySizedBox(
                    widthFactor: isDragging
                        ? dragValue
                        : (duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0),
                    child: Container(color: widget.colors.playedColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Barre de progression pour le programme EPG en cours (Live TV)
class LiveProgramProgressBar extends StatelessWidget {
  const LiveProgramProgressBar({super.key, required this.program});

  final EPGProgram program;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalMs = program.end.difference(program.start).inMilliseconds;
    var ratio = 0.0;
    if (totalMs > 0) {
      ratio = now.difference(program.start).inMilliseconds / totalMs;
    }
    ratio = ratio.clamp(0.0, 1.0);

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      if (hours > 0) return '${twoDigits(hours)}:${twoDigits(minutes)}';
      return '${twoDigits(minutes)} min';
    }

    final elapsed = now.difference(program.start);
    final remaining = program.end.difference(now);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Écoulé: ${formatDuration(elapsed)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'Restant: ${formatDuration(remaining)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
          ),
        ),
      ],
    );
  }
}