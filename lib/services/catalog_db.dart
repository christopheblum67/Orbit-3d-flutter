import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Types de catalogue stockés.
enum CatalogKind { vod, series }

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
  CatalogDb._();

  static final CatalogDb instance = CatalogDb._();

  /// Constructeur de test : base et chemin injectés.
  @visibleForTesting
  CatalogDb.forTesting(this._testPath);

  static const String _dbName = 'orbit_catalog.db';
  static const int _schemaVersion = 1;
  static const int _insertChunk = 2000;

  String? _testPath;
  Future<Database?>? _opening;
  bool _failed = false;

  bool get isAvailable => !_failed;

  /// Incrémenté à chaque écriture réussie : les providers qui dépendent de la
  /// base se rafraîchissent quand un nouveau catalogue devient disponible.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Empreinte légère d'un catalogue brut (taille + début + fin + effectif).
  /// Suffit à détecter un catalogue modifié sans hacher des dizaines de Mo.
  static String signatureOf(Uint8List bytes, int itemCount) {
    var hash = 0x811c9dc5;
    void mix(int from, int to) {
      for (var i = from; i < to; i++) {
        hash = ((hash ^ bytes[i]) * 0x01000193) & 0x7fffffff;
      }
    }

    final head = bytes.length < 4096 ? bytes.length : 4096;
    mix(0, head);
    mix(bytes.length - head, bytes.length);
    return '${bytes.length}:$itemCount:$hash';
  }

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
      return await openDatabase(
        path,
        version: _schemaVersion,
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
              stream_id TEXT NOT NULL DEFAULT '',
              ext TEXT NOT NULL DEFAULT '',
              PRIMARY KEY (kind, sub_key, id)
            ) WITHOUT ROWID
          ''');
          await db.execute(
            'CREATE INDEX idx_items_cat ON items(kind, sub_key, category_id)',
          );
          await db.execute(
            'CREATE INDEX idx_items_added ON items(kind, sub_key, added DESC)',
          );
          await db.execute('''
            CREATE TABLE meta (
              kind INTEGER NOT NULL,
              sub_key TEXT NOT NULL,
              signature TEXT NOT NULL,
              count INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (kind, sub_key)
            )
          ''');
        },
      );
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
    };
  }

  Future<void> _replace(
    CatalogKind kind,
    String subKey,
    String signature,
    int total,
    Map<String, Object?> Function(int index) rowAt,
  ) async {
    final db = await _db();
    if (db == null) return;
    try {
      await db.transaction((txn) async {
        await txn.delete(
          'items',
          where: 'kind = ? AND sub_key = ?',
          whereArgs: [kind.index, subKey],
        );
        var i = 0;
        while (i < total) {
          final end = (i + _insertChunk).clamp(0, total);
          final batch = txn.batch();
          for (; i < end; i++) {
            final row = rowAt(i);
            if ((row['id'] as String).isEmpty) continue;
            batch.insert(
              'items',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }
        final stored = Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(*) FROM items WHERE kind = ? AND sub_key = ?',
                [kind.index, subKey],
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
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      revision.value++;
    } catch (e) {
      _failed = true;
      LoggerService.instance.error('CatalogDb écriture : $e', tag: 'db');
    }
  }

  /// Supprime le catalogue d'un abonnement (ou tout si [subKey] est nul).
  Future<void> clear({CatalogKind? kind, String? subKey}) async {
    final db = await _db();
    if (db == null) return;
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
      await db.delete('items', where: clause, whereArgs: args);
      await db.delete('meta', where: clause, whereArgs: args);
    } catch (_) {}
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
  }) async {
    final rows = await _page(
      CatalogKind.vod,
      subKey,
      filter,
      sort,
      limit,
      offset,
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
  }) async {
    final rows = await _page(
      CatalogKind.series,
      subKey,
      filter,
      sort,
      limit,
      offset,
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
  ) async {
    final db = await _db();
    if (db == null) return const [];
    try {
      final q = _where(kind, subKey, filter);
      return await db.rawQuery(
        'SELECT id, title, poster, stream_id, ext, year, genre, rating, '
        'category_id, pegi, added FROM items WHERE ${q.clause} '
        'ORDER BY ${_orderBy(sort)} LIMIT ? OFFSET ?',
        [...q.args, limit, offset],
      );
    } catch (_) {
      return const [];
    }
  }

  static String _orderBy(CatalogSort sort) {
    switch (sort) {
      case CatalogSort.recentlyAdded:
        return 'added DESC, title_key ASC';
      case CatalogSort.recentlyAddedAsc:
        return 'added ASC, title_key ASC';
      case CatalogSort.title:
        return 'title_key ASC';
      case CatalogSort.titleDesc:
        return 'title_key DESC';
      case CatalogSort.rating:
        return 'rating DESC, title_key ASC';
      case CatalogSort.ratingAsc:
        return 'rating ASC, title_key ASC';
      case CatalogSort.year:
        return 'year DESC, title_key ASC';
      case CatalogSort.yearAsc:
        return 'year ASC, title_key ASC';
    }
  }

  static ({String clause, List<Object?> args}) _where(
    CatalogKind kind,
    String subKey,
    CatalogFilter f,
  ) {
    final clause = StringBuffer('kind = ? AND sub_key = ?');
    final args = <Object?>[kind.index, subKey];
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

  static String _escapeLike(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  static int _asInt(Object? v) => v is num ? v.toInt() : 0;

  static DateTime? _date(Object? v) {
    final seconds = _asInt(v);
    return seconds <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
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
