import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:path_provider/path_provider.dart';

/// Cache disque des catalogues Films / Séries (JSON brut du panel).
///
/// `get_vod_streams` pèse ~30 Mo et `get_series` ~44 Mo : sans persistance,
/// chaque lancement retéléchargeait puis reparsait tout (mesuré sur la TV :
/// 10 s + 18 s de réseau). Avec ce cache, un lancement dans la fenêtre de
/// validité ne coûte plus que la lecture du fichier et son parsing, qui se
/// fait hors du thread UI.
///
/// Toute erreur de lecture vaut « pas de cache » : un fichier corrompu coûte un
/// téléchargement, jamais un écran cassé.
class CatalogDiskCache {
  CatalogDiskCache._();

  static final CatalogDiskCache instance = CatalogDiskCache._();

  /// Durée de validité. Un catalogue de panel change à l'échelle de l'heure ou
  /// de la journée ; le rafraîchissement manuel contourne ce délai.
  static const Duration maxAge = Duration(hours: 6);

  String? _dirPath;

  Future<Directory> _dir() async {
    final known = _dirPath;
    if (known != null) return Directory(known);
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/catalog_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dirPath = dir.path;
    return dir;
  }

  /// Nom de fichier dérivé de l'abonnement : deux panels ne partagent jamais
  /// le même catalogue. Le mot de passe n'entre pas dans la clé.
  String fileNameFor(String name, String subscriptionKey) {
    var hash = 0;
    for (final unit in subscriptionKey.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return '${name}_$hash.json';
  }

  /// Octets du catalogue, ou `null` si absent, trop ancien ou illisible.
  Future<Uint8List?> read(
    String name,
    String subscriptionKey, {
    Duration maxAgeLimit = maxAge,
  }) async {
    final result = await safeAsync<Uint8List?>(
      () async {
        final file = File(
          '${(await _dir()).path}/${fileNameFor(name, subscriptionKey)}',
        );
        if (!file.existsSync()) return null;
        final age = DateTime.now().difference(file.lastModifiedSync());
        if (age > maxAgeLimit) return null;
        return file.readAsBytes();
      },
      context: 'CatalogDiskCache.read',
      fallbackValue: null,
    );
    return result.valueOrNull;
  }

  /// 	rue si un catalogue frais existe (sans le lire).
  Future<bool> hasFresh(String name, String subscriptionKey) async {
    final result = await safeAsync<bool>(
      () async {
        final file = File(
          '${(await _dir()).path}/${fileNameFor(name, subscriptionKey)}',
        );
        if (!file.existsSync()) return false;
        return DateTime.now().difference(file.lastModifiedSync()) <= maxAge;
      },
      context: 'CatalogDiskCache.hasFresh',
      fallbackValue: false,
    );
    return result.valueOrNull ?? false;
  }

  /// Écrit le catalogue. Silencieux en cas d'échec (disque plein, etc.).
  Future<void> write(
    String name,
    String subscriptionKey,
    Uint8List bytes,
  ) async {
    await safeAsync<void>(
      () async {
        final file = File(
          '${(await _dir()).path}/${fileNameFor(name, subscriptionKey)}',
        );
        await file.writeAsBytes(bytes, flush: true);
      },
      context: 'CatalogDiskCache.write',
    );
  }

  /// Supprime les catalogues en cache (changement d'abonnement, purge).
  Future<void> clear() async {
    await safeAsync<void>(
      () async {
        final dir = await _dir();
        if (dir.existsSync()) {
          for (final f in dir.listSync()) {
            if (f is File) f.deleteSync();
          }
        }
      },
      context: 'CatalogDiskCache.clear',
    );
  }
}

/// Entrée du parsing des films, exécuté dans un isolate.
class MoviesParseInput {
  const MoviesParseInput(this.bytes, this.categoryNames);

