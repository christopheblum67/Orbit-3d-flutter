class AdjacentPlayerCache<T extends Object> {
  AdjacentPlayerCache({required this.disposePlayer});

  final void Function(T player) disposePlayer;
  (int, T)? _next;
  (int, T)? _previous;

  bool get hasNext => _next != null;

  T? take(int index) {
    if (_next?.$1 == index) {
      final player = _next!.$2;
      _next = null;
      return player;
    }
    if (_previous?.$1 == index) {
      final player = _previous!.$2;
      _previous = null;
      return player;
    }
    return null;
  }

  void setNext(int index, T player) {
    clearNext();
    _next = (index, player);
  }

  void setPrevious(int index, T player) {
    clearPrevious();
    _previous = (index, player);
  }

  void clearNext() {
    final player = _next?.$2;
    _next = null;
    if (player != null) disposePlayer(player);
  }

  void clearPrevious() {
    final player = _previous?.$2;
    _previous = null;
    if (player != null) disposePlayer(player);
  }

  void clear() {
    clearNext();
    clearPrevious();
  }
}
