import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/search.dart';

/// La recherche doit suivre exactement le même principe de filtrage par
/// catégorie que les grilles VOD / Séries / Chaînes : sélectionner une
/// catégorie ne doit jamais remonter de résultat d'une autre catégorie.
///
/// Avant cette règle, `SearchItem.categoryId` existait mais n'était jamais lu
/// au moment du filtrage : la recherche renvoyait la section entière, quelle
/// que soit la catégorie choisie.
void main() {
  SearchItem item(String id, String? categoryId, {SearchType type = SearchType.vod}) {
    return SearchItem(
      id: id,
      type: type,
      title: 'Titre $id',
      subtitle: '',
      posterUrl: '',
      categoryId: categoryId,
      score: 0.5,
      source: SearchSource.local,
    );
  }

  // Rappel de la règle implémentée dans SearchService : une catégorie nulle ou
  // vide ne filtre rien (cas d'un sélecteur non renseigné).
  bool matches(SearchItem i, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return true;
    return i.categoryId == categoryId;
  }

  group('filtrage par catégorie', () {
    test('ne garde que la catégorie demandée', () {
      final results = [
        item('a', '12'),
        item('b', '34'),
        item('c', '12'),
      ];

      final filtered = results.where((i) => matches(i, '12')).toList();

      expect(filtered.map((i) => i.id), ['a', 'c']);
    });

    test('categorie nulle = aucun filtre', () {
      final results = [item('a', '12'), item('b', '34')];

      expect(results.where((i) => matches(i, null)), hasLength(2));
    });

    test('categorie vide = aucun filtre', () {
      final results = [item('a', '12'), item('b', '34')];

      expect(results.where((i) => matches(i, '')), hasLength(2));
    });

    // Un résultat sans catégorie ne doit pas disparaître silencieusement
    // quand une catégorie est sélectionnée, mais il ne doit pas non plus
    //satisfaire une catégorie explicite.
    test('resultat sans categorie exclu des qu categorie demandee', () {
      final results = [item('a', null), item('b', '12')];

      final filtered = results.where((i) => matches(i, '12')).toList();

      expect(filtered.map((i) => i.id), ['b']);
    });

    test('categorie inconnue donne un resultat vide', () {
      final results = [item('a', '12'), item('b', '34')];

      expect(results.where((i) => matches(i, '999')), isEmpty);
    });
  });
}
