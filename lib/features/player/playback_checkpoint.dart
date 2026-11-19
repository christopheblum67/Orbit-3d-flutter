import 'package:video_player/video_player.dart';

/// Holds the last valid position even if a player error clears its value.
class PlaybackCheckpoint {
  PlaybackCheckpoint(int? initialMs)
      : position = Duration(
            milliseconds: initialMs != null && initialMs > 0 ? initialMs : 0);

  Duration position;
  Duration duration = Duration.zero;
  bool restoring = true;
  bool get hasPosition => _observed || position > Duration.zero;
  bool _observed = false;

  void observe(VideoPlayerValue value) {
    if (restoring || !value.isInitialized || value.hasError) return;
    if (value.position < Duration.zero ||
        (value.duration > Duration.zero && value.position > value.duration)) {
      return;
    }
    position = value.position;
    _observed = true;
    if (value.duration > Duration.zero) duration = value.duration;
  }

  void observeExternal(Duration newPosition, Duration newDuration) {
    position = newPosition;
    duration = newDuration;
    restoring = false;
    _observed = true;
  }

  void reset() {
    position = Duration.zero;
    duration = Duration.zero;
    restoring = true;
    _observed = false;
  }
}
