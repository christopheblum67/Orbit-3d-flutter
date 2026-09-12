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

  group('profileAffinity', () {
    test('genre favori présent dans le genre du contenu → affinité = 1.0', () {
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('a', 'Aventure Alpha', 'Aventure', rating: 5),
      );
      expect(profileAffinity(reco, ['Aventure']), 1.0);
    });

    test('genre favori uniquement dans la description → affinité partielle', () {
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie(
          'b',
          'Océan calme',
          'Drame',
          description: 'Une histoire de science-fiction spatiale',
        ),
      );
      final affinity = profileAffinity(reco, ['Science-Fiction']);
      expect(affinity, greaterThan(0));
      expect(affinity, lessThan(1.0));
    });

    test('aucun genre favori → signal faible fondé sur la note uniquement', () {
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('c', 'Excellent', 'Drame', rating: 8),
      );
      final affinity = profileAffinity(reco, const []);
      expect(affinity, greaterThan(0));
      expect(affinity, lessThan(0.5));
    });

    test('affinité élevée pour un film qui touche plusieurs favoris', () {
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie(
          'd',
          'Aventure spatiale',
          'Action',
          description: 'science-fiction épique',
          rating: 7,
        ),
      );
      final affinity =
          profileAffinity(reco, ['Action', 'Aventure', 'Science-fiction']);
      expect(affinity, greaterThan(0.7));
    });
  });

  group('GroupReco', () {
    test('combined = moyenne des affinités, overlap = produit, minAffinity = min', () {
      final reco = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('p', 'Partage', 'Action'),
      );
      final grouped = GroupReco(reco: reco, affinities: [0.8, 0.4, 0.6]);
      expect(grouped.combined, closeTo(0.6, 0.0001));
      expect(grouped.overlap, closeTo(0.192, 0.0001));
      expect(grouped.minAffinity, closeTo(0.4, 0.0001));
    });
  });

  group('profileAffinityWithSignals', () {
    final reco = Recommendation(
      kind: RecommendationKind.movie,
      movie: _movie('pp', 'Action Fort', 'Action', rating: 7),
    );

    test('favori → bonus d\'affinité', () {
      final base = profileAffinity(reco, ['Action', 'Drame']);
      final boosted = profileAffinityWithSignals(reco, ['Action', 'Drame'],
          favoriteIds: {'pp'},);
      expect(boosted, greaterThan(base));
    });

    test('déjà vu → exclusion (affinité nulle)', () {
      final aff =
          profileAffinityWithSignals(reco, ['Action'], seenIds: {'pp'});
      expect(aff, 0.0);
    });

    test('titre présent dans TMDB recommandation → léger boost', () {
      final base = profileAffinity(reco, ['Action', 'Drame']);
      final boosted = profileAffinityWithSignals(reco, ['Action', 'Drame'],
          tmdbTitles: {'action fort'},);
      expect(boosted, greaterThan(base));
    });

    test('les signaux se cumulent sans dépasser 1.0', () {
      final aff = profileAffinityWithSignals(
        reco,
        ['Action', 'Drame'],
        favoriteIds: {'pp'},
        tmdbTitles: {'Action Fort'},
      );
      expect(aff, lessThanOrEqualTo(1.0));
    });
  });
}
