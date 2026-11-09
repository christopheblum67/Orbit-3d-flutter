import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_rate_limiter.dart';
import 'package:orbit_3d_flutter/services/api_transport.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preserves request options and shares limiter, without retrying 429',
      () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final seen = <String>[];
    final subscription = server.listen((request) {
      seen.add(request.uri.path);
      if (request.uri.path == '/not-modified') {
        expect(request.headers.value('if-none-match'), '"version"');
        request.response.statusCode = HttpStatus.notModified;
      } else {
        request.response.statusCode = HttpStatus.tooManyRequests;
      }
      request.response.close();
    });
    final limiter = ApiRateLimiter();
    final transport = ApiTransport(rateLimiter: limiter);
    final base = 'http://${server.address.address}:${server.port}';
    try {
      final response = await transport.request(
        '$base/not-modified',
        options: Options(
          headers: {'If-None-Match': '"version"'},
          validateStatus: (status) => status == 304,
        ),
      );
      expect(response.statusCode, 304);
      await expectLater(
        transport.request('$base/rate-limited'),
        throwsA(
          isA<StreamNetworkException>()
              .having((error) => error.isRetriable, 'isRetriable', isFalse),
        ),
      );
      expect(seen, ['/not-modified', '/rate-limited']);
      expect(limiter.isCoolingDown, isTrue);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
      HttpOverrides.global = previousOverrides;
    }
  });
}
