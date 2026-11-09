import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';
import 'package:orbit_3d_flutter/services/catalog_disk_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_http_validators.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    show StreamNetworkException;

typedef CatalogHttpGet = Future<Response<dynamic>> Function(
  String url, {
  Options? options,
});

class CatalogFetchService {
  CatalogFetchService({
    required CatalogDiskCache cache,
    required CatalogHttpValidators validators,
    required CatalogHttpGet get,
  })  : _cache = cache,
        _validators = validators,
        _get = get;

  final CatalogDiskCache _cache;
  final CatalogHttpValidators _validators;
  final CatalogHttpGet _get;

  Future<Uint8List> fetch(
    String name,
    String cacheKey,
    String url, {
    bool useFreshCache = true,
  }) async {
    if (useFreshCache) {
      final cached = await traceCatalogStep(
        name,
        'cache_read',
        () => _cache.read(name, cacheKey),
      );
      if (cached != null && cached.isNotEmpty) {
        logDiag('Catalogue $name: cache disque (${cached.length} o)');
        return cached;
      }
    }
    final stale = await _cache.read(
      name,
      cacheKey,
      maxAgeLimit: const Duration(days: 365000),
    );
    final headers = await _validators.headers(url, stale);
    Future<Response<dynamic>> request(Map<String, String> headers) =>
        traceCatalogStep(
          name,
          'network',
          () => _get(
            url,
            options: Options(
              headers: headers,
              responseType: ResponseType.bytes,
              validateStatus: (status) =>
                  status != null &&
                  (status == 304 || (status >= 200 && status < 300)),
            ),
          ),
        );
    var response = await request(headers);
    bool cannotStore(Response<dynamic> response) =>
        (response.headers.value('cache-control') ?? '')
            .toLowerCase()
            .split(',')
            .any((part) => part.trim() == 'no-store') ||
        (response.headers.value('vary')?.trim().isNotEmpty ?? false);
    if (response.statusCode == 304) {
      if (headers.isNotEmpty && stale != null) {
        if (cannotStore(response)) {
          await _cache.remove(name, cacheKey);
          await _validators.save(url, stale, cacheControl: 'no-store');
        } else {
          await _cache.write(name, cacheKey, stale);
        }
        return stale;
      }
      response = await request(const {});
    }
    if (response.statusCode != 200) {
      throw StreamNetworkException('Réponse $name invalide.');
    }
    final data = response.data;
    final bytes = data is Uint8List
        ? data
        : Uint8List.fromList(data is List<int> ? data : const <int>[]);
    if (bytes.isEmpty) {
      throw StreamNetworkException('Réponse $name vide.');
    }
    if (cannotStore(response)) {
      await _cache.remove(name, cacheKey);
    } else {
      await traceCatalogStep(
        name,
        'cache_write',
        () => _cache.write(name, cacheKey, bytes),
      );
    }
    await _validators.save(
      url,
      bytes,
      etag: response.headers.value('etag'),
      lastModified: response.headers.value('last-modified'),
      cacheControl: response.headers.value('cache-control'),
      vary: response.headers.value('vary'),
    );
    return bytes;
  }
}
