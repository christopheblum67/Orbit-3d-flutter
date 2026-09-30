import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Service d'indexation plein-texte SQLite FTS5 pour la recherche unifiée.
///
/// Remplace l'index en mémoire par une base SQLite FTS5 persistante avec :
/// - Table FTS5 `search_index` avec BM25 natif
/// - Persistance across restarts (pas de rebuild au démarrage)
/// - BM25 ranking natif + filtres type/source
/// - Mise à jour incrémentale possible
/// - Support synonymes/accents via tokenizer unicode61
class SearchFtsService {
  SearchFtsService._();
  static final SearchFtsService instance = SearchFtsService._();

  Database? _db;
  bool _initialized = false;

  static const String _dbName = 'orbit_search.db';
  static const int _schemaVersion = 1;

  /// Initialise la base et crée les tables FTS5 si nécessaire.
  Future<void> init() async {
    if (_initialized) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'orbit_search.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Activer WAL pour concurrence lecture/écriture
    await _db!.execute('PRAGMA journal_mode = WAL;');
    await _db!.execute('PRAGMA busy_timeout = 5000;');

    _initialized = true;
    LoggerService.instance.info('SearchFtsService initialisé');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table FTS5 principale avec tokenizer unicode61 (accents, casse insensible)
    await db.execute('''
      CREATE VIRTUAL TABLE search_index USING fts5(
        id UNINDEXED,
        type UNINDEXED,
        source UNINDEXED,
        category_id UNINDEXED,
        title,
        subtitle,
        poster_url UNINDEXED,
        stream_url UNINDEXED,
        category_id_str UNINDEXED,
        original_json UNINDEXED,
        tokenize = "unicode61 remove_diacritics 1"
      );
    ''');

    // Index auxiliaire pour filtres rapides par type/source
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_search_type ON search_index(type);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_search_source ON search_index(source);
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
  }

  /// Vérifie si l'index est prêt.
  bool get isReady => _initialized && _db != null;

