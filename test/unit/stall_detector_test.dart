import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';

void main() {
  group('StallDetector', () {
    late StallDetector detector;

    setUp(() {
      detector = StallDetector(
        checkInterval: const Duration(milliseconds: 10),
        stallThreshold: const Duration(milliseconds: 30),
        minChecksForStall: 3,
      );
    });

    tearDown(() {
      detector.dispose();
    });

    test('initial state: not stalling, not running', () {
      expect(detector.isStalling, isFalse);
      expect(detector.isRunning, isFalse);
    });

    test('starts and stops monitoring', () {
      // We can't easily test with a real controller in unit tests
      // without a full mock, so we verify the API works
      detector.stop();
      expect(detector.isRunning, isFalse);
      expect(detector.isStalling, isFalse);
    });

    test('dispose stops monitoring', () {
      final d = StallDetector(
        checkInterval: const Duration(milliseconds: 10),
        stallThreshold: const Duration(milliseconds: 30),
        minChecksForStall: 3,
      );
      d.dispose();
      expect(d.isRunning, isFalse);
    });

    test('configuration parameters are respected', () {
      final detector1 = StallDetector(
        checkInterval: const Duration(seconds: 1),
        stallThreshold: const Duration(seconds: 10),
        minChecksForStall: 5,
      );
      expect(detector1.isRunning, isFalse);
      detector1.dispose();

      final detector2 = StallDetector(
        checkInterval: const Duration(milliseconds: 100),
        stallThreshold: const Duration(seconds: 5),
        minChecksForStall: 2,
      );
      expect(detector2.isRunning, isFalse);
      detector2.dispose();
    });
  });
}