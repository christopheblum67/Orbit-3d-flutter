import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/vod/vod_catalog_pipeline.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

/// Contrat du pipeline catalogue VOD.
///
/// Deux choses sont vérifiées ici :
///
/// 1. **Exactitude** — le pipeline mémoïsé doit rendre exactement ce que rend
///    l'implémentation naïve qu'il remplace. Un test d'égalité stricte échoue
///    dès qu'une façade diverge.
/// 2. **Économie** — sans mémoïsation, taper une recherche rebuild le tri et
///    reminusculise tout le catalogue à chaque caractère. Ces compteurs
///    mesurent le travail réellement évité.
Movie _movie(
  String id,
  String title, {
  String genre = '',
  String category = 'c1',
  int year = 2000,
}) {
  return Movie(
    id: id,
    title: title,
    description: '',
    posterUrl: 'http://x/$id.jpg',
    year: year,
    genre: genre,
    director: '',
    rating: 5.0,
    pegi: '',
    streamId: 'http://x/$id.mkv',
    categoryId: category,
  );
}

/// Tri déterministe par titre : le pipeline ne dépend pas du tri réel.
List<Movie> _sortByTitle(List<Movie> movies, String mode) {
  final out = List<Movie>.from(movies);
  out.sort((a, b) => a.title.compareTo(b.title));
  return out;
}

/// Réimplémentation naïve, c'est-à-dire l'ancien code du `build()`.
List<Movie> _naivePipeline({
  required List<Movie> movies,
  required Set<String> hidden,
  required String categoryId,
  required Set<String> favIds,
  required Set<String> recentIds,
  required String query,
  required String sortMode,
}) {
  final categoryVisible = hidden.isEmpty
      ? movies
      : movies
          .where((m) => !hidden.contains(m.categoryId))
          .toList(growable: false);
  final List<Movie> filtered;
  if (categoryId == 'fav') {
    filtered = categoryVisible.where((m) => favIds.contains(m.id)).toList();
  } else if (categoryId == 'recent') {
    filtered = categoryVisible.where((m) => recentIds.contains(m.id)).toList();
  } else if (categoryId.isEmpty) {
    filtered = categoryVisible;
  } else {
    filtered =
        categoryVisible.where((m) => m.categoryId == categoryId).toList();
  }
  final q = query.trim().toLowerCase();
  final queryFiltered = q.isEmpty
      ? filtered
      : filtered
          .where((m) =>
              m.title.toLowerCase().contains(q) ||
              m.genre.toLowerCase().contains(q),)
          .toList();
  return _sortByTitle(queryFiltered, sortMode);
}

