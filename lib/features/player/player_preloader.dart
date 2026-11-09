/// Owns an in-flight preload until it is transferred to the adjacent cache.
class PlayerPreloader<T extends Object> {
  int? get pendingIndex => _pending?.index;
  _PreloadOperation? _pending;

  void cancel() {
    _pending = null;
  }

  Future<void> start({
    required int index,
    required Iterable<int> attempts,
    required bool Function() isCurrent,
    required T Function(int attempt) create,
    required Future<bool> Function(T player) initialize,
    required bool Function(T player) isUsable,
    required void Function(T player) pause,
    required bool Function() canAccept,
    required void Function(int index, T player) accept,
    required void Function(T player) dispose,
  }) async {
    if (_pending?.index == index) return;
    final operation = _PreloadOperation(index);
    _pending = operation;
    bool active() => identical(_pending, operation) && isCurrent();

    try {
      for (final attempt in attempts) {
        if (!active()) return;
        final player = create(attempt);
        var transferred = false;
        try {
          final initialized = await initialize(player);
          if (!active()) return;
          if (!initialized || !isUsable(player)) continue;
          if (!canAccept()) return;
          pause(player);
          accept(index, player);
          transferred = true;
          return;
        } finally {
          if (!transferred) dispose(player);
        }
      }
    } finally {
      if (identical(_pending, operation)) _pending = null;
    }
  }
}

class _PreloadOperation {
  _PreloadOperation(this.index);
  final int index;
}
