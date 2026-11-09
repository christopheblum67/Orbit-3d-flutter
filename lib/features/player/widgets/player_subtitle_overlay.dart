import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/player/widgets/subtitle_overlay.dart';
import 'package:orbit_3d_flutter/providers/subtitle_providers.dart';
import 'package:video_player/video_player.dart';

class PlayerSubtitleOverlay extends ConsumerWidget {
  const PlayerSubtitleOverlay({
    super.key,
    required this.controller,
    this.bottomPadding = 100,
  });

  final VideoPlayerController controller;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitles = ref.watch(subtitleControllerProvider);
    if (subtitles.hasActiveEmbedded) {
      return EmbeddedSubtitleOverlay(
        cues: subtitles.liveEmbeddedCues,
        bottomPadding: bottomPadding,
      );
    }
    return VideoSubtitleOverlay(
      controller: controller,
      track: subtitles.activeTrack,
      bottomPadding: bottomPadding,
    );
  }
}
