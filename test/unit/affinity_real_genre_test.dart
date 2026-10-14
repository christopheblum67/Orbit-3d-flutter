import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/tmdb_rank_entry.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';

Movie _movie(String title, String genre, {double rating = 6}) => Movie(
      id: 'x',
      title: title,
      description: '',
      posterUrl: '',
      year: 2025,
      genre: genre,
      director: '',
      rating: rating,
      pegi: '',
      streamId: 's',
    );

Series _series(String title, String genre, {double rating = 6}) => Series(
      id: 'x',
      title: title,
      description: '',
      coverUrl: '',
      year: 2025,
      genre: genre,
      director: '',
      rating: rating,
      pegi: '',
      episodes: const [],
    );

void main() {
  group('TmdbRankEntry.genreNames', () {
    test('résout tous les genreIds en français, joints par virgule', () {
      const entry = TmdbRankEntry(
        tmdbId: 1,
        title: 'Film',
        posterPath: '',
        genreIds: [27, 9648, 878],
      );
      expect(entry.genreNames, 'Horreur, Mystère, Science-fiction');
    });

    test('ignore les ids inconnus et renvoie vide si aucun genre', () {
      const entry = TmdbRankEntry(
        tmdbId: 2,
        title: 'Film',
        posterPath: '',
        genreIds: [999999],
      );
      expect(entry.genreNames, '');
    });
  });

  group('isKnownGenreLabel', () {
    test('reconnaît les genres FR/EN et multi-genres', () {
      expect(isKnownGenreLabel('Horreur'), isTrue);
      expect(isKnownGenreLabel('Science-Fiction'), isTrue);
      expect(isKnownGenreLabel('Action & Aventure'), isTrue);
      expect(isKnownGenreLabel('Horreur, Thriller'), isTrue);
      expect(isKnownGenreLabel('Drame'), isTrue);
    });

    test('rejette les noms de catégorie Xtream', () {
      expect(isKnownGenreLabel('Récents'), isFalse);
      expect(isKnownGenreLabel('Nouveautés'), isFalse);
      expect(isKnownGenreLabel('Netflix'), isFalse);
      expect(isKnownGenreLabel(''), isFalse);
    });
  });

  group('affinité avec genre réel (Option A)', () {
    final favs = ['Horreur', 'Sci-Fi', 'Mystère'];

    test('genre = nom de catégorie → affinité = bonus de note seul (3%)', () {
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('Un film récent', 'Récents'),
      );
      expect((profileAffinity(reco, favs) * 100).round(), 3);
    });

    test('genre réel résolu → affinité élevée', () {
      // Ce que fera le badge : copyWith(genre: genre réel TMDB).
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('Un film récent', 'Horreur, Mystère'),
      );
      expect((profileAffinity(reco, favs) * 100).round(), greaterThan(60));
    });

    test('MovieGenreQuery a une égalité par valeur (index family stable)', () {
      const a = MovieGenreQuery(
        id: 'x',
        title: 'T',
        year: 2025,
        catalogGenre: 'Récents',
      );
      const b = MovieGenreQuery(
        id: 'x',
        title: 'T',
        year: 2025,
        catalogGenre: 'Récents',
      );
      const c = MovieGenreQuery(
        id: 'x',
        title: 'T',
        year: 2026,
        catalogGenre: 'Récents',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('affinité série avec genre réel (même correctif que la VOD)', () {
    final favs = ['Horreur', 'Sci-Fi', 'Mystère'];

    test('genre = nom de catégorie → affinité = bonus de note seul (3%)', () {
      final reco = Recommendation(
        kind: RecommendationKind.series,
        series: _series('Une série récente', 'Récents'),
      );
      expect((profileAffinity(reco, favs) * 100).round(), 3);
    });

    test('genre réel résolu → affinité élevée', () {
      // Ce que fera le badge : Series reconstruite avec le genre TMDB réel.
      final reco = Recommendation(
        kind: RecommendationKind.series,
        series: _series('Une série récente', 'Horreur, Mystère'),
      );
      expect((profileAffinity(reco, favs) * 100).round(), greaterThan(60));
    });

    test('SeriesGenreQuery a une égalité par valeur (index family stable)', () {
      const a = SeriesGenreQuery(
        id: 'x',
        title: 'T',
        year: 2025,
        catalogGenre: 'Récents',
      );
      const b = SeriesGenreQuery(
        id: 'x',
        title: 'T',
        year: 2025,
        catalogGenre: 'Récents',
      );
      const c = SeriesGenreQuery(
        id: 'x',
        title: 'T',
        year: 2026,
        catalogGenre: 'Récents',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('TmdbRankEntry.fromTvJson résout les genres TV (famille TV)', () {
      final entry = TmdbRankEntry.fromTvJson({
        'id': 42,
        'name': 'Série',
        'first_air_date': '2023-05-01',
        'vote_average': 8.2,
        'genre_ids': [9648, 18, 10765],
      });
      expect(entry.isTv, isTrue);
      expect(entry.year, 2023);
      expect(entry.genreNames, 'Mystère, Drame, Sci-Fi & Fantasy');
    });
  });
}
