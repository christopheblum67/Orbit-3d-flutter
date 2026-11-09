import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/playback_error_policy.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';

void main() {
  test('decoder errors are recognized without widening matching rules', () {
    for (final error in [
      'MediaCodecVideoRenderer failure',
      'DecoderInitializationException',
      Exception('Decoder init failed'),
    ]) {
      expect(isPlaybackDecoderError(error), isTrue);
    }
    for (final error in [null, '', 'network error', 'decoder init failed']) {
      expect(isPlaybackDecoderError(error), isFalse);
    }
  });

  test('provider block retains public compatibility and exact matching', () {
    for (final description in ['HTTP 401', 'Source error']) {
      expect(isPlaybackProviderBlock(description), isTrue);
      expect(PlayerScreenState.isProviderBlock(description), isTrue);
    }
    for (final description in [null, '', 'HTTP 403', 'source error']) {
      expect(isPlaybackProviderBlock(description), isFalse);
      expect(PlayerScreenState.isProviderBlock(description), isFalse);
    }
  });

  test('challenge markers are case insensitive', () {
    for (final description in [
      'HTTP 403',
      'CloudFlare',
      'CHALLENGE',
      'CF_CLEARANCE',
      'BLOCKED',
      'Access Denied',
      'FORBIDDEN',
    ]) {
      expect(isPlaybackCloudflareError(description), isTrue);
    }
    for (final description in [null, '', 'HTTP 401', 'Source error']) {
      expect(isPlaybackCloudflareError(description), isFalse);
    }
  });

  test('challenge stops retries even when error also reports decoder failure',
      () {
    for (var attempts = 0; attempts <= 3; attempts++) {
      expect(
        playbackRecoveryAction(
          description: '403 MediaCodecVideoRenderer orbitDecoder=hardware',
          attempts: attempts,
        ),
        PlaybackRecoveryAction.showError,
      );
    }
  });

  test('two retries are permitted before fallback for decoder errors', () {
    for (final description in [
      null,
      'Source error',
      'MediaCodecVideoRenderer orbitDecoder=software',
    ]) {
      for (final attempts in [0, 1]) {
        expect(
          playbackRecoveryAction(description: description, attempts: attempts),
          PlaybackRecoveryAction.retry,
        );
      }
    }
    for (final attempts in [2, 3]) {
      expect(
        playbackRecoveryAction(
          description: 'Decoder init failed',
          attempts: attempts,
        ),
        PlaybackRecoveryAction.externalIfConfigured,
      );
      expect(
        playbackRecoveryAction(description: 'Source error', attempts: attempts),
        PlaybackRecoveryAction.showError,
      );
    }
  });
}
