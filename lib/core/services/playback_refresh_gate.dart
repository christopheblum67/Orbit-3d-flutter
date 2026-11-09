import 'dart:async';

class PlaybackRefreshGate {
  static final instance = PlaybackRefreshGate();

  int _active = 0;
  Completer<void>? _idle;

  PlaybackRefreshLease acquire() {
    _active++;
    return PlaybackRefreshLease._(this);
  }

  Future<void> waitUntilIdle() async {
    while (_active > 0) {
      _idle ??= Completer<void>();
      await _idle!.future;
    }
  }

  void _release() {
    assert(_active > 0);
    _active--;
    if (_active == 0) {
      final idle = _idle;
      _idle = null;
      idle?.complete();
    }
  }
}

class PlaybackRefreshLease {
  PlaybackRefreshLease._(this._gate);

  PlaybackRefreshGate? _gate;

  void release() {
    final gate = _gate;
    if (gate == null) return;
    _gate = null;
    gate._release();
  }
}