void main() {
  List<Movie> catalog({int n = 500}) => [
        for (var i = 0; i < n; i++)
          _movie('m$i', 'Film $i',
              genre: i.isEven ? 'Action' : 'Comédie',
              category: i.isEven ? 'c1' : 'c2',),
      ];

  group('exactitude', () {
    final movies = catalog(n: 60);

    test('recherche dans le titre, insensible à la casse', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      final r = p.apply(
        movies: movies,
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: const {},
        recentIds: const {},
        query: 'FILM 7',
        sortMode: 'name',
      );
      expect(r.visibleMovies.map((m) => m.id), ['m7']);
    });

    test('recherche dans le genre', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      final r = p.apply(
        movies: movies,
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: const {},
        recentIds: const {},
        query: 'comédie',
        sortMode: 'name',
      );
      // Tous les index impairs portent « Comédie ».
      expect(r.visibleMovies.length, 30);
      expect(
          r.visibleMovies.every(
              (m) => m.id.endsWith('1') || int.parse(m.id.substring(1)).isOdd,),
          isTrue,);
    });

    test('une query qui chevaucherait titre et genre ne matche pas', () {
      // Un film dont le genre commence par la fin de son titre : le séparateur
      // U+0000 doit empêcher la correspondance à cheval.
      final tricky = [_movie('x', 'Blade', genre: 'Runner')];
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      final r = p.apply(
        movies: tricky,
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: const {},
        recentIds: const {},
        query: 'deR',
        sortMode: 'name',
      );
      expect(r.visibleMovies, isEmpty);
    });

    test('concorde avec le pipeline naïf sur un balayage de requêtes', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      const hidden = <String>{'c2'};
      final favIds = {'m1', 'm5', 'm9'};
      final recentIds = {'m2', 'm4'};
      const queries = [
        '',
        ' ',
        'film',
        'Film 1',
        'film 1',
        'action',
        'ACTION',
        'zzz',
        'm',
        '0',
        'film 12',
        'comédie',
        'runner',
        'blade',
      ];
      const categories = ['', 'fav', 'recent', 'c1', 'c2'];

      for (final categoryId in categories) {
        for (final query in queries) {
          final expected = _naivePipeline(
            movies: movies,
            hidden: hidden,
            categoryId: categoryId,
            favIds: favIds,
            recentIds: recentIds,
            query: query,
            sortMode: 'name',
          );
          final actual = p
              .apply(
                movies: movies,
                hiddenCategories: hidden,
                categoryId: categoryId,
                favoriteIds: favIds,
                recentIds: recentIds,
                query: query,
                sortMode: 'name',
              )
              .visibleMovies;
          expect(actual.map((m) => m.id), expected.map((m) => m.id),
              reason: 'catégorie="$categoryId" query="$query"',);
        }
      }
    });

    test('les compteurs des onglets ignorent le filtre texte', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      final r = p.apply(
        movies: movies,
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: {'m1', 'm5'},
        recentIds: {'m2', 'm4'},
        query: 'film 1',
        sortMode: 'name',
      );
      // 60 films au total, 2 favoris, 2 récents — même filtré sur "film 1".
      expect(r.visibleCount, 60);
      expect(r.favoriteCount, 2);
      expect(r.recentCount, 2);
    });

    test('les compteurs par catégorie ignorent les catégories masquées', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      // c2 est masquée : ses 30 films ne doivent apparaître dans aucun compteur.
      final r = p.apply(
        movies: movies,
        hiddenCategories: const {'c2'},
        categoryId: '',
        favoriteIds: const {},
        recentIds: const {},
        query: '',
        sortMode: 'name',
      );
      expect(r.categoryCounts.keys.toSet(), {'c1'});
      expect(r.categoryCounts['c1'], 30);
      expect(r.visibleCount, 30);
    });

    test('les films sans catégorie ne créent pas de clef', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      final r = p.apply(
        movies: [
          _movie('a', 'A', category: 'x'),
          _movie('b', 'B', category: ''),
          _movie('c', 'C', category: 'y'),
        ],
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: const {},
        recentIds: const {},
        query: '',
        sortMode: 'name',
      );
      expect(r.categoryCounts, {'x': 1, 'y': 1});
      expect(r.visibleCount, 3,
          reason: 'le filtre texte est vide, rien n\'est exclu',);
    });

    test('un changement de favoris invalide les compteurs', () {
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      final before = p.apply(
        movies: movies,
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: {'m1'},
        recentIds: const {},
        query: '',
        sortMode: 'name',
      );
      expect(before.favoriteCount, 1);
      final after = p.apply(
        movies: movies,
        hiddenCategories: const {},
        categoryId: '',
        favoriteIds: {'m1', 'm2', 'm3'},
        recentIds: const {},
        query: '',
        sortMode: 'name',
      );
      expect(after.favoriteCount, 3);
    });
  });

  group('économie de travail', () {
    test('taper une recherche ne refait ni le filtre catégorie ni les clés',
        () {
      // Même instance de catalogue à chaque appel, comme le ferait un provider
      // Riverpod dont la valeur ne change pas.
      final catalogList = catalog(n: 300);
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      List<Movie> run(String q) => p
          .apply(
            movies: catalogList,
            hiddenCategories: const {},
            categoryId: '',
            favoriteIds: const {},
            recentIds: const {},
            query: q,
            sortMode: 'name',
          )
          .visibleMovies;

      run('');
      expect(p.stageAPasses, 1);
      expect(p.stageBPasses, 1);

      // Une frappe = un nouveau résultat. Ce qui ne doit PAS être refait :
      // la passe complète sur le catalogue, le refiltrage par catégorie et la
      // construction des 300 clés de recherche minusculisées — c'était
      // ~200 000 allocations par frappe sur un catalogue de 100 000 entrées.
      run('f');
      run('fi');
      run('fil');
      run('film');
      expect(p.searchPasses, 4, reason: 'seul le filtre texte repasse');
      expect(p.stageAPasses, 1);
      expect(p.stageBPasses, 1);
    });

    test('changer de mode de tri invalide une seule fois', () {
      final catalogList = catalog(n: 50);
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      List<Movie> run(String mode) => p
          .apply(
            movies: catalogList,
            hiddenCategories: const {},
            categoryId: '',
            favoriteIds: const {},
            recentIds: const {},
            query: '',
            sortMode: mode,
          )
          .visibleMovies;

      run('name');
      run('name');
      expect(p.sortPasses, 1);
      run('year');
      expect(p.sortPasses, 2);
      run('name');
      expect(p.sortPasses, 3);
    });

    test('changer de catégorie recalcule les clés une seule fois', () {
      final catalogList = catalog(n: 50);
      final p = VodCatalogPipeline(sorter: _sortByTitle);
      List<Movie> run(String cat) => p
          .apply(
            movies: catalogList,
            hiddenCategories: const {},
            categoryId: cat,
            favoriteIds: const {},
            recentIds: const {},
            query: '',
            sortMode: 'name',
          )
          .visibleMovies;

      run('');
      final sortsAfterTous = p.sortPasses;
      run('');
      expect(p.sortPasses, sortsAfterTous,
          reason: 'même catégorie = aucun travail',);
      run('c1');
      expect(p.sortPasses, greaterThan(sortsAfterTous));
    });
  });

  group('searchKey', () {
    test('minusculise titre et genre', () {
      expect(
          VodCatalogPipeline.searchKey(_movie('1', 'MiXeD', genre: 'ACtion')),
          'mixed\u0000action',);
    });
  });
}
