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
          reason: 'applySort doit travailler sur une copie',);
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

    test('ratingAsc est l\'inverse exact de ratingDesc', () {
      final input = [
        item('1', rating: 3),
        item('2', rating: 9),
        item('3', rating: 5),
        item('4', rating: 7),
      ];
      final desc =
          manager.applySort(input, SortMode.ratingDesc).map((e) => e.id);
      final asc = manager.applySort(input, SortMode.ratingAsc).map((e) => e.id);
      // Notes toutes distinctes : `List.sort` n'étant pas stable, un doublon
      // (ex. deux notes 9) inverserait l'ordre relatif entre les deux tris.
      expect(asc, desc.toList().reversed);
    });

    test('yearDesc', () {
      final sorted = manager.applySort(
        [item('1', year: 1999), item('2', year: 2021), item('3', year: 2010)],
        SortMode.yearDesc,
      );
      expect(sorted.map((e) => e.id), ['2', '3', '1']);
    });

    test('yearAsc remonte les années anciennes (année 0 en tête)', () {
      final sorted = manager.applySort(
        [item('1', year: 1999), item('2', year: 0), item('3', year: 2021)],
        SortMode.yearAsc,
      );
      expect(sorted.map((e) => e.id), ['2', '1', '3']);
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

    test('recentlyAddedAsc classe du plus ancien au plus récent', () {
      final sorted = manager.applySort(
        [
          item('1'),
          item('2', added: DateTime(2024, 5, 1)),
          item('3', added: DateTime(2025, 1, 1)),
        ],
        SortMode.recentlyAddedAsc,
      );
      // Les items sans date restent en fin de liste, comme dans le sens inverse.
      expect(sorted.map((e) => e.id), ['2', '3', '1']);
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

  group('sens et inversibilité (bouton ↑/↓)', () {
    test('chaque critère réversible a un inverse de même critère', () {
      final pairs = <SortMode, SortMode>{
        SortMode.nameAsc: SortMode.nameDesc,
        SortMode.ratingDesc: SortMode.ratingAsc,
        SortMode.yearDesc: SortMode.yearAsc,
        SortMode.recentlyAdded: SortMode.recentlyAddedAsc,
        SortMode.durationShort: SortMode.durationLong,
        SortMode.affinity: SortMode.affinityAsc,
      };
      for (final entry in pairs.entries) {
        expect(
          entry.key.reversed,
          entry.value,
          reason: '${entry.key} doit s\'inverser en ${entry.value}',
        );
        expect(
          entry.value.reversed,
          entry.key,
          reason: '${entry.value} doit s\'inverser en ${entry.key}',
        );
        expect(
          entry.key.criterion,
          entry.value.criterion,
          reason: '${entry.key} et ${entry.value} partagent le même critère',
        );
      }
    });

    test('« À reprendre » est le seul critère sans inverse', () {
      expect(SortMode.resumeFirst.reversed, isNull);
      for (final mode in SortMode.values) {
        if (mode != SortMode.resumeFirst) {
          expect(mode.reversed, isNotNull, reason: '$mode doit être inversible');
        }
      }
    });

    test('le sens annoncé correspond à l\'ordre produit par applySort', () {
      final byRating = [
        item('1', rating: 3),
        item('2', rating: 9),
      ];
      final ascIds = manager.applySort(byRating, SortMode.ratingAsc)
          .map((e) => e.id)
          .toList();
      expect(SortMode.ratingAsc.isAscending, isTrue);
      expect(ascIds, ['1', '2']);
      final descIds = manager.applySort(byRating, SortMode.ratingDesc)
          .map((e) => e.id)
          .toList();
      expect(SortMode.ratingDesc.isAscending, isFalse);
      expect(descIds, ['2', '1']);
    });

    test('criterion réduit chaque sens au même représentant', () {
      expect(SortMode.nameDesc.criterion, SortMode.nameDesc);
      expect(SortMode.nameAsc.criterion, SortMode.nameDesc);
      expect(SortMode.affinityAsc.criterion, SortMode.affinity);
      expect(SortMode.resumeFirst.criterion, SortMode.resumeFirst);
    });

    test('isAlphabetical ne concerne que les modes triés par titre', () {
      expect(SortMode.nameAsc.isAlphabetical, isTrue);
      expect(SortMode.nameDesc.isAlphabetical, isTrue);
      expect(SortMode.ratingDesc.isAlphabetical, isFalse);
    });
  });
}
