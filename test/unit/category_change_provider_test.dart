import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/providers/category_change_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory dir;
  late CategoryCountTracker tracker;
  late String databasePath;
  const movies = (subscriptionId: 'one', catalog: CategoryCatalog.movies);
  const series = (subscriptionId: 'one', catalog: CategoryCatalog.series);
  const other = (subscriptionId: 'two', catalog: CategoryCatalog.movies);
  CatalogItemIdentity item(String id, String category) =>
      (id: id, categoryId: category);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('category_changes_test_');
    databasePath = '${dir.path}${Platform.pathSeparator}changes.db';
    tracker = CategoryCountTracker.forTesting(databasePath);
  });
  tearDown(() async {
    await tracker.close();
    await dir.delete(recursive: true);
  });

  test('tracks actual additions, even when other items are removed', () async {
    await tracker.record(movies, [item('a', 'new'), item('b', 'new')],
        refresh: false);
    expect((await tracker.changes(movies)).newIds, isEmpty);
    await tracker.record(
      movies,
      [item('a', 'new'), item('c', 'new'), item('d', 'new')],
      refresh: true,
    );
    var changes = await tracker.changes(movies);
    expect(changes.categories, {'new': (total: 3, added: 2)});
    expect(changes.newIds, {'c', 'd'});
    expect((await tracker.changes(series)).newIds, isEmpty);
    expect((await tracker.changes(other)).newIds, isEmpty);

    await tracker.record(
      movies,
      [item('d', 'new'), item('c', 'new'), item('a', 'new')],
      refresh: false,
    );
    expect((await tracker.changes(movies)).newIds, {'c', 'd'});
    await tracker.close();
    tracker = CategoryCountTracker.forTesting(databasePath);
    expect((await tracker.changes(movies)).categories,
        {'new': (total: 3, added: 2)});
    await tracker.record(
      movies,
      [item('a', 'new'), item('c', 'new'), item('d', 'new')],
      refresh: true,
    );
    changes = await tracker.changes(movies);
    expect(changes.categories, isEmpty);
    expect(changes.newIds, isEmpty);
  });

  test('ignores empty results, duplicate IDs and category moves', () async {
    await tracker.record(series, [item('a', 'one'), item('b', 'one')],
        refresh: false);
    await tracker.record(series, [], refresh: true);
    await tracker.record(
        series, [item('a', 'two'), item('c', 'two'), item('c', 'two')],
        refresh: true);
    final changes = await tracker.changes(series);
    expect(changes.newIds, {'c'});
    expect(changes.categories, {'two': (total: 2, added: 1)});
  });

  test('simultaneous catalog updates keep their snapshots isolated', () async {
    await Future.wait([
      tracker.record(movies, [item('m1', 'movies')], refresh: false),
      tracker.record(series, [item('s1', 'series')], refresh: false),
    ]);
    await Future.wait([
      tracker.record(movies, [item('m1', 'movies'), item('m2', 'movies')],
          refresh: true),
      tracker.record(series, [item('s1', 'series'), item('s2', 'series')],
          refresh: true),
    ]);
    expect((await tracker.changes(movies)).newIds, {'m2'});
    expect((await tracker.changes(series)).newIds, {'s2'});
  });

  test('retries opening the database after an error', () async {
    await tracker.close();
    final missingDirectory =
        Directory('${dir.path}${Platform.pathSeparator}missing');
    final blockingFile = File(missingDirectory.path);
    await blockingFile.writeAsString('not a directory');
    tracker = CategoryCountTracker.forTesting(
      '${missingDirectory.path}${Platform.pathSeparator}changes.db',
    );
    await expectLater(tracker.changes(movies), throwsA(isA<Exception>()));
    await blockingFile.delete();
    await missingDirectory.create();
    await tracker.record(movies, [item('m1', 'movies')], refresh: false);
    expect((await tracker.changes(movies)).newIds, isEmpty);
  });

  test('M3U movie identity does not depend on playlist order', () {
    final movie = Movie(
      id: 'm3u-movie-1',
      title: 'Film',
      description: '',
      posterUrl: '',
      year: 0,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      streamId: 'https://example.test/a',
    );
    expect(movieChangeId(movie, isM3u: true),
        movieChangeId(movie.copyWith(id: 'm3u-movie-99'), isM3u: true));
    expect(movieChangeId(movie, isM3u: false), 'm3u-movie-1');
  });
}
