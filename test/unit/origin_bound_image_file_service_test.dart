import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:orbit_3d_flutter/core/utils/image_cache_config.dart';

class _RedirectClient extends http.BaseClient {
  _RedirectClient(this.locations);

  final Map<String, String> locations;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final location = locations[request.url.path];
    return http.StreamedResponse(
      Stream.value(utf8.encode('image')),
      location == null ? 200 : 302,
      headers: location == null ? {} : {'location': location},
    );
  }
}

void main() {
  test('redirects retain headers only until the first origin change', () async {
    final first = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final second = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = IOClient();
    addTearDown(() async {
      client.close();
      await first.close(force: true);
      await second.close(force: true);
    });
    final received = <String, String?>{};
    first.listen((request) async {
      received[request.uri.path] = request.headers.value('x-fake-session');
      if (request.uri.path == '/start') {
        request.response
          ..statusCode = 302
          ..headers.set('location', '/same');
      } else if (request.uri.path == '/same') {
        request.response
          ..statusCode = 307
          ..headers.set('location', 'http://127.0.0.1:${second.port}/cross');
      } else {
        request.response
          ..headers.contentType = ContentType('image', 'png')
          ..headers.set('cache-control', 'max-age=120')
          ..headers.set('etag', '"fake"')
          ..write('image');
      }
      await request.response.close();
    });
    second.listen((request) async {
      received[request.uri.path] = request.headers.value('x-fake-session');
      request.response
        ..statusCode = 302
        ..headers.set('location', 'http://127.0.0.1:${first.port}/end');
      await request.response.close();
    });
    final service = OriginBoundImageFileService(client: client);
    final response = await service.get(
      'http://127.0.0.1:${first.port}/start',
      headers: {'X-Fake-Session': 'marker'},
    );
    expect(await utf8.decoder.bind(response.content).join(), 'image');
    expect(received, {
      '/start': 'marker',
      '/same': 'marker',
      '/cross': null,
      '/end': null,
    });
    expect(response.statusCode, 200);
    expect(response.fileExtension, '.png');
    expect(response.eTag, '"fake"');
    expect(
      response.validTill.difference(DateTime.now()).inSeconds,
      greaterThan(110),
    );
  });

  test('HTTPS downgrade and a return to HTTPS never forward headers', () async {
    final client = _RedirectClient({
      '/start': 'http://panel.example/next',
      '/next': 'https://panel.example/end',
    });
    final service = OriginBoundImageFileService(client: client);
    final response = await service.get(
      'https://panel.example/start',
      headers: {'X-Fake-Session': 'marker'},
    );
    await response.content.drain<void>();
    expect(
      client.requests.map((request) => request.followRedirects),
      everyElement(isFalse),
    );
    expect(client.requests[0].headers['x-fake-session'], 'marker');
    expect(client.requests[1].headers, isEmpty);
    expect(client.requests[2].headers, isEmpty);
  });

  test('subdomain redirects cannot receive headers', () async {
    final client = _RedirectClient({'/start': 'https://sub.panel.example/end'});
    final response = await OriginBoundImageFileService(client: client).get(
      'https://panel.example/start',
      headers: {'X-Fake-Session': 'marker'},
    );
    await response.content.drain<void>();
    expect(client.requests[1].headers, isEmpty);
  });

  test('redirect loops fail after the usual five redirects', () async {
    final client = _RedirectClient({'/start': '/start'});
    await expectLater(
      OriginBoundImageFileService(client: client).get(
        'https://panel.example/start',
        headers: {'X-Fake-Session': 'marker'},
      ),
      throwsA(isA<HttpException>()),
    );
    expect(client.requests.length, 6);
  });
}
