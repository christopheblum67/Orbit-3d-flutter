import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';

Recommendation recoOf(String id) {
  return Recommendation(
    kind: RecommendationKind.movie,
    movie: Movie(
      id: id,
      title: 'Titre $id',
      description: '',
      posterUrl: '',
      year: 2024,
      genre: 'Action',
      director: '',
      rating: 5,
      pegi: '',
      streamId: '',
    ),
  );
}

ScoredReco scored(String id, double affinity) {
  return ScoredReco(
    recoOf(id),
    0,
    0,
    5,
    affinity: affinity,
  );
}

GroupReco groupReco(String id, List<double> affinities) {
  return GroupReco(reco: recoOf(id), affinities: affinities);
}

void main() {
  group('prioritizeStrongAffinity', () {
    // Le cœur du correctif : un contenu très affin doit remonter devant un
    // contenu mieux classé par le score historique, sans être perdu.
    test('a >80% item is promoted above a lower-ranked one', () {
      final items = [
        scored('a', 0.95),
        scored('b', 0.60),
        scored('c', 0.20),
      ];

      final result = prioritizeStrongAffinity(items);

      expect(result.first.reco.id, 'a');
      expect(result.map((e) => e.reco.id).toList(), containsAll(['b', 'c']));
      expect(result, hasLength(3));
    });

    // La priorisation ne doit rien retirer : la taille est invariante.
    test('never drops an item', () {
      final items = [scored('a', 0.81), scored('b', 0.79), scored('c', 0.1)];

      final result = prioritizeStrongAffinity(items);

      expect(result, hasLength(items.length));
      expect(result.map((e) => e.reco.id).toSet(), {'a', 'b', 'c'});
    });

    // Stabilité : l'ordre relatif dans chaque groupe est préservé, donc deux
    // appels successifs ne réordonnent pas la liste de façon imprévisible.
    test('is stable across repeated calls', () {
      final items = [
        scored('a', 0.30),
        scored('b', 0.90),
        scored('c', 0.10),
        scored('d', 0.85),
      ];

      final first = prioritizeStrongAffinity(items).map((e) => e.reco.id).toList();
      final second =
          prioritizeStrongAffinity(items).map((e) => e.reco.id).toList();

      expect(first, second);
      // Les deux à coups de cœur à devant, dans leur ordre d'origine.
      expect(first, ['b', 'd', 'a', 'c']);
    });

    test('empty input is handled', () {
      expect(prioritizeStrongAffinity([]), isEmpty);
    });

    test('threshold is inclusive at exactly 80%', () {
      final items = [scored('low', 0.10), scored('edge', 0.80)];

      final result = prioritizeStrongAffinity(items);

      expect(result.first.reco.id, 'edge');
    });
  });

  group('prioritizeStrongGroupAffinity', () {
    // Un contenu plébiscité par un seul membre ne doit pas dominer le groupe :
    // le critère porte sur le maillon faible.
    test('a one-sided hit does not outrank a group-wide hit', () {
      final items = [
        groupReco('polarisant', [0.95, 0.10]),
        groupReco('unanime', [0.85, 0.90]),
      ];

      final result = prioritizeStrongGroupAffinity(items);

      expect(result.first.reco.id, 'unanime');
    });

    test('group-wide hit is promoted', () {
      final items = [groupReco('a', [0.20, 0.25]), groupReco('b', [0.90, 0.88])];

      final result = prioritizeStrongGroupAffinity(items);

      expect(result.first.reco.id, 'b');
    });

    test('never drops an item', () {
      final items = [groupReco('a', [0.9, 0.9]), groupReco('b', [0.1, 0.1])];

      expect(prioritizeStrongGroupAffinity(items), hasLength(2));
    });
  });
}
