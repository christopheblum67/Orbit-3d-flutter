import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

void main() {
  group('Movie.fromMap', () {
    test('parses a movie from a real Xtream API list item (name key)', () {
      final movie = Movie.fromMap({
        'num': 1,
        'name': 'Infinite',
        'stream_id': 42,
        'stream_icon': 'https://cdn.example.com/poster.jpg',
        'rating': 7.2,
        'container_extension': 'mp4',
      });

      expect(movie.id, '42');
      expect(movie.title, 'Infinite');
      expect(movie.posterUrl, 'https://cdn.example.com/poster.jpg');
      expect(movie.rating, 7.2);
    });

    test('falls back to title key when the list-style name is absent', () {
      final movie = Movie.fromMap({
        'id': 99,
        'title': 'Une action',
        'year': 2020,
      });

      expect(movie.id, '99');
      expect(movie.title, 'Une action');
      expect(movie.year, 2020);
    });
  });
}