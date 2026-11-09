import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/conditional_xmltv_cache.dart';
import 'package:orbit_3d_flutter/services/xmltv_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('XML encoding takes precedence and a 304 reuses the parsed body',
      () async {
    final directory = await Directory.systemTemp.createTemp('xmltv-service-');
    addTearDown(() => directory.delete(recursive: true));
    final cache = ConditionalXmltvCache(directory: () async => directory);
    final requests = <Options>[];
    final body = Uint8List.fromList(latin1.encode(
      '<?xml version="1.0" encoding="ISO-8859-1"?>'
      '<tv><programme channel="fr" start="20261109070000 +0100" '
      'stop="20261109080000 +0100"><title>Émission</title>'
      '</programme></tv>',
    ));
    final service = XmltvService(
      cache: cache,
      get: (url, {options}) async {
        requests.add(options!);
        final first = requests.length == 1;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          statusCode: first ? 200 : 304,
          data: first ? body : null,
          headers: Headers.fromMap(first
              ? {
                  'content-type': ['text/xml; charset=utf-8'],
                  'etag': ['"guide"'],
                }
              : {}),
        );
      },
    );
    expect((await service.fetch('https://example.test/guide')).single.title,
        'Émission');
    expect((await service.fetch('https://example.test/guide')).single.title,
        'Émission');
    expect(requests[0].responseType, ResponseType.bytes);
    expect(requests[0].validateStatus!(304), isTrue);
    expect(requests[1].headers, {'If-None-Match': '"guide"'});
  });
}
