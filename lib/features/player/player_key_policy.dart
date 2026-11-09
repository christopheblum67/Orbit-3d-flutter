import 'package:flutter/services.dart';

enum PlayerKeyAction {
  ignored,
  handled,
  nextEpisode,
  previousUnfocused,
  nextUnfocused,
  showFooter,
  previous,
  next,
  togglePlayback,
  showDetails,
  seekForward,
  seekBackward,
  toggleFooter,
}

class PlayerKeyDecision {
  const PlayerKeyDecision(this.action, {this.refreshFooter = false});

  final PlayerKeyAction action;
  final bool refreshFooter;
}

/// Résout les touches sans déplacer le focus ni agir sur le lecteur.
PlayerKeyDecision resolvePlayerKey({
  required LogicalKeyboardKey key,
  required bool repeat,
  required bool isLive,
  required bool footerVisible,
  required bool footerHasFocus,
  required bool nextEpisodeHasFocus,
  required bool isPlaying,
}) {
  if (nextEpisodeHasFocus &&
      (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.gameButtonA)) {
    return const PlayerKeyDecision(PlayerKeyAction.nextEpisode);
  }
  if (isLive &&
      (key == LogicalKeyboardKey.channelUp ||
          key == LogicalKeyboardKey.channelDown ||
          (!footerHasFocus &&
              (key == LogicalKeyboardKey.arrowUp ||
                  key == LogicalKeyboardKey.arrowDown)))) {
    return PlayerKeyDecision(
      key == LogicalKeyboardKey.channelUp || key == LogicalKeyboardKey.arrowUp
          ? PlayerKeyAction.previousUnfocused
          : PlayerKeyAction.nextUnfocused,
    );
  }
  if (repeat) return const PlayerKeyDecision(PlayerKeyAction.ignored);

  PlayerKeyDecision decision(PlayerKeyAction action) =>
      PlayerKeyDecision(action, refreshFooter: footerVisible);

  if (key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter) {
    return decision(
      footerVisible ? PlayerKeyAction.ignored : PlayerKeyAction.showFooter,
    );
  }
  final arrow = key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown;
  if (footerVisible && arrow) return decision(PlayerKeyAction.ignored);
  if (key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight) {
    return decision(PlayerKeyAction.showFooter);
  }
  if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.pageUp) {
    return decision(PlayerKeyAction.previous);
  }
  if (key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.pageDown) {
    return decision(PlayerKeyAction.next);
  }
  if (key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.mediaPlayPause) {
    return decision(PlayerKeyAction.togglePlayback);
  }
  if (key == LogicalKeyboardKey.mediaPlay ||
      key == LogicalKeyboardKey.mediaPause) {
    return decision(
      (key == LogicalKeyboardKey.mediaPlay) != isPlaying
          ? PlayerKeyAction.togglePlayback
          : PlayerKeyAction.handled,
    );
  }
  if (key == LogicalKeyboardKey.contextMenu ||
      key == LogicalKeyboardKey.info ||
      key == LogicalKeyboardKey.settings) {
    return decision(PlayerKeyAction.showDetails);
  }
  if (!isLive && key == LogicalKeyboardKey.mediaFastForward) {
    return decision(PlayerKeyAction.seekForward);
  }
  if (!isLive && key == LogicalKeyboardKey.mediaRewind) {
    return decision(PlayerKeyAction.seekBackward);
  }
  if (key == LogicalKeyboardKey.mediaTrackNext) {
    return decision(PlayerKeyAction.next);
  }
  if (key == LogicalKeyboardKey.mediaTrackPrevious) {
    return decision(PlayerKeyAction.previous);
  }
  if (key == LogicalKeyboardKey.escape) {
    return decision(PlayerKeyAction.toggleFooter);
  }
  return decision(PlayerKeyAction.ignored);
}
