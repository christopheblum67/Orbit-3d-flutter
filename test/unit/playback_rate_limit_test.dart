import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/playback_rate_limit.dart';

void main() {
  test('uses the existing backoff sequence, caps it, and resets on success',
      () async {
    var now = DateTime(2026, 1, 1);
    final delays = <Duration>[];
    final limiter = PlaybackRateLimit(
      clock: () => now,
      sleep: (delay) async {
        delays.add(delay);
        now = now.add(delay);
      },
    );
    for (var i = 0; i < 5; i++) {
      limiter.startAttempt();
      expect(limiter.lastAttemptLimited, isFalse);
      limiter.register();
      expect(limiter.lastAttemptLimited, isTrue);
      await limiter.wait();
      await limiter.wait();
    }
    expect(delays.map((d) => d.inSeconds), [2, 5, 10, 20, 20]);
    limiter.resetAfterSuccess();
    await limiter.wait();
    limiter.startAttempt();
    limiter.register();
    await limiter.wait();
    expect(delays.last.inSeconds, 2);
    expect(delays.length, 6);
  });

  test('recognizes the same HTTP refusal errors as the player', () {
    expect(PlaybackRateLimit.isRateLimited(null), isFalse);
    expect(PlaybackRateLimit.isRateLimited('Response code: 401'), isTrue);
    expect(PlaybackRateLimit.isRateLimited('Response code: 403'), isTrue);
    expect(PlaybackRateLimit.isRateLimited('InvalidResponseCodeException'),
        isTrue);
    expect(PlaybackRateLimit.isRateLimited('Response code: 500'), isFalse);
  });
}
