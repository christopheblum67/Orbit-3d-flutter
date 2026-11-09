import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Cache de réponses complètes uniquement. L'appelant doit vérifier le statut
/// HTTP, les directives Cache-Control et les en-têtes Vary avant l'insertion.
class VideoDiskCache {
  VideoDiskCache(this.directory, {this.maxBytes = 512 * 1024 * 1024})
      : assert(maxBytes >= 0);

  final Directory directory;
  final int maxBytes;
  Future<void> _tail = Future<void>.value();
  int _generation = 0;

  int get generation => _generation;

  String _name(String key) => sha256.convert(utf8.encode(key)).toString();

  Future<T> _exclusive<T>(Future<T> Function() work) {
    final previous = _tail;
    final release = Completer<void>();
    _tail = release.future;
    return () async {
      await previous;
      try {
        return await work();
      } finally {
        release.complete();
      }
    }();
  }

  Future<void> initialize({bool discardExisting = false}) =>
      _exclusive(() async {
        await directory.create(recursive: true);
        await for (final entity in directory.list(followLinks: false)) {
          if (entity is File &&
              _isCacheFile(entity) &&
              (discardExisting ||
                  p.basename(entity.path).endsWith('.partial'))) {
            await entity.delete();
          }
        }
        await _evictUntil(0);
      });

  /// Retire uniquement les entrées appartenant à la session concernée.
  Future<void> removeEntries(Iterable<String> keys) {
    final names = keys.map(_name).toSet();
    return _exclusive(() async {
      for (final name in names) {
        final file = File(p.join(directory.path, '$name.cache'));
        if (await file.exists()) await file.delete();
      }
    });
  }

  /// Publie atomiquement une réponse intégrale de taille connue.
  /// Une réponse 206 ou tronquée ne doit jamais être passée comme complète.
  Future<bool> store(
    String key,
    Stream<List<int>> data, {
    required int contentLength,
    int? expectedGeneration,
  }) =>
      _exclusive(() async {
        if ((expectedGeneration != null && expectedGeneration != _generation) ||
            contentLength < 0 ||
            contentLength > maxBytes ||
            maxBytes == 0) {
          return false;
        }
        await directory.create(recursive: true);
        final name = _name(key);
        final temporary = File(p.join(directory.path, '$name.partial'));
        final target = File(p.join(directory.path, '$name.cache'));
        var written = 0;
        try {
          await _evictUntil(contentLength);
          final file = await temporary.open(mode: FileMode.write);
          try {
            await for (final chunk in data) {
              written += chunk.length;
              if (written > contentLength) {
                throw const FormatException('Réponse plus longue que prévu');
              }
              await file.writeFrom(chunk);
            }
            if (written != contentLength) {
              throw const FormatException('Réponse tronquée');
            }
            await file.flush();
          } finally {
            await file.close();
          }
          if (await target.exists()) await target.delete();
          await temporary.rename(target.path);
          return true;
        } finally {
          if (await temporary.exists()) await temporary.delete();
        }
      });

  /// Maintient l'entrée protégée de l'éviction pendant son utilisation.
  Future<T?> withEntry<T>(
    String key,
    Future<T> Function(File file) read,
  ) =>
      _exclusive(() async {
        final file = File(p.join(directory.path, '${_name(key)}.cache'));
        if (!await file.exists()) return null;
        await file.setLastModified(DateTime.now());
        return read(file);
      });

  Future<void> clear() {
    _generation++;
    return _exclusive(() async {
      if (!await directory.exists()) return;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File && _isCacheFile(entity)) await entity.delete();
      }
    });
  }

  bool _isCacheFile(File file) => RegExp(r'^[0-9a-f]{64}\.(cache|partial)$')
      .hasMatch(p.basename(file.path));

  Future<void> _evictUntil(int reserve) async {
    final files = <({File file, FileStat stat})>[];
    var used = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !_isCacheFile(entity)) continue;
      final stat = await entity.stat();
      files.add((file: entity, stat: stat));
      used += stat.size;
    }
    files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    for (final entry in files) {
      if (used + reserve <= maxBytes) break;
      await entry.file.delete();
      used -= entry.stat.size;
    }
  }
}
