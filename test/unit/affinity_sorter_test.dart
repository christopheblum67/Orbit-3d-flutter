import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/affinity_sorter.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';

/// Ces tests verrouillent le tri par affinité des écrans Films et Séries.
///
/// Le point critique : le tri doit RÉUTILISER la logique corrective du
/// matchmaking (`ProfileAffinityScorer` → `profileAffinityWithSignals`), jamais
/// une deuxième formule. Le correctif « Horreur, Mystère, … » (vrai genre TMDB
/// résolu, qui a remplacé le nom de catégorie Xtream côté tuiles) doit donc
/// continuer de profiter au tri : sans quoi on reviendrait en arrière (les films
/// rangés dans « Récents » retomberaient au seul bonus de note).
Movie _movie(
  String id,
  String title,
  String genre, {
  double rating = 0,
}) =>
    Movie(
      id: id,
      title: title,
      description: '',
      posterUrl: '',
      year: 2024,
      genre: genre,
      director: '',
      rating: rating,
      pegi: '',
      streamId: 'https://host/u/p/$id',
    );

void main() {
  group('sortByAffinityDesc', () {
    test('classe par score décroissant', () {
      final items = ['a', 'b', 'c'];
      final scores = {'a': 10.0, 'b': 90.0, 'c': 50.0};
      final res = sortByAffinityDesc(
        items,
        score: (s) => scores[s]!,
        title: (s) => s,
      );
      expect(res, ['b', 'c', 'a']);
    });

    test('égalité de score départagée par titre croissant', () {
      final res = sortByAffinityDesc(
        ['Zebre', 'alpha', 'Mike'],
        score: (_) => 42.0,
        title: (s) => s,
      );
      expect(res, ['alpha', 'Mike', 'Zebre']);
    });

    test('ne mute pas la liste d\'entrée', () {
      final input = ['a', 'b', 'c'];
      final copy = [...input];
      sortByAffinityDesc(
        input,
        score: (s) => s == 'b' ? 1.0 : 0.0,
        title: (s) => s,
      );
      expect(input, copy);
    });

    test('liste vide → liste vide', () {
      expect(
        sortByAffinityDesc<String>([], score: (_) => 0, title: (s) => s),
        isEmpty,
      );
    });

    test('descending: false classe par score croissant', () {
      final items = ['a', 'b', 'c'];
      final scores = {'a': 10.0, 'b': 90.0, 'c': 50.0};
      final res = sortByAffinityDesc(
        items,
        descending: false,
        score: (s) => scores[s]!,
        title: (s) => s,
      );
      expect(res, ['a', 'c', 'b']);
    });

    test('ascendant : égalité de score départagée par titre croissant', () {
      final res = sortByAffinityDesc(
        ['Zebre', 'alpha', 'Mike'],
        descending: false,
        score: (_) => 42.0,
        title: (s) => s,
      );
      expect(res, ['alpha', 'Mike', 'Zebre']);
    });

    test('ascendant : ne mute pas la liste d\'entrée', () {
      final input = ['a', 'b', 'c'];
      final copy = [...input];
      sortByAffinityDesc(
        input,
        descending: false,
        score: (s) => s == 'b' ? 1.0 : 0.0,
        title: (s) => s,
      );
      expect(input, copy);
    });
  });

  group('tri par affinité + logique corrective (non-régression)', () {
    const scorer = ProfileAffinityScorer(
      favoriteGenres: ['Horreur', 'Mystère'],
      favoriteIds: <String>{},
      seenIds: <String>{},
      tmdbTitles: <String>{},
    );

    test('le vrai genre (Horreur, Mystère) prime sur une note plus haute', () {
      // Film A : rangé dans la catégorie Xtream « Récents » (pas un genre),
      // mais très bien noté. Film B : correctement étiqueté « Horreur,
      // Mystère » (vrai genre TMDB), note plus faible. Le tri par affinité doit
      // remonter B — c'est toute la valeur du correctif.
      final a = _movie('a', 'A', 'Récents', rating: 9);
      final b = _movie('b', 'B', 'Horreur, Mystère', rating: 5);

      final res = sortByAffinityDesc(
        [a, b],
        score: (m) => scorer.percentForMovie(m).toDouble(),
        title: (m) => m.title,
      );

      expect(res.first.id, 'b');
    });

    test('le genre corrigé augmente bien le score (badge == tri)', () {
      // Même film : genre catalogue « Récents » (bas) puis genre réel TMDB
      // « Horreur, Mystère » (haut). Le tri et le badge passent tous deux par
      // `ProfileAffinityScorer`, donc le correctif profite aux deux.
      final catalog = _movie('x', 'X', 'Récents', rating: 6);
      final corrected = catalog.copyWith(genre: 'Horreur, Mystère');

      expect(
        scorer.percentForMovie(corrected),
        greaterThan(scorer.percentForMovie(catalog)),
      );
    });

    test('aucun favori → tri sur la note seul (repli sûr, non dégradant)', () {
      const empty = ProfileAffinityScorer(
        favoriteGenres: <String>[],
        favoriteIds: <String>{},
        seenIds: <String>{},
        tmdbTitles: <String>{},
      );
      final low = _movie('l', 'Low', 'Action', rating: 2);
      final high = _movie('h', 'High', 'Comédie', rating: 9);

      // Sans genre favori, la formule ne garde que le bonus de note : l'ordre
      // note décroissante est préservé (les écrans, eux, court-circuitent ce
      // mode et rendent la liste telle quelle — cf. _sortByAffinity).
      final res = sortByAffinityDesc(
        [low, high],
        score: (m) => empty.percentForMovie(m).toDouble(),
        title: (m) => m.title,
      );
      expect(res.first.id, 'h');
    });
  });

  group('alignement tri ↔ matchmaking', () {
    test('ProfileAffinityScorer applique la même formule que le matchmaking',
        () {
      const scorer = ProfileAffinityScorer(
        favoriteGenres: ['Horreur', 'Mystère'],
        favoriteIds: <String>{},
        seenIds: <String>{},
        tmdbTitles: <String>{},
      );
      final m = _movie('m', 'M', 'Horreur, Mystère', rating: 6);
      final reco = Recommendation(kind: RecommendationKind.movie, movie: m);

      final viaScorer = scorer.percentForMovie(m);
      final viaMatchmaking =
          (profileAffinityWithSignals(reco, ['Horreur', 'Mystère']) * 100)
              .round();

      expect(viaScorer, viaMatchmaking);
    });
  });
}
