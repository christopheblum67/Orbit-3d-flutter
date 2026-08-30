import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

void main() {
  final api = ApiService();

  group('buildXtreamStreamUrl', () {
    test('builds a live stream URL with a valid query string', () {
      final url = api.buildXtreamStreamUrl(
        'http://sofia.rabaden.eu:80',
        'user',
        'p4ss',
        '12345',
      );
      final uri = Uri.parse(url);
      expect(uri.scheme, 'http');
      expect(uri.host, 'sofia.rabaden.eu');
      expect(uri.port, 80);
      expect(uri.path, '/player_api.php');
      expect(uri.queryParameters['username'], 'user');
      expect(uri.queryParameters['password'], 'p4ss');
      expect(uri.queryParameters['stream'], '12345');
      expect(uri.queryParameters.containsKey('type'), isFalse);
      expect(url.contains('&type='), isFalse);
    });

    test('adds type param for movie streams', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '42',
        type: 'movie',
      );
      final uri = Uri.parse(url);
      expect(uri.queryParameters['stream'], '42');
      expect(uri.queryParameters['type'], 'movie');
    });

    test('strips a trailing slash from the base URL', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80/',
        'user',
        'p4ss',
        '7',
      );
      expect(Uri.parse(url).path, '/player_api.php');
    });

    test('does not duplicate player_api.php when base URL already contains it',
        () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80/player_api.php',
        'user',
        'p4ss',
        '7',
      );
      expect(Uri.parse(url).path, '/player_api.php');
    });

    test('URL-encodes credentials with reserved characters', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'us er',
        'p@ss&word',
        '7',
      );
      final uri = Uri.parse(url);
      expect(uri.queryParameters['username'], 'us er');
      expect(uri.queryParameters['password'], 'p@ss&word');
      expect(url.contains(' '), isFalse);
    });

    test('includes extra params for replay streams', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '99',
        extra: {'start': '20260830090000', 'end': '20260830100000'},
      );
      final uri = Uri.parse(url);
      expect(uri.queryParameters['stream'], '99');
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