  final Uint8List bytes;
  final Map<String, String> categoryNames;
}

/// Résultat d'un parsing : la liste et le nombre d'entrées ignorées.
class CatalogParseResult<T> {
  const CatalogParseResult(
    this.items,
    this.ignored,
    this.firstError, [
    this.decodeMs = 0,
    this.buildMs = 0,
  ]);

  final List<T> items;
  final int ignored;
  final String? firstError;
  final int decodeMs;
  final int buildMs;
}

dynamic _decodeCatalogJson(Uint8List bytes) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return jsonDecode(latin1.decode(bytes));
  }
}

/// Parse `get_vod_streams` hors du thread UI (à passer à `compute`).
///
/// Ne dépend d'aucun état global : le constructeur d'URL de stream n'existe pas
/// dans l'isolate, la validité d'un film se réduit donc à la présence de son
/// identifiant de flux.
CatalogParseResult<Movie> parseMoviesPayload(MoviesParseInput input) {
  final sw = Stopwatch()..start();
  final raw = _decodeCatalogJson(input.bytes);
  final decodeMs = sw.elapsedMilliseconds;
  if (raw is! List) {
    throw FormatException('Réponse VOD illisible (type ${raw.runtimeType}).');
  }
  final out = <Movie>[];
  var ignored = 0;
  String? firstError;
  for (final e in raw) {
    if (e is! Map) {
      ignored++;
      continue;
    }
    try {
      final map = Map<String, dynamic>.from(e);
      _enrichMovieMap(map, input.categoryNames);
      final movie = Movie.fromMap(map);
      if (movie.streamId.isEmpty) {
        ignored++;
        continue;
      }
      out.add(movie);
    } catch (err) {
      firstError ??= '${err.runtimeType} -> $err';
      ignored++;
    }
  }
  return CatalogParseResult<Movie>(
    out,
    ignored,
    firstError,
    decodeMs,
    sw.elapsedMilliseconds - decodeMs,
  );
}

/// Parse `get_series` hors du thread UI (à passer à `compute`).
CatalogParseResult<Series> parseSeriesPayload(Uint8List bytes) {
  final sw = Stopwatch()..start();
  final raw = _decodeCatalogJson(bytes);
  final decodeMs = sw.elapsedMilliseconds;
  if (raw is! List) {
    throw FormatException(
        'Réponse séries illisible (type ${raw.runtimeType}).');
  }
  final out = <Series>[];
  var ignored = 0;
  String? firstError;
  for (final e in raw) {
    if (e is! Map) {
      ignored++;
      continue;
    }
    try {
      out.add(Series.fromMap(Map<String, dynamic>.from(e)));
    } catch (err) {
      firstError ??= '${err.runtimeType} -> $err';
      ignored++;
    }
  }
  return CatalogParseResult<Series>(
    out,
    ignored,
    firstError,
    decodeMs,
    sw.elapsedMilliseconds - decodeMs,
  );
}

/// Genre manquant ← nom de catégorie, année manquante ← date d'ajout.
void _enrichMovieMap(Map<String, dynamic> map, Map<String, String> names) {
  final genre = (map['genre']?.toString() ?? '').trim();
  if (genre.isEmpty) {
    final catName = names[map['category_id']?.toString() ?? ''];
    if (catName != null && catName.trim().isNotEmpty) {
      map['genre'] = catName.trim();
    }
  }
  final year = map['year'];
  if ((year == null || year == 0 || '$year' == '0') && map['added'] != null) {
    final added = map['added'];
    if (added is num) {
      map['year'] =
          DateTime.fromMillisecondsSinceEpoch(added.toInt() * 1000).year;
    }
  }
}

/// Lance le parsing dans un isolate (visible pour les tests).
Future<CatalogParseResult<Movie>> parseMoviesInBackground(
  MoviesParseInput input,
) =>
    compute(parseMoviesPayload, input);

Future<CatalogParseResult<Series>> parseSeriesInBackground(Uint8List bytes) =>
    compute(parseSeriesPayload, bytes);
