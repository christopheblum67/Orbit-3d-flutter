import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';

/// Overlay qui affiche le sous-titre actif synchronisé avec la position vidéo.
class SubtitleOverlay extends StatelessWidget {
  final SubtitleTrack? track;
  final int positionMs;
  final TextStyle? style;
  final double bottomPadding;
  final double maxWidthFraction;
  final Duration fadeDuration;

  const SubtitleOverlay({
    super.key,
    required this.track,
    required this.positionMs,
    this.style,
    this.bottomPadding = 80,
    this.maxWidthFraction = 0.9,
    this.fadeDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final cue = track?.activeCueAt(positionMs);
    if (cue == null) return const SizedBox.shrink();

    final defaultStyle = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      shadows: const [
        Shadow(
          blurRadius: 6,
          color: Colors.black,
          offset: Offset(0, 2),
        ),
      ],
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: fadeDuration,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * maxWidthFraction,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cue.text,
                textAlign: TextAlign.center,
                style: style ?? defaultStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Version avec animation de transition entre cues (slide + fade).
class AnimatedSubtitleOverlay extends StatefulWidget {
  final SubtitleTrack? track;
  final int positionMs;
  final TextStyle? style;
  final double bottomPadding;
  final double maxWidthFraction;
  final Duration fadeDuration;
  final Duration slideDuration;

  const AnimatedSubtitleOverlay({
    super.key,
    required this.track,
    required this.positionMs,
    this.style,
    this.bottomPadding = 80,
    this.maxWidthFraction = 0.9,
    this.fadeDuration = const Duration(milliseconds: 200),
    this.slideDuration = const Duration(milliseconds: 250),
  });

  @override
  State<AnimatedSubtitleOverlay> createState() => _AnimatedSubtitleOverlayState();
}

class _AnimatedSubtitleOverlayState extends State<AnimatedSubtitleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  SubtitleCue? _lastCue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.slideDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _lastCue = widget.track?.activeCueAt(widget.positionMs);
    if (_lastCue != null) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedSubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCue = widget.track?.activeCueAt(widget.positionMs);
    if (newCue != _lastCue) {
      _lastCue = newCue;
      if (newCue != null) {
        _controller.reset();
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cue = widget.track?.activeCueAt(widget.positionMs);
    if (cue == null) return const SizedBox.shrink();

    final defaultStyle = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      shadows: const [
        Shadow(
          blurRadius: 6,
          color: Colors.black,
          offset: Offset(0, 2),
        ),
      ],
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * widget.maxWidthFraction,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cue.text,
                  textAlign: TextAlign.center,
                  style: widget.style ?? defaultStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}