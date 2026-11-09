import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:path_provider/path_provider.dart';

class XmltvResponse {
  const XmltvResponse({
    required this.statusCode,
    this.body,
    this.contentType,
    this.etag,
    this.lastModified,
    this.cacheControl,
    this.vary,
  });

  final int statusCode;
  final Uint8List? body;
  final String? contentType;
  final String? etag;
  final String? lastModified;
  final String? cacheControl;
  final String? vary;
}

class ConditionalXmltvCache {
  ConditionalXmltvCache({Future<Directory> Function()? directory})
      : _directory = directory ?? _defaultDirectory;

  static final instance = ConditionalXmltvCache();
  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}xmltv_http_cache');
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
    required Future<XmltvResponse> Function(Map<String, String>) request,
    required Future<T> Function(Uint8List, String?) parse,
  }) async {
    final dir = await _directory();
    final key = sha256.convert(utf8.encode(resource));
    final bodyFile = File('${dir.path}${Platform.pathSeparator}$key.body');
    final metaFile = File('${dir.path}${Platform.pathSeparator}$key.json');
    Uint8List? cached;
    Map<String, dynamic>? meta;
    try {
      if (await bodyFile.exists() && await metaFile.exists()) {
        final value = jsonDecode(await metaFile.readAsString());
        if (value is! Map<String, dynamic>) throw const FormatException();
        final bytes = await bodyFile.readAsBytes();
        if (await compute(_digest, bytes) != value['digest']) {
          throw const FormatException();
        }
        cached = bytes;
        meta = value;
      }
    } on FileSystemException catch (error) {
      logDiag('XMLTV cache read failed: ${error.runtimeType}');
    } on FormatException catch (error) {
      logDiag('XMLTV cache invalid: ${error.runtimeType}');
    }
    final headers = <String, String>{};
    final etag = meta?['etag'];
    final modified = meta?['lastModified'];
    if (cached != null && etag is String && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    } else if (cached != null && modified is String && modified.isNotEmpty) {
      headers['If-Modified-Since'] = modified;
    }

    bool cannotStore(XmltvResponse response) =>
        (response.cacheControl ?? '')
            .toLowerCase()
            .split(',')
            .any((part) => part.trim() == 'no-store') ||
        (response.vary?.trim().isNotEmpty ?? false);

    Future<void> remove() async {
      try {
        if (await metaFile.exists()) await metaFile.delete();
        if (await bodyFile.exists()) await bodyFile.delete();
      } on FileSystemException catch (error) {
        logDiag('XMLTV cache removal failed: ${error.runtimeType}');
      }
    }

    var response = await request(headers);
    if (response.statusCode == 304) {
      if (cached != null && headers.isNotEmpty) {
        try {
          final contentType = meta?['contentType'];
          final result = await parse(
            cached,
            contentType is String ? contentType : null,
          );
          if (cannotStore(response)) await remove();
          return result;
        } on FormatException catch (error) {
          logDiag('XMLTV cache parse failed: ${error.runtimeType}');
        }
      }
      response = await request(const {});
    }
    final bytes = response.body;
    if (response.statusCode != 200 || bytes == null || bytes.isEmpty) {
      throw StateError('Unexpected XMLTV HTTP status ${response.statusCode}');
    }
    final result = await parse(bytes, response.contentType);
    final hasValidator = (response.etag?.isNotEmpty ?? false) ||
        (response.lastModified?.isNotEmpty ?? false);
    if (!hasValidator || cannotStore(response)) {
      await remove();
      return result;
    }
    try {
      await dir.create(recursive: true);
      await bodyFile.writeAsBytes(bytes, flush: true);
      await metaFile.writeAsString(
        jsonEncode({
          'digest': await compute(_digest, bytes),
          'contentType': response.contentType,
          'etag': response.etag,
          'lastModified': response.lastModified,
        }),
        flush: true,
      );
    } on FileSystemException catch (error) {
      logDiag('XMLTV cache write failed: ${error.runtimeType}');
    }
    return result;
  }
}

String _digest(Uint8List bytes) => sha256.convert(bytes).toString();