  /// Nombre total d'entrées indexées.
  Future<int> get count async {
    if (!isReady) return 0;
    final result = await _db!.rawQuery('SELECT COUNT(*) as c FROM search_index');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Rebuild complet de l'index à partir des catalogues actuels.
  Future<void> rebuild({
    required List<Movie> movies,
    required List<Series> series,
    required List<Channel> channels,
  }) async {
    if (!isReady) await init();

    final batch = _db!.batch();

    // Vider l'index
    batch.delete('search_index');

    // Films
    for (final m in movies) {
      batch.insert('search_index', _toFtsRow(m));
    }

    // Séries
    for (final s in series) {
      batch.insert('search_index', _toFtsRow(s));
    }

    // Chaînes
    for (final c in channels) {
      batch.insert('search_index', _toFtsRow(c));
    }

    await batch.commit(noResult: true);
    LoggerService.instance.info('SearchFtsService rebuild: ${movies.length} films, ${series.length} séries, ${channels.length} chaînes');
  }

  /// Insère ou met à jour une entrée unique (mise à jour incrémentale).
  Future<void> upsert(Object entry) async {
    if (!isReady) await init();
    await _db!.insert('search_index', _toFtsRow(entry),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Supprime une entrée par ID.
  Future<void> delete(String id, SearchType type) async {
    if (!isReady) return;
    await _db!.delete(
      'search_index',
      where: 'id = ? AND type = ?',
      whereArgs: [id, type.name],
    );
  }

  /// Recherche plein-texte avec BM25 natif + filtres.
  Future<List<SearchFtsHit>> search({
    required String query,
    int limit = 40,
    SearchType? type,
    SearchSource? source,
  }) async {
    if (!isReady) await init();
    if (query.trim().isEmpty) return [];

    // Préparation requête FTS5 : préfixes + AND implicite
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '$t*')
        .join(' ');

    final whereClauses = <String>[];
    final whereArgs = <Object>[];

    whereClauses.add('search_index MATCH ?');
    whereArgs.add(terms);

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }
    if (source != null) {
      whereClauses.add('source = ?');
      whereArgs.add(source.name);
    }

    final whereClause = whereClauses.join(' AND ');
    final sql = '''
      SELECT
        id, type, source, category_id,
        title, subtitle, poster_url, stream_url,
        bm25(search_index) as rank
      FROM search_index
      WHERE $whereClause
      ORDER BY rank ASC
      LIMIT ?
    ''';

    whereArgs.add(limit);

    final rows = await _db!.rawQuery(sql, whereArgs);

    return rows.map((r) => SearchFtsHit(
      id: r['id'] as String,
      type: SearchType.values.byName(r['type'] as String),
      source: SearchSource.values.byName(r['source'] as String),
      title: r['title'] as String,
      subtitle: (r['subtitle'] as String?) ?? '',
      posterUrl: (r['poster_url'] as String?) ?? '',
      streamUrl: (r['stream_url'] as String?) ?? '',
      categoryId: (r['category_id'] as String?) ?? '',
      rank: (r['rank'] as num).toDouble(),
    )).toList();
  }

  /// Suggestions d'autocomplétion (prefix match sur titres).
  Future<List<String>> suggestions(String prefix, {int limit = 10}) async {
    if (!isReady) await init();
    if (prefix.trim().length < 2) return [];

    final term = '${prefix.trim()}*';
    final rows = await _db!.rawQuery('''
      SELECT DISTINCT title
      FROM search_index
      WHERE title MATCH ?
      ORDER BY title
      LIMIT ?
    ''', [term, limit]);

    return rows.map((r) => r['title'] as String).toList();
  }

  /// Nettoie l'index (vidage complet).
  Future<void> clear() async {
    if (!isReady) return;
    await _db!.delete('search_index');
  }

  /// Ferme la base.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _initialized = false;
    }
  }

  /// Convertit un objet domaine en ligne FTS5.
  Map<String, Object?> _toFtsRow(dynamic obj) {
    if (obj is Movie) {
      return {
        'id': obj.id,
        'type': SearchType.vod.name,
        'source': SearchSource.xtream.name,
        'category_id': obj.categoryId,
        'title': obj.title,
        'subtitle': _subtitleMovie(obj),
        'poster_url': obj.posterUrl,
        'stream_url': obj.streamUrl,
        'category_id_str': obj.categoryId,
        'original_json': '',
      };
    }
    if (obj is Series) {
      return {
        'id': obj.id,
        'type': SearchType.series.name,
        'source': SearchSource.xtream.name,
        'category_id': obj.categoryId,
        'title': obj.title,
        'subtitle': _subtitleSeries(obj),
        'poster_url': obj.coverUrl,
        'stream_url': '',
        'category_id_str': obj.categoryId,
        'original_json': '',
      };
    }
    if (obj is Channel) {
      return {
        'id': obj.id,
        'type': SearchType.live.name,
        'source': SearchSource.xtream.name,
        'category_id': obj.categoryId,
        'title': obj.name,
        'subtitle': obj.groupLabel,
        'poster_url': obj.logoUrl,
        'stream_url': obj.streamUrl,
        'category_id_str': obj.categoryId,
        'original_json': '',
      };
    }
    throw ArgumentError('Type non supporté: ${obj.runtimeType}');
  }

  String _subtitleMovie(Movie m) {
    final parts = <String>[];
    if (m.year > 0) parts.add(m.year.toString());
    if (m.genre.isNotEmpty) parts.add(m.genre);
    return parts.join(' · ');
  }

  String _subtitleSeries(Series s) {
    final parts = <String>[];
    if (s.year > 0) parts.add(s.year.toString());
    if (s.genre.isNotEmpty) parts.add(s.genre);
    return parts.join(' · ');
  }
}

/// Résultat de recherche FTS5 avec score BM25.
class SearchFtsHit {
  const SearchFtsHit({
    required this.id,
    required this.type,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.posterUrl,
    required this.streamUrl,
    required this.categoryId,
    required this.rank,
  });

  final String id;
  final SearchType type;
  final SearchSource source;
  final String title;
  final String subtitle;
  final String posterUrl;
  final String streamUrl;
  final String categoryId;
  final double rank; // BM25 score (plus bas = meilleur)

  /// Convertit vers SearchItem pour compatibilité UI existante.
  SearchItem toSearchItem() {
    return SearchItem(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      posterUrl: posterUrl,
      streamUrl: streamUrl.isEmpty ? null : streamUrl,
      categoryId: categoryId.isEmpty ? null : categoryId,
      score: 1.0 - (rank / 100).clamp(0.0, 1.0), // conversion BM25 -> score 0..1
      source: source,
      originalObject: null,
    );
  }
}