import 'package:flutter/foundation.dart';

/// Per-screen delay; the native player still enforces the global network gate.
class PlaybackRateLimit {
  PlaybackRateLimit({
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  })  : _clock = clock ?? DateTime.now,
        _sleep = sleep ?? Future<void>.delayed;

  static const _backoffs = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
  ];

  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;
  int _strikes = 0;
  DateTime? _until;
  bool _lastAttemptLimited = false;

  bool get lastAttemptLimited => _lastAttemptLimited;

  static bool isRateLimited(Object? error) {
    if (error == null) return false;
    final text = error.toString();
    return text.contains('Response code: 401') ||
        text.contains('Response code: 403') ||
        text.contains('InvalidResponseCodeException');
  }

  void startAttempt() => _lastAttemptLimited = false;

  void register() {
    final index = _strikes.clamp(0, _backoffs.length - 1);
    final backoff = _backoffs[index];
    _strikes++;
    _until = _clock().add(backoff);
    _lastAttemptLimited = true;
    debugPrint(
      'Orbit3D 401 throttle: strike=$_strikes pause=${backoff.inSeconds}s',
    );
  }

  Future<void> wait() async {
    final until = _until;
    if (until == null) return;
    final delay = until.difference(_clock());
    if (delay.isNegative || delay.inMilliseconds <= 0) return;
    debugPrint('Orbit3D throttle: attente ${delay.inMilliseconds}ms');
    await _sleep(delay);
  }

  void resetAfterSuccess() {
    _strikes = 0;
    _until = null;
  }
}
