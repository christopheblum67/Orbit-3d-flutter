import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';

Movie _movie(
  String id,
  String title,
  String genre, {
  double rating = 0,
  String description = '',
}) =>
    Movie(
      id: id,
      title: title,
      description: description,
      posterUrl: '',
      year: 2024,
      genre: genre,
      director: '',
      rating: rating,
      pegi: '',
      streamUrl: 'https://host/u/p/$id',
    );

Series _series(
  String id,
  String title,
  String genre, {
  double rating = 0,
  String description = '',
}) =>
    Series(
      id: id,
      title: title,
      description: description,
      coverUrl: '',
      year: 2024,
      genre: genre,
      director: '',
      rating: rating,
      pegi: '',
      episodes: const [],
    );

void main() {
  group('rankRecommendations', () {
    test('classe par pertinence du genre favori puis par note', () {
      final res = rankRecommendations(
        movies: [
          _movie(
            'a',
            'Aventure Alpha',
            'Aventure',
            rating: 7,
            description: 'Un film d\'action',
          ),
          _movie('b', 'Action Fort', 'Action', rating: 9),
          _movie('c', 'Aventure Bravo', 'Aventure', rating: 5),
        ],
        series: const [],
        favorites: ['Aventure'],
      );
      expect(res.length, 2);
      expect(res.first.title, 'Aventure Alpha');
      expect(res.last.title, 'Aventure Bravo');
    });

    test('mélange films et séries', () {
      final res = rankRecommendations(
        movies: [_movie('m1', 'Film Aventure', 'Aventure')],
        series: [_series('s1', 'Série Aventure', 'Aventure')],
        favorites: ['Aventure'],
      );
      expect(res.length, 2);
      expect(
          res.map((r) => r.kind),
          containsAll(
            [
              RecommendationKind.movie,
              RecommendationKind.series,
            ],
          ),
        );
    });

    test('sans genre favori, montre les mieux notés (note ≥ 6)', () {
      final res = rankRecommendations(
        movies: [
          _movie('x', 'Film moyen', 'Drame', rating: 4),
          _movie('y', 'Film excellent', 'Action', rating: 8),
        ],
        series: const [],
        favorites: [],
      );
      expect(res.isNotEmpty, isTrue);
      expect(res.first.title, 'Film excellent');
      final wellRated = res.every(
        (r) => r.rating >= 6 || r.title == 'Film excellent',
      );
      expect(wellRated, isTrue);
    });

    test('retourne vide si aucun contenu ne matche', () {
      final res = rankRecommendations(
        movies: [_movie('x', 'Drame triste', 'Drame')],
        series: const [],
        favorites: ['Science-Fiction'],
      );
      expect(res, isEmpty);
    });

    test('note ≥ 7 reçoit un bonus de 2', () {
      final res = rankRecommendations(
        movies: [
          _movie('a', 'Bon Film', 'Aventure', rating: 7),
          _movie('b', 'Super Film', 'Aventure', rating: 4),
        ],
        series: const [],
        favorites: ['Aventure'],
      );
      expect(res.first.title, 'Bon Film');
    });
  });
}
