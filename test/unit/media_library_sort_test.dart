import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';

/// Tri de la bibliothèque unifiée.
///
/// Ces tests verrouillent l'ordre produit par `applySort`, parce que la grille
/// VOD s'appuie dessus pour l'ordre d'affichage : une inversion silencieuse
/// ferait « clignoter » la liste sans qu'aucune erreur n'apparaisse.
void main() {
  late MediaLibraryManager manager;

  setUp(() {
    manager = MediaLibraryManager();
  });

  MediaItem item(
    String id, {
    String title = '',
    double rating = 0,
    int year = 0,
    int duration = 0,
    DateTime? added,
    DateTime? watched,
    bool unfinished = false,
  }) {
    return MediaItem(
      id: id,
      title: title,
      streamUrl: '',
      rating: rating,
      releaseYear: year,
      durationMinutes: duration,
      addedDate: added,
      // `isUnfinished` se déduit de la progression : on la fabrique donc par
      // les positions, pas par un paramètre.
      lastPositionMs: unfinished ? 500 : 0,
      totalDurationMs: 1000,
      lastWatchedAt: watched,
    );
  }

  group('tri par nom', () {
    test('nameAsc ignore la casse', () {
      final sorted = manager.applySort(
        [
          item('1', title: 'banane'),
          item('2', title: 'Ananas'),
          item('3', title: 'cerise'),
        ],
        SortMode.nameAsc,
      );
      expect(sorted.map((e) => e.id), ['2', '1', '3']);
    });

    test('nameDesc est l\'inverse de nameAsc', () {
      final input = [
        item('1', title: 'banane'),
        item('2', title: 'Ananas'),
        item('3', title: 'cerise'),
        item('4', title: 'Abricot'),
      ];
      final asc =
          manager.applySort(input, SortMode.nameAsc).map((e) => e.id).toList();
      final desc =
          manager.applySort(input, SortMode.nameDesc).map((e) => e.id).toList();
      expect(desc, asc.reversed);
    });

    test('les accents se comparent sans planter', () {
      final sorted = manager.applySort(
        [
          item('1', title: 'Été à Paris'),
          item('2', title: 'Eléphant'),
          item('3', title: 'Zoo'),
        ],
        SortMode.nameAsc,
      );
      expect(sorted.length, 3);
      expect(sorted.first.title, 'Eléphant');
    });

    test('une liste vide ou à un élément ne plante pas', () {
      expect(manager.applySort([], SortMode.nameAsc), isEmpty);
      expect(manager.applySort([item('1')], SortMode.nameDesc).length, 1);
    });

    test('la liste d\'entrée n\'est pas modifiée sur place', () {
      final input = [item('2', title: 'b'), item('1', title: 'a')];
      manager.applySort(input, SortMode.nameAsc);
      expect(input.map((e) => e.id), ['2', '1'],
          reason: 'applySort doit travailler sur une copie');
    });

    test('titres identiques : tous les items sont conservés', () {
      final sorted = manager.applySort(
        [for (var i = 0; i < 5; i++) item('$i', title: 'MÊME')],
        SortMode.nameAsc,
      );
      expect(sorted.length, 5);
      expect(sorted.map((e) => e.id).toSet(), {'0', '1', '2', '3', '4'});
    });
  });

  group('tri par note, année et durée', () {
    test('ratingDesc', () {
      final sorted = manager.applySort(
        [item('1', rating: 3), item('2', rating: 9), item('3', rating: 5)],
        SortMode.ratingDesc,
      );
      expect(sorted.map((e) => e.id), ['2', '3', '1']);
    });

    test('yearDesc', () {
      final sorted = manager.applySort(
        [item('1', year: 1999), item('2', year: 2021), item('3', year: 2010)],
        SortMode.yearDesc,
      );
      expect(sorted.map((e) => e.id), ['2', '3', '1']);
    });

    test('durationShort et durationLong', () {
      final input = [
        item('1', duration: 120),
        item('2', duration: 30),
        item('3', duration: 90),
      ];
      expect(
        manager.applySort(input, SortMode.durationShort).map((e) => e.id),
        ['2', '3', '1'],
      );
      expect(
        manager.applySort(input, SortMode.durationLong).map((e) => e.id),
        ['1', '3', '2'],
      );
    });
  });

  group('dates', () {
    test('recentlyAdded met les items sans date en fin de liste', () {
      final sorted = manager.applySort(
        [
          item('1'),
          item('2', added: DateTime(2024, 5, 1)),
          item('3', added: DateTime(2025, 1, 1)),
        ],
        SortMode.recentlyAdded,
      );
      expect(sorted.map((e) => e.id), ['3', '2', '1']);
    });

    test('resumeFirst remonte les vidéos commencées non terminées', () {
      final sorted = manager.applySort(
        [
          item('1', watched: DateTime(2025, 6, 1)),
          item('2', unfinished: true),
          item('3'),
        ],
        SortMode.resumeFirst,
      );
      // L'item inachevé passe devant, puis les dates de lecture décroissantes,
      // l'item jamais vu en dernier (borne basse epoch).
      expect(sorted.first.id, '2');
      expect(sorted.last.id, '3');
    });
  });
}
