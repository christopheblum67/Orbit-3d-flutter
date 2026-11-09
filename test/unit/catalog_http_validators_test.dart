import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/catalog_disk_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_http_validators.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context);
}

Uint8List bytes(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late CatalogHttpValidators validators;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('orbit-catalog-test-');
    validators = CatalogHttpValidators(directory: () async => directory);
  });
  tearDown(() async {
    ApiService.bypassCatalogCache = false;
    await directory.delete(recursive: true);
  });

  test('validates resource, digest, body shape and validator precedence',
      () async {
    final catalog = bytes('[{"id":1}]');
    await validators.save('resource-a', catalog,
        etag: '"a"', lastModified: 'yesterday');
    expect(await validators.headers('resource-a', catalog),
        {'If-None-Match': '"a"'});
    expect(await validators.headers('resource-b', catalog), isEmpty);
    expect(
        await validators.headers('resource-a', bytes('[{"id":2}]')), isEmpty);
    expect(await validators.headers('resource-a', null), isEmpty);
    final bad = bytes('{"error":"unauthorized"}');
    await validators.save('resource-a', bad, etag: '"bad"');
    expect(await validators.headers('resource-a', bad), isEmpty);
    await validators.save('resource-a', catalog, lastModified: 'yesterday');
    expect(await validators.headers('resource-a', catalog),
        {'If-Modified-Since': 'yesterday'});
  });

  test('removes metadata for no-store, vary and absent validators', () async {
    final catalog = bytes('[]');
    for (final fields in [
      (cacheControl: 'no-store', vary: null),
      (cacheControl: null, vary: 'Authorization'),
    ]) {
      await validators.save('resource', catalog, etag: '"a"');
      await validators.save('resource', catalog,
          etag: '"a"', cacheControl: fields.cacheControl, vary: fields.vary);
      expect(await validators.headers('resource', catalog), isEmpty);
    }
    await validators.save('resource', catalog, etag: '"a"');
    await validators.save('resource', catalog);
    expect(await validators.headers('resource', catalog), isEmpty);
  });

  test('Xtream catalogue sends a conditional request and reuses 304 body',
      () async {
    final cacheDirectory =
        Directory('${directory.path}${Platform.pathSeparator}bodies');
    await cacheDirectory.create();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String?>[];
    server.listen((request) async {
      seen.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      if (seen.length == 1) {
        request.response.headers.set(HttpHeaders.etagHeader, '"v1"');
        request.response.write('[{"id":1}]');
      } else {
        request.response.statusCode = HttpStatus.notModified;
      }
      await request.response.close();
    });
    final api = ApiService(
      catalogCache: CatalogDiskCache.forTesting(cacheDirectory.path),
      catalogValidators: validators,
    );
    final url = 'http://${server.address.address}:${server.port}/catalog';
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(utf8.decode(await api.catalogBytesForTest('vod', 'sub', url)),
          '[{"id":1}]');
      ApiService.bypassCatalogCache = true;
      expect(utf8.decode(await api.catalogBytesForTest('vod', 'sub', url)),
          '[{"id":1}]');
    }, _RealHttpOverrides());
    expect(seen, [null, '"v1"']);
  });

  test('fresh catalogue is reused without a network request', () async {
    final cacheDirectory =
        Directory('${directory.path}${Platform.pathSeparator}bodies');
    await cacheDirectory.create();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var calls = 0;
    server.listen((request) async {
      calls++;
      request.response.headers.set(HttpHeaders.etagHeader, '"v1"');
      request.response.write('[]');
      await request.response.close();
    });
    final api = ApiService(
      catalogCache: CatalogDiskCache.forTesting(cacheDirectory.path),
      catalogValidators: validators,
    );
    final url = 'http://${server.address.address}:${server.port}/catalog';
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(utf8.decode(await api.catalogBytesForTest('vod', 'sub', url)), '[]');
      expect(utf8.decode(await api.catalogBytesForTest('vod', 'sub', url)), '[]');
    }, _RealHttpOverrides());
    expect(calls, 1);
  });

  test('category requests revalidate even while the local copy is fresh',
      () async {
    final cacheDirectory =
        Directory('${directory.path}${Platform.pathSeparator}bodies');
    await cacheDirectory.create();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String?>[];
    server.listen((request) async {
      seen.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      if (seen.length == 1) {
        request.response.headers.set(HttpHeaders.etagHeader, '"categories"');
        request.response.write('[]');
      } else {
        request.response.statusCode = HttpStatus.notModified;
      }
      await request.response.close();
    });
    final api = ApiService(
      catalogCache: CatalogDiskCache.forTesting(cacheDirectory.path),
      catalogValidators: validators,
    );
    final url = 'http://${server.address.address}:${server.port}/categories';
    await HttpOverrides.runWithHttpOverrides(() async {
      for (var i = 0; i < 2; i++) {
        expect(
          utf8.decode(await api.catalogBytesForTest(
            'vod_cats',
            'sub',
            url,
            useFreshCache: false,
          )),
          '[]',
        );
      }
    }, _RealHttpOverrides());
    expect(seen, [null, '"categories"']);
  });

  test('corrupted catalogue is downloaded again without a validator', () async {
    final cacheDirectory =
        Directory('${directory.path}${Platform.pathSeparator}bodies');
    await cacheDirectory.create();
    final cache = CatalogDiskCache.forTesting(cacheDirectory.path);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String?>[];
    server.listen((request) async {
      seen.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      request.response.headers.set(HttpHeaders.etagHeader, '"v1"');
      request.response.write('[{"id":${seen.length}}]');
      await request.response.close();
    });
    final api = ApiService(catalogCache: cache, catalogValidators: validators);
    final url = 'http://${server.address.address}:${server.port}/catalog';
    await HttpOverrides.runWithHttpOverrides(() async {
      await api.catalogBytesForTest('series', 'sub', url);
      await cache.write('series', 'sub', bytes('invalid'));
      ApiService.bypassCatalogCache = true;
      expect(utf8.decode(await api.catalogBytesForTest('series', 'sub', url)),
          '[{"id":2}]');
    }, _RealHttpOverrides());
    expect(seen, [null, null]);
  });

  test('304 no-store removes the previously cached catalogue', () async {
    final cacheDirectory =
        Directory('${directory.path}${Platform.pathSeparator}bodies');
    await cacheDirectory.create();
    final cache = CatalogDiskCache.forTesting(cacheDirectory.path);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var calls = 0;
    server.listen((request) async {
      calls++;
      if (calls == 1) {
        request.response.headers.set(HttpHeaders.etagHeader, '"v1"');
        request.response.write('[]');
      } else {
        request.response.headers
            .set(HttpHeaders.cacheControlHeader, 'no-store');
        request.response.statusCode = HttpStatus.notModified;
      }
      await request.response.close();
    });
    final api = ApiService(catalogCache: cache, catalogValidators: validators);
    final url = 'http://${server.address.address}:${server.port}/catalog';
    await HttpOverrides.runWithHttpOverrides(() async {
      await api.catalogBytesForTest('vod', 'sub', url);
      ApiService.bypassCatalogCache = true;
      expect(
          utf8.decode(await api.catalogBytesForTest('vod', 'sub', url)), '[]');
    }, _RealHttpOverrides());
    expect(await cache.read('vod', 'sub'), isNull);
    expect(await validators.headers(url, bytes('[]')), isEmpty);
  });

  test('unexpected 304 with no cached body retries unconditionally', () async {
    final cacheDirectory =
        Directory('${directory.path}${Platform.pathSeparator}bodies');
    await cacheDirectory.create();
    final cache = CatalogDiskCache.forTesting(cacheDirectory.path);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String?>[];
    server.listen((request) async {
      seen.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      if (seen.length == 1) {
        request.response.statusCode = HttpStatus.notModified;
      } else {
        request.response.write('[]');
      }
      await request.response.close();
    });
    final api = ApiService(catalogCache: cache, catalogValidators: validators);
    final url = 'http://${server.address.address}:${server.port}/catalog';
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(utf8.decode(await api.catalogBytesForTest('vod', 'sub', url)),
          '[]');
    }, _RealHttpOverrides());
    expect(seen, [null, null]);
  });
}
