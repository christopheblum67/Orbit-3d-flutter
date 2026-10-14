import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';

/// Vérrouille l'alignement « matchmaking ↔ grilles » sur le vrai genre TMDB.
///
/// Les tuiles Films/Séries et le tri par affinité scorent sur le **vrai genre
/// TMDB** (résolu en tâche de fond, « Horreur, Mystère, … »), tandis que l'onglet
/// « Pour vous » ne disposait que du genre catalogue (souvent un nom de
/// catégorie Xtream du type « Récents »). Résultat : un même film pouvait
/// afficher 8 % en tuile et être mal classé dans le matchmaking.
///
/// Le correctif réinjecte le genre réel déjà connu (cache Hive partagé, sans
/// réseau) dans la [Recommendation] avant le scoring. Ces tests garantissent que
/// ce réinjectement change bien le score, et qu'il est sans effet quand le genre
/// réel est absent (aucune régression).
Movie _movie(String title, String genre, {double rating = 6}) => Movie(
      id: 'm',
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
      id: 's',
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
  group('recommendationWithRealGenre (film)', () {
    test('un genre réel résolu l\'emporte sur le nom de catégorie', () {
      final base = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('Un film', 'Récents'),
      );
      final aligned = recommendationWithRealGenre(base, 'Horreur, Mystère');

      final favs = ['Horreur', 'Mystère'];
      expect(
        profileAffinityWithSignals(aligned, favs),
        greaterThan(profileAffinityWithSignals(base, favs)),
      );
    });

    test('le genre réel remplace bien le genre de la recommandation', () {
      final base = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('Un film', 'Récents'),
      );
      final aligned = recommendationWithRealGenre(base, 'Horreur, Mystère');
      expect(aligned.genre, 'Horreur, Mystère');
      // Les autres champs sont préservés (id, note…).
      expect(aligned.id, base.id);
      expect(aligned.rating, base.rating);
    });

    test('genre réel vide → recommandation inchangée', () {
      final base = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('Un film', 'Récents'),
      );
      expect(identical(recommendationWithRealGenre(base, ''), base), isTrue);
    });

    test('genre réel identique au genre catalogue → inchangée', () {
      final base = Recommendation(
        kind: RecommendationKind.movie,
        movie: _movie('Un film', 'Action'),
      );
      expect(
        identical(recommendationWithRealGenre(base, 'Action'), base),
        isTrue,
      );
    });
  });

  group('movieWithRealGenre / seriesWithRealGenre (primitives)', () {
    test('film : remplace le genre catalogue par le genre réel', () {
      final m = _movie('Un film', 'Récents');
      final aligned = movieWithRealGenre(m, 'Horreur, Mystère');
      expect(aligned.genre, 'Horreur, Mystère');
      expect(aligned.id, m.id);
      expect(aligned.rating, m.rating);
    });

    test('film : genre réel vide → même instance (pas de copie)', () {
      final m = _movie('Un film', 'Récents');
      expect(identical(movieWithRealGenre(m, ''), m), isTrue);
    });

    test('série : remplace le genre catalogue par le genre réel', () {
      final s = _series('Une série', 'Tous');
      final aligned = seriesWithRealGenre(s, 'Drame, Mystère');
      expect(aligned.genre, 'Drame, Mystère');
      expect(aligned.id, s.id);
      expect(aligned.rating, s.rating);
    });

    test('série : genre réel identique → même instance (pas de copie)', () {
      final s = _series('Une série', 'Drame');
      expect(identical(seriesWithRealGenre(s, 'Drame'), s), isTrue);
    });
  });

  group('recommendationWithRealGenre (série)', () {
    test('un genre réel résolu l\'emporte sur le nom de catégorie', () {
      final base = Recommendation(
        kind: RecommendationKind.series,
        series: _series('Une série', 'Tous'),
      );
      final aligned = recommendationWithRealGenre(base, 'Drame, Mystère');

      final favs = ['Drame', 'Mystère'];
      expect(
        profileAffinityWithSignals(aligned, favs),
        greaterThan(profileAffinityWithSignals(base, favs)),
      );
    });

    test('le genre réel remplace bien le genre et garde l\'identité', () {
      final base = Recommendation(
        kind: RecommendationKind.series,
        series: _series('Une série', 'Tous'),
      );
      final aligned = recommendationWithRealGenre(base, 'Drame, Mystère');
      expect(aligned.genre, 'Drame, Mystère');
      expect(aligned.id, base.id);
      expect(aligned.rating, base.rating);
    });
  });
}
