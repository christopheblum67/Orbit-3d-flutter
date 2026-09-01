import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

void main() {
  final api = ApiService();

  group('buildXtreamStreamUrl', () {
    test('builds the classic host-style stream URL (host/user/pass/id)', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '12345',
      );
      final uri = Uri.parse(url);
      expect(uri.scheme, 'http');
      expect(uri.host, 'host');
      expect(uri.port, 80);
      expect(uri.path, '/user/p4ss/12345');
      expect(uri.hasQuery, isFalse);
    });

    test('adds type param for movie streams without changing the path', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '42',
        type: 'movie',
      );
      final uri = Uri.parse(url);
      expect(uri.path, '/user/p4ss/42');
      expect(uri.hasQuery, isFalse);
    });

    test('strips a trailing slash from the base URL', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80/',
        'user',
        'p4ss',
        '7',
      );
      expect(Uri.parse(url).path, '/user/p4ss/7');
    });

    test('keeps only the stream part when base URL already contains a script',
        () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80/player_api.php',
        'user',
        'p4ss',
        '7',
      );
      expect(Uri.parse(url).path, '/user/p4ss/7');
    });

    test('URL-encodes credentials with reserved characters in path segments',
        () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'us er',
        'p@ss&word',
        '7',
      );
      final uri = Uri.parse(url);
      expect(uri.pathSegments, containsAll(['us er', 'p@ss&word', '7']));
      expect(url.contains(' '), isFalse);
    });

    test('includes extra params as query for replay streams', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '99',
        extra: {'start': '20260830090000', 'end': '20260830100000'},
      );
      final uri = Uri.parse(url);
      expect(uri.path, '/user/p4ss/99');
      expect(uri.queryParameters['start'], '20260830090000');
      expect(uri.queryParameters['end'], '20260830100000');
    });

    test('returns an empty string when streamId is null or empty', () {
      expect(
        api.buildXtreamStreamUrl('http://host:80', 'user', 'p4ss', null),
        isEmpty,
      );
      expect(
        api.buildXtreamStreamUrl('http://host:80', 'user', 'p4ss', ''),
        isEmpty,
      );
    });
  });
}