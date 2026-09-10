import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/trakt_rank_entry.dart';

void main() {
  group('TraktRankEntry.fromMovieJson', () {
    test('parse tous les champs standard (extended=full)', () {
      final entry = TraktRankEntry.fromMovieJson({
        'title': 'Inception',
        'year': 2010,
        'ids': {
          'trakt': 1,
          'slug': 'inception-2010',
          'imdb': 'tt1375666',
          'tmdb': 27205,
        },
        'images': {
          'poster': ['https://walter.trakt.tv/image1.jpg'],
          'fanart': ['https://walter.trakt.tv/image2.jpg'],
        },
        'tagline': 'Your mind is the scene of the crime',
        'overview': 'Dom Cobb...',
        'released': '2010-07-15',
        'runtime': 148,
        'rating': 8.4,
        'votes': 35461,
        'certification': 'PG-13',
        'genres': ['action', 'science-fiction'],
        'trailer': 'https://youtube.com/watch?v=x',
      });

      expect(entry.traktId, 1);
      expect(entry.tmdbId, 27205);
      expect(entry.imdbId, 'tt1375666');
      expect(entry.slug, 'inception-2010');
      expect(entry.title, 'Inception');
      expect(entry.isTv, isFalse);
      expect(entry.year, 2010);
      expect(entry.rating, 8.4);
      expect(entry.voteCount, 35461);
      expect(entry.overview, 'Dom Cobb...');
      expect(entry.posterUrl, 'https://walter.trakt.tv/image1.jpg');
      expect(entry.backdropUrl, 'https://walter.trakt.tv/image2.jpg');
      expect(entry.genres, ['action', 'science-fiction']);
      expect(entry.runtime, 148);
      expect(entry.certification, 'PG-13');
      expect(entry.tagline, isNotEmpty);
      expect(entry.trailerUrl, 'https://youtube.com/watch?v=x');
      expect(entry.watchers, 0);
    });

    test('champs vides/nuls -> valeurs par défaut', () {
      final entry = TraktRankEntry.fromMovieJson({
        'title': 'X',
        'ids': {'trakt': 2, 'slug': 'x'},
        'year': null,
        'released': null,
        'rating': null,
        'votes': null,
        'images': null,
        'genres': null,
      });
      expect(entry.year, 0);
      expect(entry.rating, 0);
      expect(entry.voteCount, 0);
      expect(entry.posterUrl, isEmpty);
      expect(entry.backdropUrl, isEmpty);
      expect(entry.genres, isEmpty);
      expect(entry.traktId, 2);
    });
  });

  group('TraktRankEntry.fromShowJson', () {
    test('parse une série (first_aired / network / tvdb)', () {
      final entry = TraktRankEntry.fromShowJson({
        'title': 'Breaking Bad',
        'year': 2008,
        'ids': {
          'trakt': 1396,
          'slug': 'breaking-bad',
          'tvdb': 81189,
          'imdb': 'tt0903747',
          'tmdb': 1396,
        },
        'first_aired': '2008-01-20',
        'network': 'AMC',
        'certification': 'TV-MA',
        'rating': 8.9,
        'votes': 13299,
        'genres': ['crime', 'drama'],
      });

      expect(entry.title, 'Breaking Bad');
      expect(entry.isTv, isTrue);
      expect(entry.year, 2008);
      expect(entry.network, 'AMC');
      expect(entry.certification, 'TV-MA');
      expect(entry.rating, 8.9);
      expect(entry.genres, ['crime', 'drama']);
    });
  });

  group('TraktRankEntry.fromTrendingMovieJson/ShowJson', () {
    test('lit watchers depuis le wrapper et le media embedded', () {
      final movie = TraktRankEntry.fromTrendingMovieJson({
        'watchers': 8120,
        'movie': {
          'title': 'Dune: Part Two',
          'year': 2024,
          'ids': {'trakt': 100, 'slug': 'dune-part-2', 'tmdb': 693134},
          'released': '2024-02-27',
          'rating': 8.1,
          'votes': 5000,
        },
      });
      expect(movie.watchers, 8120);
      expect(movie.title, 'Dune: Part Two');
      expect(movie.year, 2024);
      expect(movie.isTv, isFalse);

      final show = TraktRankEntry.fromTrendingShowJson({
        'watchers': 3450,
        'show': {
          'title': 'Shōgun',
          'year': 2024,
          'ids': {'trakt': 200, 'slug': 'shogun', 'tmdb': 94971},
          'first_aired': '2024-02-27',
        },
      });
      expect(show.watchers, 3450);
      expect(show.title, 'Shōgun');
      expect(show.year, 2024);
      expect(show.isTv, isTrue);
    });
  });
}