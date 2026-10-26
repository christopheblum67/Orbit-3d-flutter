/// Spaces panel requests and caps concurrency to reduce global 429s.
///
/// Spacing grows after rate limits and gradually recovers after successes.
///
/// Admission remains synchronous between state inspection and update, so two
/// callers cannot acquire the same slot while waiting.
class ApiRequestGate {
  ApiRequestGate({
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  })  : _clock = clock ?? DateTime.now,
        _sleep = sleep ?? ((duration) => Future<void>.delayed(duration));

  static const Duration _minGap = Duration(milliseconds: 120);
  static const Duration _maxGap = Duration(seconds: 2);
  static const int _maxConcurrent = 3;
  static const Duration _poll = Duration(milliseconds: 25);

  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;
  DateTime _nextAllowedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _gap = _minGap;
  int _inFlight = 0;
  int _consecutive429 = 0;

  Future<void> acquire() async {
    while (true) {
      var wait = Duration.zero;
      var admitted = false;
      final now = _clock();
      if (_inFlight >= _maxConcurrent) {
        wait = _poll;
      } else if (now.isBefore(_nextAllowedAt)) {
        wait = _nextAllowedAt.difference(now);
      } else {
        _inFlight++;
        _nextAllowedAt = now.add(_gap);
        admitted = true;
      }
      if (admitted) return;
      await _sleep(wait);
    }
  }

  void onRateLimited() {
    _consecutive429++;
    final scaled = _minGap.inMilliseconds * (_consecutive429 + 1);
    _gap = Duration(
      milliseconds:
          scaled > _maxGap.inMilliseconds ? _maxGap.inMilliseconds : scaled,
    );
    _nextAllowedAt = _clock().add(_gap);
  }

  void onSuccess() {
    if (_consecutive429 > 0) _consecutive429--;
    final halved = _gap.inMilliseconds ~/ 2;
    final floor = _minGap.inMilliseconds;
    _gap = Duration(milliseconds: halved < floor ? floor : halved);
  }

  void release() {
    if (_inFlight > 0) _inFlight--;
  }

  int get consecutiveRateLimits => _consecutive429;
}
