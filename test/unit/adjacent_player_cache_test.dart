import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/adjacent_player_cache.dart';

void main() {
  test('taking a matching player transfers ownership without disposing it', () {
    final disposed = <String>[];
    final cache = AdjacentPlayerCache<String>(disposePlayer: disposed.add);
    cache.setPrevious(1, 'previous');
    cache.setNext(3, 'next');

    expect(cache.take(2), isNull);
    expect(cache.hasNext, isTrue);
    expect(cache.take(3), 'next');
    expect(cache.hasNext, isFalse);
    expect(cache.take(3), isNull);
    expect(cache.take(1), 'previous');
    cache.clear();
    expect(disposed, isEmpty);
  });

  test('replacement and clearing dispose each owned player exactly once', () {
    final disposed = <String>[];
    final cache = AdjacentPlayerCache<String>(disposePlayer: disposed.add);
    cache.setNext(2, 'old');
    cache.setNext(3, 'new');
    cache.setPrevious(1, 'previous');
    expect(disposed, ['old']);
    cache.clearPrevious();
    cache.clear();
    cache.clear();
    expect(disposed, ['old', 'previous', 'new']);
  });
}
