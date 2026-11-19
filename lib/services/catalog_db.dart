import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Types de catalogue stockés.
enum CatalogKind { vod, series }

String _catalogSignature(({Uint8List bytes, int itemCount}) input) =>
    CatalogDb.signatureOf(input.bytes, input.itemCount);

/// Ordres de tri exécutés par SQLite.
enum CatalogSort {
  recentlyAdded,
  recentlyAddedAsc,
  title,
  titleDesc,
  rating,
  ratingAsc,
  year,
  yearAsc,
}

/// Catalogue Films / Séries dans SQLite (champs de navigation uniquement).
///
/// Les ~100 000 titres ne sont plus tous gardés en mémoire pour la navigation :
/// les écrans interrogent une page à la fois (catégorie, recherche, tri), sans
/// refiltrer toute la liste à chaque frappe. Le détail complet (description,
/// casting, URL) reste chargé à la demande.
///
/// Toute erreur (plateforme sans sqflite, disque plein, base corrompue) vaut
/// « base indisponible » : [isAvailable] devient faux et l'appelant retombe sur
/// le chemin en mémoire. Aucune exception ne remonte.
class CatalogDb {
  CatalogDb._() : afterBatchForTesting = null;

  static final CatalogDb instance = CatalogDb._();

  /// Constructeur de test : base et chemin injectés.
  @visibleForTesting
  CatalogDb.forTesting(this._testPath, {this.afterBatchForTesting});

  static const String _dbName = 'orbit_catalog.db';
  static const int _schemaVersion = 4;
  static const int _insertChunk = 500;
  static int _nextGeneration = 0;

  String? _testPath;
  final Future<void> Function()? afterBatchForTesting;
  Future<void> _writeTail = Future<void>.value();
  Future<Database?>? _opening;
  bool _failed = false;

  bool get isAvailable => !_failed;

  /// Incrémenté à chaque écriture réussie : les providers qui dépendent de la
  /// base se rafraîchissent quand un nouveau catalogue devient disponible.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Empreinte du catalogue complet, différente de l'ancien format échantillonné.
  static String signatureOf(Uint8List bytes, int itemCount) {
    return 'sha256:${sha256.convert(bytes)}:$itemCount';
  }

  static Future<String> signatureInBackground(Uint8List bytes, int itemCount) =>
      compute(_catalogSignature, (bytes: bytes, itemCount: itemCount));

  /// Réécrit les films seulement si le contenu source a changé.
  Future<void> syncMovies(
    String subKey,
    String signature,
    List<Movie> movies,
  ) async {
    if (await isCurrent(CatalogKind.vod, subKey, signature)) return;
    await replaceMovies(subKey, signature, movies);
  }

  /// Réécrit les séries seulement si le contenu source a changé.
  Future<void> syncSeries(
    String subKey,
    String signature,
    List<Series> series,
  ) async {
    if (await isCurrent(CatalogKind.series, subKey, signature)) return;
    await replaceSeries(subKey, signature, series);
  }

  Future<Database?> _db() {
    return _opening ??= _open();
  }

