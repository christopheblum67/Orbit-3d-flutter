import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/green_screen_detection.dart';

void main() {
  test('requires repeated green samples and resets after a non-green frame',
      () {
    final detector = GreenScreenDetector();

    expect(detector.addSample(0.9), isFalse);
    expect(detector.addSample(0.1), isFalse);
    expect(detector.addSample(0.9), isFalse);
    expect(detector.addSample(0.9), isFalse);
    expect(detector.addSample(0.9), isTrue);
  });

  test('ignores missing and invalid samples', () {
    final detector = GreenScreenDetector();

    expect(detector.addSample(0.9), isFalse);
    expect(detector.addSample(null), isFalse);
    expect(detector.addSample(double.nan), isFalse);
    expect(detector.addSample(0.9), isFalse);
  });
}
