import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/playback_checkpoint.dart';
import 'package:video_player/video_player.dart';

void main() {
  test(
      'preserves position on error and while restoring, but accepts seek to zero',
      () {
    final checkpoint = PlaybackCheckpoint(12000);
    const duration = Duration(minutes: 10);
    checkpoint.observe(
        const VideoPlayerValue(duration: duration, position: Duration.zero));
    expect(checkpoint.position, const Duration(seconds: 12));
    checkpoint.restoring = false;
    checkpoint.observe(const VideoPlayerValue(
        duration: duration,
        position: Duration(seconds: 90),
        isInitialized: true));
    checkpoint.observe(VideoPlayerValue.erroneous('decoder error'));
    expect(checkpoint.position, const Duration(seconds: 90));
    checkpoint.restoring = true;
    checkpoint.observe(
        const VideoPlayerValue(duration: duration, isInitialized: true));
    expect(checkpoint.position, const Duration(seconds: 90));
    checkpoint.restoring = false;
    checkpoint.observe(
        const VideoPlayerValue(duration: duration, isInitialized: true));
    expect(checkpoint.position, Duration.zero);
    expect(checkpoint.hasPosition, isTrue);
    checkpoint.reset();
    expect(checkpoint.hasPosition, isFalse);
  });
}