  Future<Database?> _open() async {
    try {
      final path = _testPath ?? p.join(await getDatabasesPath(), _dbName);
      final db = await openDatabase(
        path,
        version: _schemaVersion,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        },
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE items (
              kind INTEGER NOT NULL,
              sub_key TEXT NOT NULL,
              id TEXT NOT NULL,
              title TEXT NOT NULL,
              title_key TEXT NOT NULL,
              search_key TEXT NOT NULL,
              poster TEXT NOT NULL,
              year INTEGER NOT NULL,
              genre TEXT NOT NULL,
              rating REAL NOT NULL,
              category_id TEXT NOT NULL,
              pegi TEXT,
              added INTEGER NOT NULL,
              sort_added INTEGER NOT NULL,
              stream_id TEXT NOT NULL DEFAULT '',
              ext TEXT NOT NULL DEFAULT '',
              PRIMARY KEY (kind, sub_key, id)
            ) WITHOUT ROWID
          ''');
          await db.execute(
            'CREATE INDEX idx_items_cat ON items(kind, sub_key, category_id)',
          );
          await db.execute(
            'CREATE INDEX idx_items_added ON items(kind, sub_key, sort_added DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_items_title ON items(kind, sub_key, title_key)',
          );
          await db.execute(
            'CREATE INDEX idx_items_cat_title ON items(kind, sub_key, category_id, title_key, id)',
          );
          await db.execute('''
            CREATE TABLE meta (
              kind INTEGER NOT NULL,
              sub_key TEXT NOT NULL,
              signature TEXT NOT NULL,
              count INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              data_key TEXT,
              PRIMARY KEY (kind, sub_key)
            )
          ''');
          await db.execute('''
            CREATE TABLE pending_cleanup (
              kind INTEGER NOT NULL,
              data_key TEXT NOT NULL,
              PRIMARY KEY (kind, data_key)
            ) WITHOUT ROWID
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE meta ADD COLUMN data_key TEXT');
            await db.execute(
              'CREATE INDEX idx_items_title ON items(kind, sub_key, title_key)',
            );
            await db.execute('''
              CREATE TABLE pending_cleanup (
                kind INTEGER NOT NULL,
                data_key TEXT NOT NULL,
                PRIMARY KEY (kind, data_key)
              ) WITHOUT ROWID
            ''');
          }
          if (oldVersion < 3) {
            await db.execute(
              'CREATE INDEX idx_items_cat_title ON items(kind, sub_key, category_id, title_key, id)',
            );
          }
          if (oldVersion < 4) {
            await db.execute(
              'ALTER TABLE items ADD COLUMN sort_added INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute('UPDATE items SET sort_added = added');
            await db.execute('DROP INDEX IF EXISTS idx_items_added');
            await db.execute(
              'CREATE INDEX idx_items_added ON items(kind, sub_key, sort_added DESC)',
            );
          }
        },
      );
      unawaited(_cleanupPending(db));
      return db;
    } catch (e) {
      _failed = true;
      LoggerService.instance.error('CatalogDb indisponible : $e', tag: 'db');
      return null;
    }
  }

  /// Vrai si le catalogue stocké correspond déjà à [signature] (même contenu
  /// source) : inutile de le réécrire.
  Future<bool> isCurrent(
    CatalogKind kind,
    String subKey,
    String signature,
  ) async {
    final db = await _db();
    if (db == null) return false;
    try {
      final rows = await db.query(
        'meta',
        where: 'kind = ? AND sub_key = ?',
        whereArgs: [kind.index, subKey],
      );
      if (rows.isEmpty) return false;
      return rows.first['signature'] == signature &&
          _asInt(rows.first['count']) > 0;
    } catch (_) {
      return false;
    }
  }

  /// Vrai si un catalogue non vide est stocké pour cet abonnement.
  Future<bool> hasData(CatalogKind kind, String subKey) async {
    final db = await _db();
    if (db == null) return false;
    try {
      final rows = await db.query(
        'meta',
        columns: ['count'],
        where: 'kind = ? AND sub_key = ?',
        whereArgs: [kind.index, subKey],
      );
      return rows.isNotEmpty && _asInt(rows.first['count']) > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> replaceMovies(
    String subKey,
    String signature,
    List<Movie> movies,
  ) {
    return _replace(
      CatalogKind.vod,
      subKey,
      signature,
      movies.length,
      (i) {
        final m = movies[i];
        return _row(
          CatalogKind.vod,
          subKey,
          id: m.id,
          title: m.title,
          genre: m.genre,
          poster: m.posterUrl,
          year: m.year,
          rating: m.rating,
          categoryId: m.categoryId,
          pegi: m.pegi,
          added: m.addedDate,
          streamId: m.streamId,
          ext: m.containerExtension,
        );
      },
    );
  }

  Future<void> replaceSeries(
    String subKey,
    String signature,
    List<Series> series,
  ) {
    return _replace(
      CatalogKind.series,
      subKey,
      signature,
      series.length,
      (i) {
        final s = series[i];
        return _row(
          CatalogKind.series,
          subKey,
          id: s.id,
          title: s.title,
          genre: s.genre,
          poster: s.coverUrl,
          year: s.year,
          rating: s.rating,
          categoryId: s.categoryId,
          pegi: s.pegi,
          added: s.addedDate,
          sortAdded: s.catalogSortDate,
        );
      },
    );
  }

  Map<String, Object?> _row(
    CatalogKind kind,
    String subKey, {
    required String id,
    required String title,
    required String genre,
    required String poster,
    required int year,
    required double rating,
    required String categoryId,
    required String? pegi,
    required DateTime? added,
    DateTime? sortAdded,
    String streamId = '',
    String ext = '',
  }) {
    final lowerTitle = title.toLowerCase();
    return {
      'kind': kind.index,
      'sub_key': subKey,
      'id': id,
      'title': title,
      'title_key': lowerTitle,
      'search_key': '$lowerTitle\u0001${genre.toLowerCase()}',
      'poster': poster,
      'stream_id': streamId,
      'ext': ext,
      'year': year,
      'genre': genre,
      'rating': rating,
      'category_id': categoryId,
      'pegi': pegi,
      'added': added == null ? 0 : added.millisecondsSinceEpoch ~/ 1000,
      'sort_added': ((sortAdded ?? added)?.millisecondsSinceEpoch ?? 0) ~/ 1000,
    };
  }

  Future<void> _replace(
    CatalogKind kind,
    String subKey,
    String signature,
    int total,
    Map<String, Object?> Function(int index) rowAt,
  ) async {
    final previousWrite = _writeTail;
    final finished = Completer<void>();
    _writeTail = finished.future;
    await previousWrite;
    final db = await _db();
    if (db == null) {
      finished.complete();
      return;
    }
    final stageKey =
        'orbit-stage:${DateTime.now().microsecondsSinceEpoch}:${_nextGeneration++}';
    var published = false;
    try {
      await db.insert('pending_cleanup', {
        'kind': kind.index,
        'data_key': stageKey,
      });
      var i = 0;
      while (i < total) {
        await db.transaction((txn) async {
          final end = (i + _insertChunk).clamp(0, total);
          final batch = txn.batch();
          for (; i < end; i++) {
            final row = rowAt(i);
            if ((row['id'] as String).isEmpty) continue;
            row['sub_key'] = stageKey;
            batch.insert(
              'items',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        });
        await afterBatchForTesting?.call();
        await Future<void>.delayed(Duration.zero);
      }
      String? oldKey;
      await db.transaction((txn) async {
        final old = await txn.query(
          'meta',
          columns: ['data_key'],
          where: 'kind = ? AND sub_key = ?',
          whereArgs: [kind.index, subKey],
        );
        if (old.isNotEmpty) {
          oldKey = old.first['data_key'] as String? ?? subKey;
          await txn.insert(
            'pending_cleanup',
            {'kind': kind.index, 'data_key': oldKey},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        final stored = Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(*) FROM items WHERE kind = ? AND sub_key = ?',
                [kind.index, stageKey],
              ),
            ) ??
            0;
        await txn.insert(
          'meta',
          {
            'kind': kind.index,
            'sub_key': subKey,
            'signature': signature,
            'count': stored,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
            'data_key': stageKey,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.delete(
          'pending_cleanup',
          where: 'kind = ? AND data_key = ?',
          whereArgs: [kind.index, stageKey],
        );
      });
      published = true;
      revision.value++;
      if (oldKey != null && oldKey != stageKey) {
        await _deleteRowsInBatches(db, kind, oldKey!);
        await db.delete(
          'pending_cleanup',
          where: 'kind = ? AND data_key = ?',
          whereArgs: [kind.index, oldKey],
        );
      }
    } catch (e) {
      _failed = true;
      LoggerService.instance.error('CatalogDb écriture : $e', tag: 'db');
      if (!published) {
        try {
          await _deleteRowsInBatches(db, kind, stageKey);
          await db.delete(
            'pending_cleanup',
            where: 'kind = ? AND data_key = ?',
            whereArgs: [kind.index, stageKey],
          );
        } catch (cleanupError) {
          LoggerService.instance.error(
            'CatalogDb nettoyage : $cleanupError',
            tag: 'db',
          );
        }
      }
    } finally {
      finished.complete();
    }
  }

  Future<void> _cleanupPending(Database db) async {
    final previousWrite = _writeTail;
    final finished = Completer<void>();
    _writeTail = finished.future;
    await previousWrite;
    try {
      final pending = await db.query('pending_cleanup');
      for (final entry in pending) {
        final kind = CatalogKind.values[_asInt(entry['kind'])];
        final key = entry['data_key'] as String;
        await _deleteRowsInBatches(db, kind, key);
        await db.delete(
          'pending_cleanup',
          where: 'kind = ? AND data_key = ?',
          whereArgs: [kind.index, key],
        );
      }
    } catch (error) {
      LoggerService.instance.error(
        'CatalogDb nettoyage différé : $error',
        tag: 'db',
      );
    } finally {
      finished.complete();
    }
  }

  Future<void> _deleteRowsInBatches(
    Database db,
    CatalogKind kind,
    String key,
  ) async {
    int deleted;
    do {
      deleted = await db.rawDelete(
        'DELETE FROM items WHERE kind = ? AND sub_key = ? AND id IN '
        '(SELECT id FROM items WHERE kind = ? AND sub_key = ? LIMIT ?)',
        [kind.index, key, kind.index, key, _insertChunk],
      );
      await Future<void>.delayed(Duration.zero);
    } while (deleted == _insertChunk);
  }

  /// Supprime le catalogue d'un abonnement (ou tout si [subKey] est nul).
  Future<void> clear({CatalogKind? kind, String? subKey}) async {
    final previousWrite = _writeTail;
    final finished = Completer<void>();
    _writeTail = finished.future;
    await previousWrite;
    final db = await _db();
    if (db == null) {
      finished.complete();
      return;
    }
    try {
      final where = <String>[];
      final args = <Object>[];
      if (kind != null) {
        where.add('kind = ?');
        args.add(kind.index);
      }
      if (subKey != null) {
        where.add('sub_key = ?');
        args.add(subKey);
      }
      final clause = where.isEmpty ? null : where.join(' AND ');
      final metadata = await db.transaction((txn) async {
        final rows = await txn.query(
          'meta',
          columns: ['kind', 'sub_key', 'data_key'],
          where: clause,
          whereArgs: args,
        );
        for (final entry in rows) {
          await txn.insert(
            'pending_cleanup',
            {
              'kind': entry['kind'],
              'data_key': entry['data_key'] ?? entry['sub_key'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await txn.delete('meta', where: clause, whereArgs: args);
        return rows;
      });
      if (metadata.isNotEmpty) revision.value++;
      for (final entry in metadata) {
        final key = entry['data_key'] as String? ?? entry['sub_key'] as String;
        await _deleteRowsInBatches(
          db,
          CatalogKind.values[_asInt(entry['kind'])],
          key,
        );
        await db.delete(
          'pending_cleanup',
          where: 'kind = ? AND data_key = ?',
          whereArgs: [entry['kind'], key],
        );
      }
    } catch (error) {
      LoggerService.instance.error('CatalogDb suppression : $error', tag: 'db');
    } finally {
      finished.complete();
    }
  }

  /// Nombre d'éléments correspondant au filtre.
  Future<int> count(
    CatalogKind kind,
    String subKey, {
    CatalogFilter filter = const CatalogFilter(),
  }) async {
    final db = await _db();
    if (db == null) return 0;
    try {
      final q = _where(kind, subKey, filter);
      return Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM items WHERE ${q.clause}',
              q.args,
            ),
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  /// Effectifs par catégorie (hors catégories masquées).
  Future<Map<String, int>> categoryCounts(
    CatalogKind kind,
    String subKey, {
    Set<String> hiddenCategories = const {},
  }) async {
    final db = await _db();
    if (db == null) return const {};
    try {
      final q = _where(
        kind,
        subKey,
        CatalogFilter(hiddenCategories: hiddenCategories),
      );
      final rows = await db.rawQuery(
        'SELECT category_id, COUNT(*) AS c FROM items WHERE ${q.clause} '
        'GROUP BY category_id',
        q.args,
      );
      return {
        for (final r in rows)
          if ((r['category_id'] as String).isNotEmpty)
            r['category_id'] as String: _asInt(r['c']),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<List<Movie>> queryMovies(
    String subKey, {
    CatalogFilter filter = const CatalogFilter(),
    CatalogSort sort = CatalogSort.recentlyAdded,
    int limit = 120,
    int offset = 0,
    CatalogCursor? after,
  }) async {
    final rows = await _page(
      CatalogKind.vod,
      subKey,
      filter,
      sort,
      limit,
      offset,
      after,
    );
    return [
      for (final r in rows)
        Movie(
          id: r['id'] as String,
          title: r['title'] as String,
          description: '',
          posterUrl: r['poster'] as String,
          year: _asInt(r['year']),
          genre: r['genre'] as String,
          director: '',
          rating: (r['rating'] as num).toDouble(),
          pegi: (r['pegi'] as String?) ?? '',
          streamId: r['stream_id'] as String,
          containerExtension: r['ext'] as String,
          categoryId: r['category_id'] as String,
          addedDate: _date(r['added']),
        ),
    ];
  }

  Future<List<Series>> querySeries(
    String subKey, {
    CatalogFilter filter = const CatalogFilter(),
    CatalogSort sort = CatalogSort.recentlyAdded,
    int limit = 120,
    int offset = 0,
    CatalogCursor? after,
  }) async {
    final rows = await _page(
      CatalogKind.series,
      subKey,
      filter,
      sort,
      limit,
      offset,
      after,
    );
    return [
      for (final r in rows)
        Series(
          id: r['id'] as String,
          title: r['title'] as String,
          description: '',
          coverUrl: r['poster'] as String,
          year: _asInt(r['year']),
          genre: r['genre'] as String,
          director: '',
          rating: (r['rating'] as num).toDouble(),
          pegi: (r['pegi'] as String?) ?? '',
          episodes: const [],
          categoryId: r['category_id'] as String,
          addedDate: _date(r['added']),
          lastModifiedDate:
              _date(r['added']) == null ? _date(r['sort_added']) : null,
        ),
    ];
  }

  Future<List<Map<String, Object?>>> _page(
    CatalogKind kind,
    String subKey,
    CatalogFilter filter,
    CatalogSort sort,
    int limit,
    int offset,
    CatalogCursor? after,
  ) async {
    final db = await _db();
    if (db == null) return const [];
    final stopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    try {
      final q = _where(kind, subKey, filter);
      final cursor = after == null ? null : _after(sort, after);
      return await db.rawQuery(
        'SELECT id, title, poster, stream_id, ext, year, genre, rating, '
        'category_id, pegi, added, sort_added FROM items WHERE ${q.clause} '
        '${cursor == null ? '' : 'AND ${cursor.clause} '}'
        'ORDER BY ${_orderBy(sort)} LIMIT ? OFFSET ?',
        [...q.args, ...?cursor?.args, limit, after == null ? offset : 0],
      );
    } catch (error) {
      LoggerService.instance.error(
        'CatalogDb : lecture de page impossible (${error.runtimeType})',
        tag: 'db',
      );
      return const [];
    } finally {
      if (stopwatch != null) {
        debugPrint(
          'CATALOG_PAGE kind=${kind.name} sort=${sort.name} '
          'cursor=${after != null} durationUs=${stopwatch.elapsedMicroseconds}',
        );
      }
    }
  }

  static ({String clause, List<Object> args}) _after(
    CatalogSort sort,
    CatalogCursor cursor,
  ) {
    final title = cursor.title.toLowerCase();
    if (sort == CatalogSort.title) {
      return (
        clause: '(title_key >= ? AND '
            '(title_key > ? OR (title_key = ? AND id > ?)))',
        args: [title, title, title, cursor.id],
      );
    }
    if (sort == CatalogSort.titleDesc) {
      return (
        clause: '(title_key <= ? AND '
            '(title_key < ? OR (title_key = ? AND id > ?)))',
        args: [title, title, title, cursor.id],
      );
    }
    final (column, value, descending) = switch (sort) {
      CatalogSort.recentlyAdded => ('sort_added', cursor.added, true),
      CatalogSort.recentlyAddedAsc => ('sort_added', cursor.added, false),
      CatalogSort.rating => ('rating', cursor.rating, true),
      CatalogSort.ratingAsc => ('rating', cursor.rating, false),
      CatalogSort.year => ('year', cursor.year, true),
      CatalogSort.yearAsc => ('year', cursor.year, false),
      _ => throw StateError('Tri incompatible avec le curseur'),
    };
    final operator = descending ? '<' : '>';
    return (
      clause: '($column $operator= ? AND ($column $operator ? OR '
          '($column = ? AND (title_key > ? OR '
          '(title_key = ? AND id > ?)))))',
      args: [value, value, value, title, title, cursor.id],
    );
  }

  static String _orderBy(CatalogSort sort) {
    switch (sort) {
      case CatalogSort.recentlyAdded:
        return 'sort_added DESC, title_key ASC, id ASC';
      case CatalogSort.recentlyAddedAsc:
        return 'sort_added ASC, title_key ASC, id ASC';
      case CatalogSort.title:
        return 'title_key ASC, id ASC';
      case CatalogSort.titleDesc:
        return 'title_key DESC, id ASC';
      case CatalogSort.rating:
        return 'rating DESC, title_key ASC, id ASC';
      case CatalogSort.ratingAsc:
        return 'rating ASC, title_key ASC, id ASC';
      case CatalogSort.year:
        return 'year DESC, title_key ASC, id ASC';
      case CatalogSort.yearAsc:
        return 'year ASC, title_key ASC, id ASC';
    }
  }

  static ({String clause, List<Object?> args}) _where(
    CatalogKind kind,
    String subKey,
    CatalogFilter f,
  ) {
    final clause = StringBuffer(
      'kind = ? AND sub_key = '
      '(SELECT COALESCE(data_key, sub_key) FROM meta WHERE kind = ? AND sub_key = ?)',
    );
    final args = <Object?>[kind.index, kind.index, subKey];
    if (f.categoryId.isNotEmpty) {
      clause.write(' AND category_id = ?');
      args.add(f.categoryId);
    }
    if (f.hiddenCategories.isNotEmpty) {
      clause.write(
        ' AND category_id NOT IN (${List.filled(f.hiddenCategories.length, '?').join(',')})',
      );
      args.addAll(f.hiddenCategories);
    }
    final ids = f.onlyIds;
    if (ids != null) {
      if (ids.isEmpty) {
        clause.write(' AND 0');
      } else {
        clause.write(' AND id IN (${List.filled(ids.length, '?').join(',')})');
        args.addAll(ids);
      }
    }
    final q = f.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      clause.write(" AND search_key LIKE ? ESCAPE '\\'");
      args.add('%${_escapeLike(q)}%');
    }
    return (clause: clause.toString(), args: args);
  }

  static String _escapeLike(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');

  static int _asInt(Object? v) => v is num ? v.toInt() : 0;

  static DateTime? _date(Object? v) {
    final seconds = _asInt(v);
    return seconds <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}

/// Dernière entrée affichée, avec les clés de tri et de départage SQLite.
class CatalogCursor {
  const CatalogCursor({
    required this.id,
    required this.title,
    required this.added,
    required this.rating,
    required this.year,
  });

  factory CatalogCursor.fromMovie(Movie movie) => CatalogCursor(
        id: movie.id,
        title: movie.title,
        added: (movie.addedDate?.millisecondsSinceEpoch ?? 0) ~/ 1000,
        rating: movie.rating,
        year: movie.year,
      );

  factory CatalogCursor.fromSeries(Series series) => CatalogCursor(
        id: series.id,
        title: series.title,
        added: (series.catalogSortDate?.millisecondsSinceEpoch ?? 0) ~/ 1000,
        rating: series.rating,
        year: series.year,
      );

  final String id;
  final String title;
  final int added;
  final double rating;
  final int year;
}

/// Filtre commun aux requêtes de catalogue.
class CatalogFilter {
  const CatalogFilter({
    this.categoryId = '',
    this.hiddenCategories = const {},
    this.onlyIds,
    this.query = '',
  });

  /// Catégorie serveur (vide = toutes).
  final String categoryId;

  final Set<String> hiddenCategories;

  /// Restreint à ces identifiants (favoris, récents). `null` = pas de limite.
  final Set<String>? onlyIds;

  /// Recherche sur titre et genre (insensible à la casse).
  final String query;
}
