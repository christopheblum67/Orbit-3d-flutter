import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:path_provider/path_provider.dart';

class CatalogHttpValidators {
  CatalogHttpValidators({Future<Directory> Function()? directory})
      : _directory = directory ?? _defaultDirectory;

  static final instance = CatalogHttpValidators();
  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}catalog_validators');
  }

  Future<File> _file(String resource) async {
    final dir = await _directory();
    final key = sha256.convert(utf8.encode(resource));
    return File('${dir.path}${Platform.pathSeparator}$key.json');
  }

  Future<void> clear() async {
    final dir = await _directory();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        await entity.delete();
      }
    }
  }

  Future<Map<String, String>> headers(String resource, Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return {};
    try {
      final file = await _file(resource);
      if (!await file.exists()) return {};
      final value = jsonDecode(await file.readAsString());
      if (value is! Map || value['digest'] is! String) {
        return {};
      }
      if (!await compute(
          _isValidCachedCatalog, (bytes, value['digest'] as String))) {
        return {};
      }
      final etag = value['etag'];
      final modified = value['lastModified'];
      if (etag is String && etag.isNotEmpty) return {'If-None-Match': etag};
      if (modified is String && modified.isNotEmpty) {
        return {'If-Modified-Since': modified};
      }
    } on FileSystemException catch (error) {
      logDiag('Catalogue validators read failed: ${error.runtimeType}');
    } on FormatException catch (error) {
      logDiag('Catalogue validators invalid: ${error.runtimeType}');
    }
    return {};
  }

  Future<void> save(
    String resource,
    Uint8List bytes, {
    String? etag,
    String? lastModified,
    String? cacheControl,
    String? vary,
  }) async {
    try {
      final file = await _file(resource);
      final noStore = (cacheControl ?? '')
          .toLowerCase()
          .split(',')
          .any((part) => part.trim() == 'no-store');
      if (noStore ||
          (vary?.trim().isNotEmpty ?? false) ||
          ((etag?.isEmpty ?? true) && (lastModified?.isEmpty ?? true))) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'digest': await compute(_digest, bytes),
          'etag': etag,
          'lastModified': lastModified,
        }),
        flush: true,
      );
    } on FileSystemException catch (error) {
      logDiag('Catalogue validators write failed: ${error.runtimeType}');
    }
  }
}

String _digest(Uint8List bytes) => sha256.convert(bytes).toString();

bool _isValidCachedCatalog((Uint8List, String) input) {
  final (bytes, digest) = input;
  if (_digest(bytes) != digest) return false;
  try {
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      content = latin1.decode(bytes);
    }
    return jsonDecode(content) is List;
  } on FormatException {
    return false;
  }
}
