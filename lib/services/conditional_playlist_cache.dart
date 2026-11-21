import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:path_provider/path_provider.dart';

String _decodeCachedBody((Uint8List, String?) input) {
  final (bytes, digest) = input;
  if (sha256.convert(bytes).toString() != digest) {
    throw const FormatException('Invalid playlist cache digest');
  }
  return utf8.decode(bytes);
}

(List<int>, String) _encodeCachedBody(String body) {
  final bytes = utf8.encode(body);
  return (bytes, sha256.convert(bytes).toString());
}

class PlaylistResponse {
  const PlaylistResponse({
    required this.statusCode,
    this.body,
    this.etag,
    this.lastModified,
    this.cacheControl,
    this.vary,
  });

  final int statusCode;
  final String? body;
  final String? etag;
  final String? lastModified;
  final String? cacheControl;
  final String? vary;
}

class ConditionalPlaylistCache {
  ConditionalPlaylistCache({Future<Directory> Function()? directory})
      : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;
  static final ConditionalPlaylistCache instance = ConditionalPlaylistCache();

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}playlist_cache');
  }

  Future<void> clear() async {
    final dir = await _directory();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.body') || entity.path.endsWith('.json'))) {
        await entity.delete();
      }
    }
  }

  Future<T> fetch<T>({
    required String resource,
    required Future<PlaylistResponse> Function(Map<String, String> headers)
        request,
    required FutureOr<T> Function(String body) parse,
  }) async {
    final key = sha256.convert(utf8.encode(resource)).toString();
    final dir = await _directory();
    final bodyFile = File('${dir.path}${Platform.pathSeparator}$key.body');
    final metaFile = File('${dir.path}${Platform.pathSeparator}$key.json');
    bool cannotStore(PlaylistResponse response) =>
        (response.cacheControl ?? '')
            .toLowerCase()
            .split(',')
            .any((directive) => directive.trim() == 'no-store') ||
        (response.vary?.trim().isNotEmpty ?? false);
    String? cached;
    Map<String, dynamic>? meta;
    try {
      if (await bodyFile.exists() && await metaFile.exists()) {
        final parsedMeta = jsonDecode(await metaFile.readAsString());
        if (parsedMeta is! Map<String, dynamic>) {
          throw const FormatException('Invalid playlist cache metadata');
        }
        final bytes = await bodyFile.readAsBytes();
        final digest = parsedMeta['sha256'];
        if (digest is! String) {
          throw const FormatException('Invalid playlist cache digest');
        }
        cached = await compute(_decodeCachedBody, (bytes, digest));
        meta = parsedMeta;
      }
    } on FileSystemException catch (error) {
      logDiag('M3U cache read failed: ${error.runtimeType}');
    } on FormatException catch (error) {
      logDiag('M3U cache invalid: ${error.runtimeType}');
    }

    final headers = <String, String>{};
    final etag = meta?['etag'];
    final lastModified = meta?['lastModified'];
    if (cached != null && etag is String && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    } else if (cached != null &&
        lastModified is String &&
        lastModified.isNotEmpty) {
      headers['If-Modified-Since'] = lastModified;
    }
    var response = await request(headers);
    if (response.statusCode == 304) {
      if (cached != null && headers.isNotEmpty) {
        try {
          final result = await parse(cached);
          if (cannotStore(response)) {
            try {
              if (await metaFile.exists()) await metaFile.delete();
              if (await bodyFile.exists()) await bodyFile.delete();
            } on FileSystemException catch (error) {
              logDiag('M3U cache removal failed: ${error.runtimeType}');
            }
          }
          return result;
        } on FormatException catch (error) {
          logDiag('M3U cache parse failed: ${error.runtimeType}');
        } on StreamUrlEmptyException catch (error) {
          logDiag('M3U cache parse failed: ${error.runtimeType}');
        }
      }
      response = await request(const {});
    }
    if (response.statusCode != 200 || response.body == null) {
      throw StateError(
          'Unexpected playlist HTTP status ${response.statusCode}');
    }
    final body = response.body!;
    final result = await parse(body);
    try {
      await dir.create(recursive: true);
      final hasValidator = (response.etag?.isNotEmpty ?? false) ||
          (response.lastModified?.isNotEmpty ?? false);
      if (!hasValidator || cannotStore(response)) {
        if (await metaFile.exists()) await metaFile.delete();
        if (await bodyFile.exists()) await bodyFile.delete();
        return result;
      }
      final (bytes, digest) = await compute(_encodeCachedBody, body);
      await bodyFile.writeAsBytes(bytes, flush: true);
      await metaFile.writeAsString(
          jsonEncode({
            'sha256': digest,
            'etag': response.etag,
            'lastModified': response.lastModified,
          }),
          flush: true);
    } on FileSystemException catch (error) {
      logDiag('M3U cache write failed: ${error.runtimeType}');
    }
    return result;
  }
}
