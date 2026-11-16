import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

enum CategoryCatalog { movies, series }

typedef CategoryChangeKey = ({String subscriptionId, CategoryCatalog catalog});
typedef CatalogItemIdentity = ({String id, String categoryId});
typedef CategoryIncrease = ({int total, int added});

class CategoryChanges {
  const CategoryChanges({this.categories = const {}, this.newIds = const {}});
  final Map<String, CategoryIncrease> categories;
  final Set<String> newIds;
}

/// Les identifiants de films M3U dépendent de leur position dans la playlist.
String movieChangeId(Movie movie, {required bool isM3u}) {
  if (!isM3u) return movie.id;
  if (movie.streamId.isEmpty) return '';
  return sha256.convert(utf8.encode(movie.streamId)).toString();
}

final categoryCountTrackerProvider = Provider<CategoryCountTracker>(
  (ref) => CategoryCountTracker(),
);

final categoryIncreasesProvider =
    FutureProvider.family<CategoryChanges, CategoryChangeKey>((ref, key) async {
  try {
    return await ref.watch(categoryCountTrackerProvider).changes(key);
  } catch (error, stack) {
    LoggerService.instance.error(
      'Impossible de lire les changements de catégories : $error',
      tag: 'catalog',
      error: error,
    );
    LoggerService.instance.error('$stack', tag: 'catalog');
    rethrow;
  }
});

/// Référence par abonnement et nouveautés depuis la dernière mise à jour.
class CategoryCountTracker {
  CategoryCountTracker();

  @visibleForTesting
  CategoryCountTracker.forTesting(String databasePath)
      : _testPath = databasePath;

  String? _testPath;
  Future<Database>? _opening;

  Future<Database> _database() async {
    final opening = _opening ??= _open();
    try {
      return await opening;
    } catch (_) {
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final dbPath = _testPath ??
        path.join(await getDatabasesPath(), 'orbit_category_changes.db');
    return openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE snapshots (
          subscription TEXT NOT NULL, catalog INTEGER NOT NULL,
          PRIMARY KEY (subscription, catalog)
        ) WITHOUT ROWID
      ''');
      for (final table in ['baseline', 'new_items']) {
        await db.execute('''
          CREATE TABLE $table (
            subscription TEXT NOT NULL, catalog INTEGER NOT NULL,
            id TEXT NOT NULL, category TEXT NOT NULL,
            PRIMARY KEY (subscription, catalog, id)
          ) WITHOUT ROWID
        ''');
      }
      await db.execute(
        'CREATE INDEX baseline_category ON baseline(subscription, catalog, category)',
      );
    });
  }

  Future<CategoryChanges> changes(CategoryChangeKey key) async {
    final db = await _database();
    return db.transaction((txn) async {
      final args = [key.subscriptionId, key.catalog.index];
      final rows = await txn.rawQuery('''
        SELECT n.category, COUNT(*) AS added,
          (SELECT COUNT(*) FROM baseline b
           WHERE b.subscription = n.subscription AND b.catalog = n.catalog
             AND b.category = n.category) AS total
        FROM new_items n
        WHERE n.subscription = ? AND n.catalog = ? AND n.category != ''
        GROUP BY n.category
      ''', args);
      final ids = await txn.query('new_items',
          columns: ['id'],
          where: 'subscription = ? AND catalog = ?',
          whereArgs: args);
      return CategoryChanges(
        categories: {
          for (final row in rows)
            row['category'] as String: (
              total: row['total'] as int,
              added: row['added'] as int,
            ),
        },
        newIds: {for (final row in ids) row['id'] as String},
      );
    });
  }

  Future<void> record(
    CategoryChangeKey key,
    Iterable<CatalogItemIdentity> items, {
    required bool refresh,
  }) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.execute(
        'CREATE TEMP TABLE IF NOT EXISTS update_stage '
        '(id TEXT PRIMARY KEY, category TEXT NOT NULL) WITHOUT ROWID',
      );
      await txn.delete('update_stage');
      var batch = txn.batch();
      var count = 0;
      for (final item in items) {
        if (item.id.isEmpty) continue;
        batch.insert(
          'update_stage',
          {'id': item.id, 'category': item.categoryId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (++count % 500 == 0) {
          await batch.commit(noResult: true);
          batch = txn.batch();
        }
      }
      await batch.commit(noResult: true);
      if (count == 0) return;

      final args = [key.subscriptionId, key.catalog.index];
      final initialized = (await txn.query('snapshots',
              columns: ['subscription'],
              where: 'subscription = ? AND catalog = ?',
              whereArgs: args))
          .isNotEmpty;
      if (initialized && !refresh) {
        final difference = Sqflite.firstIntValue(await txn.rawQuery('''
          SELECT
            (SELECT COUNT(*) FROM baseline WHERE subscription = ? AND catalog = ?)
              != (SELECT COUNT(*) FROM update_stage)
            OR EXISTS (
              SELECT 1 FROM update_stage s LEFT JOIN baseline b
                ON b.subscription = ? AND b.catalog = ? AND b.id = s.id
              WHERE b.id IS NULL OR b.category != s.category
            )
        ''', [...args, ...args]));
        if (difference == 0) {
          await txn.delete('update_stage');
          return;
        }
      }

      await txn.delete('new_items',
          where: 'subscription = ? AND catalog = ?', whereArgs: args);
      if (initialized) {
        await txn.rawInsert('''
          INSERT INTO new_items(subscription, catalog, id, category)
          SELECT ?, ?, s.id, s.category FROM update_stage s
          WHERE NOT EXISTS (
            SELECT 1 FROM baseline b
            WHERE b.subscription = ? AND b.catalog = ? AND b.id = s.id
          )
        ''', [...args, ...args]);
      }
      await txn.delete('baseline',
          where: 'subscription = ? AND catalog = ?', whereArgs: args);
      await txn.rawInsert('''
        INSERT INTO baseline(subscription, catalog, id, category)
        SELECT ?, ?, id, category FROM update_stage
      ''', args);
      await txn.insert(
        'snapshots',
        {'subscription': key.subscriptionId, 'catalog': key.catalog.index},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.delete('update_stage');
    });
  }

  @visibleForTesting
  Future<void> close() async {
    if (_opening != null) await (await _opening!).close();
  }
}
