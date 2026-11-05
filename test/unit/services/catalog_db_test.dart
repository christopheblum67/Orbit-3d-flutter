import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Movie _movie(
  String id,
  String title, {
  String genre = '',
  int year = 2000,
  double rating = 5,
  String category = 'c1',
  DateTime? added,
}) {
  return Movie(
    id: id,
    title: title,
    description: 'desc',
    posterUrl: 'p$id',
    year: year,
    genre: genre,
    director: '',
    rating: rating,
    pegi: '',
    streamId: 's$id',
    containerExtension: 'mkv',
    categoryId: category,
    addedDate: added,
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late CatalogDb db;
  const sub = 'http://x|u';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('catalog_db_test');
    db = CatalogDb.forTesting('${dir.path}\\t.db');
    await db.replaceMovies(sub, 'sig1', [
      _movie(
        '1',
        'Alpha',
        genre: 'Action',
        year: 2001,
        rating: 7,
        added: DateTime.utc(2024, 1, 1),
      ),
      _movie(
        '2',
        'Bravo',
        genre: 'Drame',
        year: 2010,
        rating: 9,
        category: 'c2',
        added: DateTime.utc(2024, 3, 1),
      ),
      _movie(
        '3',
        'Charlie',
        genre: 'Action',
        year: 1999,
        rating: 3,
        added: DateTime.utc(2024, 2, 1),
      ),
    ]);
  });

  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  test('hasData / isCurrent / count', () async {
    expect(await db.hasData(CatalogKind.vod, sub), isTrue);
    expect(await db.hasData(CatalogKind.series, sub), isFalse);
    expect(await db.isCurrent(CatalogKind.vod, sub, 'sig1'), isTrue);
    expect(await db.isCurrent(CatalogKind.vod, sub, 'autre'), isFalse);
    expect(await db.count(CatalogKind.vod, sub), 3);
  });

  test('tris', () async {
    Future<List<String>> ids(CatalogSort s) async =>
        (await db.queryMovies(sub, sort: s)).map((m) => m.id).toList();
    expect(await ids(CatalogSort.title), ['1', '2', '3']);
    expect(await ids(CatalogSort.titleDesc), ['3', '2', '1']);
    expect(await ids(CatalogSort.rating), ['2', '1', '3']);
    expect(await ids(CatalogSort.ratingAsc), ['3', '1', '2']);
    expect(await ids(CatalogSort.year), ['2', '1', '3']);
    expect(await ids(CatalogSort.yearAsc), ['3', '1', '2']);
    expect(await ids(CatalogSort.recentlyAdded), ['2', '3', '1']);
    expect(await ids(CatalogSort.recentlyAddedAsc), ['1', '3', '2']);
  });

  test('filtres : catégorie, recherche, ids, masquage, pagination', () async {
    final cat = await db.queryMovies(
      sub,
      filter: const CatalogFilter(categoryId: 'c2'),
    );
    expect(cat.map((m) => m.id), ['2']);

    final search = await db.queryMovies(
      sub,
      filter: const CatalogFilter(query: 'action'),
      sort: CatalogSort.title,
    );
    expect(search.map((m) => m.id), ['1', '3']);

    final only = await db.queryMovies(
      sub,
      filter: const CatalogFilter(onlyIds: {'3'}),
    );
    expect(only.map((m) => m.id), ['3']);
    expect(
      await db.queryMovies(sub, filter: const CatalogFilter(onlyIds: {})),
      isEmpty,
    );

    final hidden = await db.queryMovies(
      sub,
      filter: const CatalogFilter(hiddenCategories: {'c2'}),
    );
    expect(hidden.length, 2);

    final page = await db.queryMovies(
      sub,
      sort: CatalogSort.title,
      limit: 2,
      offset: 2,
    );
    expect(page.map((m) => m.id), ['3']);
  });

  test('champs de lecture conservés', () async {
    final m = (await db.queryMovies(sub, sort: CatalogSort.title)).first;
    expect(m.streamId, 's1');
    expect(m.containerExtension, 'mkv');
    expect(m.posterUrl, 'p1');
  });

  test('compteurs par catégorie et remplacement', () async {
    expect(
      await db.categoryCounts(CatalogKind.vod, sub),
      {'c1': 2, 'c2': 1},
    );
    await db.replaceMovies(sub, 'sig2', [_movie('9', 'Zulu')]);
    expect(await db.count(CatalogKind.vod, sub), 1);
    expect(await db.isCurrent(CatalogKind.vod, sub, 'sig2'), isTrue);
  });

  test('signatureOf varie avec le contenu', () {
    final a = Uint8List.fromList(List.filled(10000, 1));
    final b = Uint8List.fromList([...List.filled(9999, 1), 2]);
    expect(CatalogDb.signatureOf(a, 3), CatalogDb.signatureOf(a, 3));
    expect(CatalogDb.signatureOf(a, 3), isNot(CatalogDb.signatureOf(b, 3)));
    expect(CatalogDb.signatureOf(a, 3), isNot(CatalogDb.signatureOf(a, 4)));
  });
}
