// Script de test automatisé pour diagnostiquer le flux Live TV / Cloudflare
// Exécuter : flutter test test_stream_flow.dart
// Ou copier-coller dans une session dart run

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const testUrl = 'https://draap.online/series/169503400638842/1593574628/7819';
const host = 'draap.online';

const userAgents = [
  'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
  'Orbit3D/1.0 (Linux; Android 14; FireTV) ExoPlayerLib/2.19.1',
  'ExoPlayer/2.19.1',
];

void main() {
  group('Stream Flow Diagnostic', () {
    late Dio dio;

    setUpAll(() {
      dio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));
    });

    tearDownAll(() => dio.close());

    test('1. HEAD request (should be 200)', () async {
      final resp = await dio.head(testUrl, options: Options(
        headers: {'User-Agent': userAgents[0]},
        validateStatus: (s) => true,
      ));
      print('HEAD: ${resp.statusCode}');
      expect(resp.statusCode, equals(200));
    });

    test('2. GET with Chrome UA (should be 406 without cookie)', () async {
      try {
        final resp = await dio.get(testUrl, options: Options(
          headers: {
            'User-Agent': userAgents[0],
            'Accept': '*/*',
            'Referer': 'https://draap.online/',
          },
          validateStatus: (s) => true,
        ));
        print('GET Chrome UA: ${resp.statusCode}');
        print('  Headers: ${resp.headers.map}');
      } on DioException catch (e) {
        print('GET Chrome UA ERROR: ${e.response?.statusCode}');
      }
    });

    test('3. GET with ExoPlayer UA (should be 406)', () async {
      try {
        final resp = await dio.get(testUrl, options: Options(
          headers: {
            'User-Agent': userAgents[2],
            'Accept': '*/*',
            'Referer': 'https://draap.online/',
          },
          validateStatus: (s) => true,
        ));
        print('GET ExoPlayer UA: ${resp.statusCode}');
      } on DioException catch (e) {
        print('GET ExoPlayer UA ERROR: ${e.response?.statusCode}');
      }
    });

    test('4. Session: load homepage then GET stream (cookie jar test)', () async {
      final cookieJar = <String, String>{};
      final client = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));

      // Intercept cookies
      client.interceptors.add(InterceptorsWrapper(
        onResponse: (resp, handler) {
          final cookies = resp.headers['set-cookie'];
          if (cookies != null) {
            for (final c in cookies) {
              final parts = c.split(';')[0].split('=');
              if (parts.length == 2) cookieJar[parts[0]] = parts[1];
            }
          }
          return handler.next(resp);
        },
      ));

      // 1. Load homepage
      print('Loading homepage...');
      await client.get('https://draap.online/', options: Options(
        headers: {'User-Agent': userAgents[0]},
        validateStatus: (s) => true,
      ));
      print('Cookies after homepage: ${cookieJar.keys.join(", ")}');

      // 2. Try stream with cookies
      print('Trying stream with cookies...');
      try {
        final resp = await client.get(testUrl, options: Options(
          headers: {
            'User-Agent': userAgents[0],
            'Accept': '*/*',
            'Referer': 'https://draap.online/',
            if (cookieJar.isNotEmpty) 'Cookie': cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; '),
          },
          validateStatus: (s) => true,
        ));
        print('GET with cookies: ${resp.statusCode}');
        if (resp.statusCode == 200) {
          print('SUCCESS! Content-Type: ${resp.headers.value('content-type')}');
        }
      } on DioException catch (e) {
        print('GET with cookies ERROR: ${e.response?.statusCode}');
      }
    });

    test('5. Check for cf_clearance in cookies after challenge', () async {
      // This simulates what the WebView does
      final client = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 10,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));

      final cookies = <String, String>{};
      client.interceptors.add(InterceptorsWrapper(
        onResponse: (resp, handler) {
          final setCookie = resp.headers['set-cookie'];
          if (setCookie != null) {
            for (final c in setCookie) {
              final kv = c.split(';')[0].split('=');
              if (kv.length == 2) cookies[kv[0].trim()] = kv[1].trim();
            }
          }
          return handler.next(resp);
        },
      ));

      // Multiple requests to trigger challenge resolution
      for (int i = 0; i < 5; i++) {
        print('Attempt ${i + 1}/5...');
        try {
          await client.get('https://draap.online/', options: Options(
            headers: {'User-Agent': userAgents[0]},
            validateStatus: (s) => true,
          ));
          await Future.delayed(const Duration(seconds: 3));
          
          if (cookies.containsKey('cf_clearance')) {
            print('cf_clearance FOUND after ${i + 1} attempts!');
            print('Value: ${cookies['cf_clearance']!.substring(0, 50)}...');
            break;
          }
        } catch (e) {
          print('Attempt ${i + 1} error: $e');
        }
      }
      
      if (!cookies.containsKey('cf_clearance')) {
        print('cf_clearance NOT found after all attempts');
        print('All cookies: ${cookies.keys.join(", ")}');
      }
    });

    test('6. Test stream with cf_clearance if available', () async {
      // Run test 5 first, then manually copy cf_clearance here
      const cfClearance = ''; // PASTE VALUE FROM TEST 5 HERE
      
      if (cfClearance.isEmpty) {
        print('SKIPPED: No cf_clearance provided');
        return;
      }

      try {
        final resp = await dio.get(testUrl, options: Options(
          headers: {
            'User-Agent': userAgents[0],
            'Accept': '*/*',
            'Referer': 'https://draap.online/',
            'Cookie': 'cf_clearance=$cfClearance',
          },
          validateStatus: (s) => true,
        ));
        print('GET with cf_clearance: ${resp.statusCode}');
        if (resp.statusCode == 200) {
          print('SUCCESS! Stream accessible with cookie');
        }
      } on DioException catch (e) {
        print('GET with cf_clearance ERROR: ${e.response?.statusCode}');
      }
    });
  });
}