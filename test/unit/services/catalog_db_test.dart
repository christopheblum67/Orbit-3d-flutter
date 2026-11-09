import 'dart:async';
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

  test('la pagination conserve un ordre stable pour les titres identiques', () async {
    await db.replaceMovies(sub, 'duplicates', [
      _movie('3', 'Identique'),
      _movie('1', 'Identique'),
      _movie('2', 'Identique'),
    ]);
    for (final sort in CatalogSort.values) {
      final ids = <String>[];
      for (var offset = 0; offset < 3; offset++) {
        final page = await db.queryMovies(sub, sort: sort, limit: 1, offset: offset);
        ids.add(page.single.id);
      }
      expect(ids, ['1', '2', '3'], reason: sort.name);
    }
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

  test('les lectures voient le catalogue publié pendant les lots', () async {
    final firstBatch = Completer<void>();
    final resume = Completer<void>();
    var batches = 0;
    final staged = CatalogDb.forTesting(
      '${dir.path}\\concurrent.db',
      afterBatchForTesting: () async {
        batches++;
        if (batches == 2) {
          firstBatch.complete();
          await resume.future;
        }
      },
    );
    await staged.replaceMovies(sub, 'old', [_movie('old', 'Ancien')]);
    final replacement = staged.replaceMovies(
      sub,
      'new',
      List.generate(501, (i) => _movie('$i', 'Film $i')),
    );
    await firstBatch.future;
    expect(await staged.count(CatalogKind.vod, sub), 1);
    expect((await staged.queryMovies(sub)).single.id, 'old');
    expect(await staged.isCurrent(CatalogKind.vod, sub, 'old'), isTrue);
    resume.complete();
    await replacement;
    expect(await staged.count(CatalogKind.vod, sub), 501);
    expect(await staged.isCurrent(CatalogKind.vod, sub, 'new'), isTrue);
  });

  test('une insertion échouée conserve le catalogue publié', () async {
    var calls = 0;
    final staged = CatalogDb.forTesting(
      '${dir.path}\\failed.db',
      afterBatchForTesting: () async {
        calls++;
        if (calls == 2) throw StateError('interruption simulée');
      },
    );
    await staged.replaceMovies(sub, 'old', [_movie('old', 'Ancien')]);
    await staged.replaceMovies(sub, 'new', [_movie('new', 'Nouveau')]);
    expect(await staged.isCurrent(CatalogKind.vod, sub, 'old'), isTrue);
    expect((await staged.queryMovies(sub)).single.id, 'old');
  });

  test('active WAL et indexe le tri par titre', () async {
    final opened = await databaseFactory.openDatabase('${dir.path}\\t.db');
    final journal = await opened.rawQuery('PRAGMA journal_mode');
    expect(journal.single.values.single.toString().toLowerCase(), 'wal');
    final plan = await opened.rawQuery(
      'EXPLAIN QUERY PLAN SELECT id FROM items '
      'WHERE kind = ? AND sub_key = ? ORDER BY title_key LIMIT ?',
      [CatalogKind.vod.index, 'key', 72],
    );
    expect(plan.map((row) => row['detail']).join(), contains('idx_items_title'));
  });

  test('suppression après remplacement retire le catalogue actif', () async {
    await db.replaceMovies(sub, 'sig2', [_movie('9', 'Zulu')]);
    await db.clear(kind: CatalogKind.vod, subKey: sub);
    expect(await db.hasData(CatalogKind.vod, sub), isFalse);
    expect(await db.queryMovies(sub), isEmpty);
  });

  test('une génération sans métadonnées publiées reste invisible', () async {
    final raw = await databaseFactory.openDatabase('${dir.path}\\t.db');
    await raw.rawInsert(
      'INSERT INTO items SELECT kind, ?, id, title, title_key, search_key, '
      'poster, year, genre, rating, category_id, pegi, added, stream_id, ext '
      'FROM items WHERE kind = ? AND sub_key = '
      '(SELECT data_key FROM meta WHERE kind = ? AND sub_key = ?)',
      ['abandoned', CatalogKind.vod.index, CatalogKind.vod.index, sub],
    );
    expect(await db.queryMovies('abandoned'), isEmpty);
    expect(await db.count(CatalogKind.vod, 'abandoned'), 0);
  });

  test('reprend le nettoyage des générations abandonnées au redémarrage', () async {
    final path = '${dir.path}\\t.db';
    final raw = await databaseFactory.openDatabase(path);
    for (final key in ['interrupted-stage', 'previous-generation']) {
      await raw.rawInsert(
        'INSERT INTO items SELECT kind, ?, id, title, title_key, search_key, '
        'poster, year, genre, rating, category_id, pegi, added, stream_id, ext '
        'FROM items WHERE kind = ? AND sub_key = '
        '(SELECT data_key FROM meta WHERE kind = ? AND sub_key = ?)',
        [key, CatalogKind.vod.index, CatalogKind.vod.index, sub],
      );
      await raw.insert('pending_cleanup', {
        'kind': CatalogKind.vod.index,
        'data_key': key,
      });
    }

    final reopened = CatalogDb.forTesting(path);
    expect(await reopened.hasData(CatalogKind.vod, sub), isTrue);
    // Le nettoyage est placé dans la file avant cette suppression sans effet.
    await reopened.clear(kind: CatalogKind.series, subKey: sub);
    expect(await reopened.count(CatalogKind.vod, sub), 3);
    expect(await raw.query('pending_cleanup'), isEmpty);
    final rows = await raw.rawQuery(
      'SELECT COUNT(*) AS n FROM items WHERE sub_key IN (?, ?)',
      ['interrupted-stage', 'previous-generation'],
    );
    expect(rows.single['n'], 0);
  });

  test('remplacements et suppression concurrents sont sérialisés', () async {
    final paused = Completer<void>();
    final resume = Completer<void>();
    var batches = 0;
    final staged = CatalogDb.forTesting(
      '${dir.path}\\queue.db',
      afterBatchForTesting: () async {
        if (++batches == 1) {
          paused.complete();
          await resume.future;
        }
      },
    );
    final first = staged.replaceMovies(sub, 'first', [_movie('1', 'Premier')]);
    await paused.future;
    final second = staged.replaceMovies(sub, 'second', [_movie('2', 'Deuxième')]);
    final clear = staged.clear(kind: CatalogKind.vod, subKey: sub);
    resume.complete();
    await Future.wait([first, second, clear]);
    expect(await staged.hasData(CatalogKind.vod, sub), isFalse);
    final raw = await databaseFactory.openDatabase('${dir.path}\\queue.db');
    expect(await raw.query('items'), isEmpty);
    expect(await raw.query('pending_cleanup'), isEmpty);
  });

  test('migration préserve les catalogues version 1', () async {
    final path = '${dir.path}\\legacy.db';
    final legacy = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE items (
              kind INTEGER NOT NULL, sub_key TEXT NOT NULL, id TEXT NOT NULL,
              title TEXT NOT NULL, title_key TEXT NOT NULL, search_key TEXT NOT NULL,
              poster TEXT NOT NULL, year INTEGER NOT NULL, genre TEXT NOT NULL,
              rating REAL NOT NULL, category_id TEXT NOT NULL, pegi TEXT,
              added INTEGER NOT NULL, stream_id TEXT NOT NULL DEFAULT '',
              ext TEXT NOT NULL DEFAULT '', PRIMARY KEY(kind, sub_key, id)
            ) WITHOUT ROWID
          ''');
          await db.execute('''
            CREATE TABLE meta (
              kind INTEGER NOT NULL, sub_key TEXT NOT NULL,
              signature TEXT NOT NULL, count INTEGER NOT NULL,
              updated_at INTEGER NOT NULL, PRIMARY KEY(kind, sub_key)
            )
          ''');
          await db.insert('items', {
            'kind': 0, 'sub_key': sub, 'id': 'legacy', 'title': 'Ancien',
            'title_key': 'ancien', 'search_key': 'ancien', 'poster': '',
            'year': 0, 'genre': '', 'rating': 0, 'category_id': '',
            'added': 0,
          });
          await db.insert('meta', {
            'kind': 0, 'sub_key': sub, 'signature': 'old',
            'count': 1, 'updated_at': 0,
          });
        },
      ),
    );
    await legacy.close();
    final migrated = CatalogDb.forTesting(path);
    expect((await migrated.queryMovies(sub)).single.id, 'legacy');
    await migrated.replaceMovies(sub, 'new', [_movie('new', 'Nouveau')]);
    expect((await migrated.queryMovies(sub)).single.id, 'new');
  });

  test('signatureOf varie avec le contenu', () {
    final a = Uint8List.fromList(List.filled(10000, 1));
    final b = Uint8List.fromList([...List.filled(9999, 1), 2]);
    expect(CatalogDb.signatureOf(a, 3), CatalogDb.signatureOf(a, 3));
    expect(CatalogDb.signatureOf(a, 3), isNot(CatalogDb.signatureOf(b, 3)));
    expect(CatalogDb.signatureOf(a, 3), isNot(CatalogDb.signatureOf(a, 4)));
  });
}
