import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/conditional_xmltv_cache.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late ConditionalXmltvCache cache;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit-xmltv-test-');
    cache = ConditionalXmltvCache(directory: () async => dir);
  });
  tearDown(() async => dir.delete(recursive: true));

  test('real XMLTV requests reuse 304 and preserve HTTP charset', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final headers = <String?>[];
    server.listen((request) async {
      headers.add(request.headers.value(HttpHeaders.ifNoneMatchHeader));
      if (headers.length == 1) {
        request.response.headers.set(HttpHeaders.etagHeader, '"guide-v1"');
        request.response.headers.set(
            HttpHeaders.contentTypeHeader, 'text/xml; charset=iso-8859-1');
        request.response.add(latin1.encode(
          '<tv><programme channel="fr" start="20261109070000 +0100" '
          'stop="20261109080000 +0100"><title>Émission</title>'
          '</programme></tv>',
        ));
      } else {
        request.response.statusCode = HttpStatus.notModified;
      }
      await request.response.close();
    });
    final api = ApiService(xmltvCache: cache);
    final url = 'http://${server.address.address}:${server.port}/guide';
    await HttpOverrides.runWithHttpOverrides(() async {
      final first = await api.fetchXmltvForTest(url);
      final second = await api.fetchXmltvForTest(url);
      expect(first.single.title, 'Émission');
      expect(second.single.title, 'Émission');
    }, _RealHttpOverrides());
    expect(headers, [null, '"guide-v1"']);
    await cache.clear();
    expect(dir.listSync(), isEmpty);
  });

  test('corruption and missing files require an unconditional response',
      () async {
    final payload = Uint8List.fromList(utf8.encode('<tv></tv>'));
    Future<String> fetch() => cache.fetch(
          resource: 'guide',
          request: (headers) async {
            expect(headers, isEmpty);
            return XmltvResponse(statusCode: 200, body: payload, etag: '"a"');
          },
          parse: (bytes, _) async => utf8.decode(bytes),
        );
    await fetch();
    final file = dir.listSync().whereType<File>().singleWhere(
          (entity) => entity.path.endsWith('.body'),
        );
    await file.writeAsString('corrupted');
    expect(await fetch(), '<tv></tv>');
    await file.delete();
    expect(await fetch(), '<tv></tv>');
  });

  test('does not store no-store responses or accept a repeated 304', () async {
    final payload = Uint8List.fromList(utf8.encode('<tv></tv>'));
    await cache.fetch(
      resource: 'guide',
      request: (_) async => XmltvResponse(
        statusCode: 200,
        body: payload,
        etag: '"a"',
        cacheControl: 'no-store',
      ),
      parse: (bytes, _) async => utf8.decode(bytes),
    );
    expect(dir.listSync(), isEmpty);
    var calls = 0;
    await expectLater(
      cache.fetch(
        resource: 'guide',
        request: (_) async {
          calls++;
          return const XmltvResponse(statusCode: 304);
        },
        parse: (bytes, _) async => utf8.decode(bytes),
      ),
      throwsStateError,
    );
    expect(calls, 2);
  });

  test('last-modified is scoped to the resource and vary prevents storage',
      () async {
    final payload = Uint8List.fromList(utf8.encode('<tv/>'));
    Future<String> fetch(
      String resource,
      Future<XmltvResponse> Function(Map<String, String>) request,
    ) =>
        cache.fetch(
          resource: resource,
          request: request,
          parse: (bytes, _) async => utf8.decode(bytes),
        );
    await fetch('a', (headers) async {
      expect(headers, isEmpty);
      return XmltvResponse(
        statusCode: 200,
        body: payload,
        lastModified: 'Wed, 21 Oct 2015 07:28:00 GMT',
      );
    });
    await fetch('b', (headers) async {
      expect(headers, isEmpty);
      return XmltvResponse(statusCode: 200, body: payload, vary: 'Accept');
    });
    expect(await fetch('a', (headers) async {
      expect(headers, {'If-Modified-Since': 'Wed, 21 Oct 2015 07:28:00 GMT'});
      return const XmltvResponse(statusCode: 304, vary: 'Accept');
    }), '<tv/>');
    expect(dir.listSync(), isEmpty);
  });

  test('accepts empty XMLTV and rejects an HTML error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var calls = 0;
    server.listen((request) async {
      calls++;
      request.response.write(calls == 1 ? '<tv/>' : '<html>Error</html>');
      await request.response.close();
    });
    final api = ApiService(xmltvCache: cache);
    final url = 'http://${server.address.address}:${server.port}/guide';
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(await api.fetchXmltvForTest(url), isEmpty);
      await expectLater(api.fetchXmltvForTest(url), throwsFormatException);
    }, _RealHttpOverrides());
  });
}
