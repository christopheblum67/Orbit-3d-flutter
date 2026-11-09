import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/player_key_policy.dart';

void main() {
  PlayerKeyDecision decide(
    LogicalKeyboardKey key, {
    bool repeat = false,
    bool live = false,
    bool visible = false,
    bool footerFocus = false,
    bool nextFocus = false,
    bool playing = false,
  }) =>
      resolvePlayerKey(
        key: key,
        repeat: repeat,
        isLive: live,
        footerVisible: visible,
        footerHasFocus: footerFocus,
        nextEpisodeHasFocus: nextFocus,
        isPlaying: playing,
      );

  test('next episode activation takes precedence and allows repeats', () {
    for (final key in [
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.gameButtonA,
    ]) {
      final result = decide(key, nextFocus: true, repeat: true, visible: true);
      expect(result.action, PlayerKeyAction.nextEpisode);
      expect(result.refreshFooter, isFalse);
    }
    expect(
      decide(LogicalKeyboardKey.numpadEnter, nextFocus: true).action,
      PlayerKeyAction.showFooter,
    );
  });

  test('live channel keys and unfocused vertical arrows support repeats', () {
    for (final key in [
      LogicalKeyboardKey.channelUp,
      LogicalKeyboardKey.arrowUp,
    ]) {
      expect(
        decide(key, live: true, repeat: true).action,
        PlayerKeyAction.previousUnfocused,
      );
    }
    for (final key in [
      LogicalKeyboardKey.channelDown,
      LogicalKeyboardKey.arrowDown,
    ]) {
      expect(
        decide(key, live: true, repeat: true).action,
        PlayerKeyAction.nextUnfocused,
      );
    }
    expect(
      decide(LogicalKeyboardKey.channelUp, live: true, footerFocus: true)
          .action,
      PlayerKeyAction.previousUnfocused,
    );
    final focused = decide(
      LogicalKeyboardKey.arrowUp,
      live: true,
      footerFocus: true,
      visible: true,
    );
    expect(focused.action, PlayerKeyAction.ignored);
    expect(focused.refreshFooter, isTrue);
    final repeated = decide(
      LogicalKeyboardKey.arrowUp,
      live: true,
      footerFocus: true,
      visible: true,
      repeat: true,
    );
    expect(repeated.action, PlayerKeyAction.ignored);
    expect(repeated.refreshFooter, isFalse);
  });

  test('footer allows focused controls and refreshes on ordinary keydown', () {
    for (final key in [
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyA,
    ]) {
      final result = decide(key, visible: true);
      expect(result.action, PlayerKeyAction.ignored);
      expect(result.refreshFooter, isTrue);
      expect(decide(key, visible: true, repeat: true).refreshFooter, isFalse);
    }
    for (final key in [
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ]) {
      expect(decide(key).action, PlayerKeyAction.showFooter);
    }
  });

  test('navigation, details and media shortcuts map to their actions', () {
    final keys = {
      LogicalKeyboardKey.arrowUp: PlayerKeyAction.previous,
      LogicalKeyboardKey.pageUp: PlayerKeyAction.previous,
      LogicalKeyboardKey.mediaTrackPrevious: PlayerKeyAction.previous,
      LogicalKeyboardKey.arrowDown: PlayerKeyAction.next,
      LogicalKeyboardKey.pageDown: PlayerKeyAction.next,
      LogicalKeyboardKey.mediaTrackNext: PlayerKeyAction.next,
      LogicalKeyboardKey.space: PlayerKeyAction.togglePlayback,
      LogicalKeyboardKey.mediaPlayPause: PlayerKeyAction.togglePlayback,
      LogicalKeyboardKey.contextMenu: PlayerKeyAction.showDetails,
      LogicalKeyboardKey.info: PlayerKeyAction.showDetails,
      LogicalKeyboardKey.settings: PlayerKeyAction.showDetails,
      LogicalKeyboardKey.mediaFastForward: PlayerKeyAction.seekForward,
      LogicalKeyboardKey.mediaRewind: PlayerKeyAction.seekBackward,
      LogicalKeyboardKey.escape: PlayerKeyAction.toggleFooter,
    };
    for (final entry in keys.entries) {
      expect(decide(entry.key).action, entry.value, reason: '${entry.key}');
      expect(decide(entry.key, repeat: true).action, PlayerKeyAction.ignored);
    }
    expect(
      decide(LogicalKeyboardKey.mediaFastForward, live: true).action,
      PlayerKeyAction.ignored,
    );
    expect(
      decide(LogicalKeyboardKey.mediaRewind, live: true).action,
      PlayerKeyAction.ignored,
    );
  });

  test('play and pause are idempotent and always consume the key', () {
    expect(
      decide(LogicalKeyboardKey.mediaPlay).action,
      PlayerKeyAction.togglePlayback,
    );
    expect(
      decide(LogicalKeyboardKey.mediaPlay, playing: true).action,
      PlayerKeyAction.handled,
    );
    expect(
      decide(LogicalKeyboardKey.mediaPause).action,
      PlayerKeyAction.handled,
    );
    expect(
      decide(LogicalKeyboardKey.mediaPause, playing: true).action,
      PlayerKeyAction.togglePlayback,
    );
  });
}
