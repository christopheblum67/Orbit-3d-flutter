import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/series.dart';

void main() {
  group('Series.fromMap', () {
    test('parses a series from a real Xtream API list item (rating as string)', () {
      final series = Series.fromMap({
        'num': 1,
        'name': 'The Rain',
        'series_id': 2,
        'cover': 'https://image.tmdb.org/cover.jpg',
        'plot': 'Une s\xc5\x93ur se bat pour sauver son fr\xc3\xa8re.',
        'genre': 'Science-Fiction & Fantastique',
        'director': '',
        'releaseDate': '2018-05-04',
        'rating': '7',
      });

      expect(series.id, '2');
      expect(series.title, 'The Rain');
      expect(series.year, 2018);
      expect(series.rating, 7.0);
      expect(series.genre, contains('Science-Fiction'));
    });

    test('falls back to id/title/year fields when list-style keys are absent',
        () {
      final series = Series.fromMap({
        'id': 99,
        'title': 'Une action',
        'year': 2020,
        'rating': 8.5,
      });

      expect(series.id, '99');
      expect(series.title, 'Une action');
      expect(series.year, 2020);
      expect(series.rating, 8.5);
      expect(series.episodes, isEmpty);
    });

    test('keeps default values when rating/year are missing or invalid', () {
      final series = Series.fromMap({
        'name': 'Sans note',
        'series_id': 7,
        'rating': 'abc',
      });

      expect(series.rating, 0);
      expect(series.year, 0);
    });
  });

  group('Episode.fromMap', () {
    test('parses episode id, number and season from Xtream info response', () {
      final episode = Episode.fromMap({
        'id': '14190',
        'episode_num': 1,
        'season': '1',
        'title': 'Restez à l\'abri',
      });

      expect(episode.id, '14190');
      expect(episode.episodeNumber, 1);
      expect(episode.season, 1);
    });
  });
}