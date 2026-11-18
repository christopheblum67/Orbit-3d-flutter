import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

const _greenScreenChannel = MethodChannel('flutter.io/videoPlayer/tracks');

class GreenScreenDetector {
  static const double greenPixelRatioThreshold = 0.7;
  static const int requiredConsecutiveSamples = 3;

  int _consecutiveGreenSamples = 0;

  bool addSample(double? greenPixelRatio) {
    if (greenPixelRatio == null ||
        !greenPixelRatio.isFinite ||
        greenPixelRatio < greenPixelRatioThreshold) {
      _consecutiveGreenSamples = 0;
      return false;
    }

    _consecutiveGreenSamples++;
    return _consecutiveGreenSamples >= requiredConsecutiveSamples;
  }

  void reset() {
    _consecutiveGreenSamples = 0;
  }
}

Future<double?> sampleGreenFrame(VideoPlayerController controller) async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;

  // The Android backend's custom surface channel addresses players by ID.
  // ignore: invalid_use_of_visible_for_testing_member
  final playerId = controller.playerId;
  try {
    return (await _greenScreenChannel.invokeMethod<num>(
      'sampleGreenFrame',
      <String, Object?>{'playerId': playerId},
    ))
        ?.toDouble();
  } on MissingPluginException {
    debugPrint('Green-screen sampling is unavailable for this player.');
    return null;
  } on PlatformException catch (error) {
    debugPrint('Green-screen sampling failed: ${error.code}');
    return null;
  }
}
