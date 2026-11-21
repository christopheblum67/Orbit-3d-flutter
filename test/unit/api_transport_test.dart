import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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

  test('forwards download progress after an HTTP retry', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    final subscription = server.listen((request) async {
      requests++;
      if (requests == 1) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
      } else {
        request.response.contentLength = 6;
        request.response.write('abc');
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        request.response.write('def');
      }
      await request.response.close();
    });
    final progress = <(int, int)>[];
    final logs = <String>[];
    const channel = MethodChannel('com.example.orbit_3d_flutter/app_log');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments;
      if (args is Map && args['message'] is String) {
        logs.add(args['message'] as String);
      }
      return null;
    });
    final transport = ApiTransport(rateLimiter: ApiRateLimiter());
    try {
      final response = await transport.request(
        'http://${server.address.address}:${server.port}/playlist',
        options: Options(
          responseType: ResponseType.plain,
          extra: {'orbitM3uTraceId': 174},
        ),
        onReceiveProgress: (received, total) => progress.add((received, total)),
      );
      expect(response.data, 'abcdef');
      expect(requests, 2);
      expect(progress, contains((6, 6)));
      expect(
        logs,
        contains(matches(
          r'^M3U gate trace=174 attempt=\d+ state=waiting$',
        )),
      );
      expect(
        logs,
        contains(matches(
          r'^M3U gate trace=174 attempt=\d+ state=acquired waitMs=\d+$',
        )),
      );
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await subscription.cancel();
      await server.close(force: true);
      HttpOverrides.global = previousOverrides;
    }
  });
}
