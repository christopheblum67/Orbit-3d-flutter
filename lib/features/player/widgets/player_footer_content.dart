import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/features/player/widgets/cast_button.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_footer_bars.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:video_player/video_player.dart';

class PlayerFooterContent extends StatelessWidget {
  const PlayerFooterContent({
    super.key,
    required this.controller,
    required this.contentType,
    required this.streamUrl,
    required this.progressId,
    required this.channel,
    required this.title,
    required this.subtitle,
    required this.seriesName,
    required this.episodeLabel,
    required this.rating,
    required this.genre,
    required this.index,
    required this.total,
    required this.onExit,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlayPause,
    this.playPauseFocusNode,
    required this.onPip,
    required this.onSeekBack30,
    required this.onSeekForward30,
    required this.onToggleNightFocus,
    required this.onDetailsPressed,
    required this.onProgressInteraction,
  });

  final VideoPlayerController controller;
  final PlaybackContentType contentType;
  final String streamUrl;
  final String? progressId;
  final Channel? channel;
  final String? title;
  final String? subtitle;
  final String? seriesName;
  final String? episodeLabel;
  final double? rating;
  final String? genre;
  final int index;
  final int total;
  final VoidCallback onExit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onTogglePlayPause;
  final FocusNode? playPauseFocusNode;
  final VoidCallback? onPip;
  final VoidCallback onSeekBack30;
  final VoidCallback onSeekForward30;
  final VoidCallback onToggleNightFocus;
  final VoidCallback onDetailsPressed;
  final VoidCallback onProgressInteraction;

  @override
  Widget build(BuildContext context) {
    final isLive = contentType == PlaybackContentType.live;
    final castButton = CastButton(streamUrl: streamUrl, isLive: isLive);
    final streamDetails = FooterStreamDetails(
      onPressed: onDetailsPressed,
    );
    return switch (contentType) {
      PlaybackContentType.live => LiveFooterBar(
          channel: channel,
          fallbackTitle: title ?? channel?.name ?? 'Live',
          index: index,
          total: total,
          isPlaying: controller.value.isPlaying,
          showSeek: false,
          onExit: onExit,
          onPrevious: onPrevious,
          onNext: onNext,
          onTogglePlayPause: onTogglePlayPause,
          playPauseFocusNode: playPauseFocusNode,
          onPip: onPip,
          onSeekBack30: null,
          onSeekForward30: null,
          castButton: castButton,
          streamDetails: streamDetails,
          onToggleNightFocus: onToggleNightFocus,
        ),
      PlaybackContentType.replay => LiveFooterBar(
          channel: channel,
          fallbackTitle: title ?? 'Replay',
          subtitle: subtitle,
          controller: controller,
          index: index,
          total: total,
          isPlaying: controller.value.isPlaying,
          showSeek: true,
          onExit: onExit,
          onPrevious: onPrevious,
          onNext: onNext,
          onTogglePlayPause: onTogglePlayPause,
          playPauseFocusNode: playPauseFocusNode,
          onPip: onPip,
          onSeekBack30: onSeekBack30,
          onSeekForward30: onSeekForward30,
          castButton: castButton,
          streamDetails: streamDetails,
          onToggleNightFocus: onToggleNightFocus,
          onProgressInteraction: onProgressInteraction,
        ),
      PlaybackContentType.vod || PlaybackContentType.series => VodFooterBar(
          controller: controller,
          title: title ?? seriesName ?? 'Lecture',
          rating: rating,
          genre: genre,
          subtitle: subtitle,
          seriesName: seriesName,
          episodeLabel: episodeLabel,
          isPlaying: controller.value.isPlaying,
          onExit: onExit,
          onTogglePlayPause: onTogglePlayPause,
          playPauseFocusNode: playPauseFocusNode,
          onPip: onPip,
          onSeekBack30: onSeekBack30,
          onSeekForward30: onSeekForward30,
          castButton: castButton,
          streamDetails: streamDetails,
          onToggleNightFocus: onToggleNightFocus,
          onProgressInteraction: onProgressInteraction,
        ),
    };
  }
}
