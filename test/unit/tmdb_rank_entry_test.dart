import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';

void main() {
  group('TmdbRankEntry.fromMovieJson', () {
    test('parse tous les champs standard', () {
      final entry = TmdbRankEntry.fromMovieJson({
        'id': 5459,
        'title': 'Inception',
        'poster_path': '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        'backdrop_path': '/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
        'release_date': '2010-07-15',
        'vote_average': 8.4,
        'vote_count': 35461,
        'overview': "Dom Cobb...",
        'popularity': 87.123,
      });

      expect(entry.tmdbId, 5459);
      expect(entry.title, 'Inception');
      expect(entry.isTv, isFalse);
      expect(entry.year, 2010);
      expect(entry.rating, 8.4);
      expect(entry.voteCount, 35461);
      expect(entry.popularity, closeTo(87.123, 0.001));
      expect(
        entry.posterUrl,
        'https://image.tmdb.org/t/p/w342/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
      );
      expect(
        entry.backdropUrl,
        'https://image.tmdb.org/t/p/w780/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
      );
    });

    test('release_date vide -> year 0', () {
      final entry = TmdbRankEntry.fromMovieJson({
        'id': 1,
        'title': 'X',
        'poster_path': null,
        'backdrop_path': null,
        'release_date': null,
        'vote_average': null,
        'vote_count': null,
      });
      expect(entry.year, 0);
      expect(entry.rating, 0);
      expect(entry.voteCount, 0);
      expect(entry.posterUrl, isEmpty);
      expect(entry.backdropUrl, isEmpty);
    });
  });

  group('TmdbRankEntry.fromTvJson', () {
    test('parse une série (name / first_air_date)', () {
      final entry = TmdbRankEntry.fromTvJson({
        'id': 1396,
        'name': 'Breaking Bad',
        'poster_path': '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
        'backdrop_path': '/3faBlCJ9snWFeK3Ns66dOoMHnRf.jpg',
        'first_air_date': '2008-01-20',
        'vote_average': 8.9,
        'vote_count': 13299,
        'overview': '...',
      });

      expect(entry.tmdbId, 1396);
      expect(entry.title, 'Breaking Bad');
      expect(entry.isTv, isTrue);
      expect(entry.year, 2008);
      expect(entry.rating, 8.9);
      expect(entry.posterUrl, isNotEmpty);
    });
  });
}