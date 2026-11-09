import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart'
    show tvModeNotifierProvider;
import 'package:orbit_3d_flutter/features/player/widgets/delayed_playback_loading.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_monitoring_overlay.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_video_viewport.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class ReadyPlayer extends ConsumerStatefulWidget {
  const ReadyPlayer({
    super.key,
    required this.controller,
    required this.onTap,
    required this.streamUrl,
    required this.onRetry,
    required this.watchBuffering,
  });

  final VideoPlayerController controller;
  final VoidCallback onTap;
  final String streamUrl;
  final VoidCallback onRetry;
  final bool watchBuffering;

  @override
  ConsumerState<ReadyPlayer> createState() => _ReadyPlayerState();
}

class _ReadyPlayerState extends ConsumerState<ReadyPlayer> {
  bool _showBuffering = false;

  @override
  void initState() {
    super.initState();
    _showBuffering = widget.controller.value.isBuffering;
    widget.controller.addListener(_onPlayerStateChanged);
  }

  @override
  void didUpdateWidget(covariant ReadyPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPlayerStateChanged);
      widget.controller.addListener(_onPlayerStateChanged);
      _showBuffering = widget.controller.value.isBuffering;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final isBuffering = widget.controller.value.isBuffering;
    if (isBuffering != _showBuffering) {
      setState(() {
        _showBuffering = isBuffering;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isStalling =
        widget.watchBuffering && ref.watch(stallDetectorProvider).isStalling;
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlayerVideoViewport(
            aspectRatio: widget.controller.value.aspectRatio,
            cover: ref.watch(tvModeNotifierProvider).enabled,
            child: VideoPlayer(widget.controller),
          ),
          // Buffering indicator
          if (_showBuffering && !widget.watchBuffering)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          if ((_showBuffering || isStalling) && widget.watchBuffering)
            DelayedPlaybackLoading(
              key: ValueKey(widget.controller),
              onRetry: widget.onRetry,
              initialChild: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          // Monitoring overlay (réseau, stall, cooldown)
          PlayerMonitoringOverlay(
            streamUrl: widget.streamUrl,
            onRetry: widget.onRetry,
            showStall: !widget.watchBuffering,
          ),
        ],
      ),
    );
  }
}
