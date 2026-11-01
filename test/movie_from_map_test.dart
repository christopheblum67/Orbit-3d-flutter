import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

/// Régression : catalogue VOD vide (`Films VOD (0)`).
///
/// `get_vod_streams` ne renvoie jamais `cast`. `Movie.fromMap` trie ensuite le
/// casting avec `List.sort`, qui exige une liste MUTABLE. Le repli de
/// `Actor.listFromDynamic` était `const []` (non modifiable) : le `sort`
/// levait `UnsupportedError: Cannot modify an unmodifiable list` sur CHAQUE
/// entrée, et `_fetchMovies` les ignorait toutes (100 109 films → 0).
void main() {
  group('Movie.fromMap — entrée get_vod_streams', () {
    test('une entrée sans cast ne lève pas', () {
      final movie = Movie.fromMap({
        'num': 1,
        'name': 'Un film',
        'stream_type': 'movie',
        'stream_id': 12345,
        'stream_icon': 'http://panel/img/12345.jpg',
        'rating': '7.5',
        'added': '1700000000',
        'category_id': '12',
        'container_extension': 'mkv',
      });

      expect(movie.title, 'Un film');
      expect(movie.streamId, '12345');
      expect(movie.cast, isEmpty);
      expect(movie.crew, isEmpty);
    });

    test('un cast fourni par le panel est conservé et trié', () {
      final movie = Movie.fromMap({
        'stream_id': '1',
        'name': 'Un film',
        'cast': [
          {'name': 'Second', 'order': 2},
          {'name': 'Premier', 'order': 1},
        ],
      });

      expect(movie.cast.map((a) => a.name).toList(), ['Premier', 'Second']);
    });
  });

  group('Actor.listFromDynamic', () {
    test('le repli renvoyé est mutable (utilisable par List.sort)', () {
      final fallback = Actor.listFromDynamic(null);
      expect(fallback, isEmpty);
      expect(() => fallback.sort((a, b) => a.order.compareTo(b.order)),
          returnsNormally);
    });

    test('le repli explicite reste mutable', () {
      const empty = <Actor>[];
      final result = Actor.listFromDynamic(null, fallback: empty);
      expect(() => result.sort((a, b) => a.order.compareTo(b.order)),
          returnsNormally);
      // La constante passée par l'appelant ne doit pas être corrompue/partagée.
      expect(identical(result, empty), isFalse);
    });
  });
}
