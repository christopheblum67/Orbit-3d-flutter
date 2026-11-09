import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';

void main() {
  test('le live utilise les seuils IPTV tout en gardant le plafond vidéo', () {
    for (final device in DeviceProfile.values) {
      final vod = Media3PlaybackProfile.forProfile(device);
      final live = Media3PlaybackProfile.forProfile(device, live: true);
      expect(live.minBufferMs, 15000);
      expect(live.maxBufferMs, 50000);
      expect(live.bufferForPlaybackMs, 2500);
      expect(live.bufferForPlaybackAfterRebufferMs, 5000);
      expect(live.maxVideoHeight, vod.maxVideoHeight);
      expect(live.prioritizeTimeOverSizeThresholds, isTrue);
      expect(vod.prioritizeTimeOverSizeThresholds, isFalse);
      expect(live.toMethodArguments()['prioritizeTimeOverSizeThresholds'], isTrue);
    }
    expect(
      Media3PlaybackProfile.unset.toMethodArguments()['prioritizeTimeOverSizeThresholds'],
      isFalse,
    );
  });
}
