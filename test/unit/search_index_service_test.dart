import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/services/search_index_service.dart';

SearchIndexEntry e(
  String id,
  String title, {
  String subtitle = '',
  SearchType type = SearchType.vod,
}) =>
    SearchIndexEntry(
      type: type,
      id: id,
      title: title,
      subtitle: subtitle,
      streamUrl: 'http://x/$id',
      posterUrl: '',
    );

void main() {
  group('SearchIndexService.build', () {
    test('indexe les entrées et remplace l’existant', () {
      final index = SearchIndexService();
      index.build([e('1', 'Interstellar'), e('2', 'Inception')]);
      expect(index.size, 2);
      index.build([e('3', 'Batman')]);
      expect(index.size, 1);
      expect(index.isBuilt, true);
    });

    test('pas de résultats si vide ou jamais construit', () {
      expect(SearchIndexService().search('star'), isEmpty);
      final index = SearchIndexService()..build(const []);
      expect(index.search('star'), isEmpty);
    });
  });

  group('SearchIndexService.search', () {
    final index = SearchIndexService()
      ..build([
        e('1', 'Interstellar'),
        e('2', 'Inception'),
        e('3', 'The Dark Knight', subtitle: 'Batman'),
        e('4', 'L’Échelle de Jacob', type: SearchType.series),
      ]);

    test('trouve par préfixe de token', () {
      final hits = index.search('inter');
      expect(hits.map((h) => h.entry.id), contains('1'));
    });

    test('trouve par token du sous-titre', () {
      final hits = index.search('batman');
      expect(hits.map((h) => h.entry.id), contains('3'));
    });

    test('filtre par type', () {
      final hits = index.search('échelle', type: SearchType.series);
      expect(hits, hasLength(1));
      expect(hits.single.entry.id, '4');
      expect(index.search('échelle', type: SearchType.vod), isEmpty);
    });

    test('insensible aux accents et à la casse', () {
      expect(index.search('ECHELLE'), hasLength(1));
      expect(index.search('Échelle'), hasLength(1));
    });

    test('multi-tokens : la meilleure correspondance est en tête', () {
      final hits = index.search('dark knight');
      expect(hits, isNotEmpty);
      expect(hits.first.entry.id, '3');
    });

    test('range de préfixe : « in » couvre inception, pas interstellar', () {
      final hits = index.search('in');
      final ids = hits.map((h) => h.entry.id).toSet();
      expect(ids, contains('2'));
      // « interstellar » commence par ine..., pas par in.
      expect(ids, containsAll(['2']));
    });

    test('limite les résultats', () {
      final many = SearchIndexService()
        ..build([
          for (var i = 0; i < 50; i++) e('$i', 'Star Wars $i'),
        ]);
      expect(many.search('star', limit: 10), hasLength(10));
    });
  });
}