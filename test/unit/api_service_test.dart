import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
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

    test('builds the movie stream URL with the standard /movie/ prefix '
        '(no extension)', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '42',
        type: 'movie',
      );
      final uri = Uri.parse(url);
      expect(uri.path, '/movie/user/p4ss/42');
      expect(uri.hasQuery, isFalse);
    });

    test('keeps the /movie/ prefix without extension by default even when '
        'provided', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '42',
        type: 'movie',
        extension: '.mkv',
      );
      expect(Uri.parse(url).path, '/movie/user/p4ss/42');
    });

    test('adds the extension only when withExtension is set (legacy servers)',
        () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '42',
        type: 'movie',
        extension: '.mkv',
        withExtension: true,
      );
      expect(Uri.parse(url).path, '/movie/user/p4ss/42.mkv');
    });

    test('builds the series stream URL with the standard /series/ prefix '
        '(no extension)', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '7',
        type: 'series',
        extension: 'mp4',
      );
      expect(Uri.parse(url).path, '/series/user/p4ss/7');
    });

    test('adds the series extension only when withExtension is set', () {
      final url = api.buildXtreamStreamUrl(
        'http://host:80',
        'user',
        'p4ss',
        '7',
        type: 'series',
        extension: 'mp4',
        withExtension: true,
      );
      expect(Uri.parse(url).path, '/series/user/p4ss/7.mp4');
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

    test('timeshift URL uses streaming/timeshift.php with start + duration',
        () {
      final url = api.buildXtreamTimeshiftUrl(
        'http://host:8121',
        'user',
        'p4ss',
        '99',
        start: 1785643200,
        end: 1785646800,
      );
      final uri = Uri.parse(url);
      expect(uri.path, '/streaming/timeshift.php');
      expect(uri.queryParameters['username'], 'user');
      expect(uri.queryParameters['password'], 'p4ss');
      expect(uri.queryParameters['stream'], '99');
      expect(uri.queryParameters['start'], '1785643200');
      expect(uri.queryParameters['duration'], '3600');
    });

    test('timeshift URL derives duration from end - start, and strips '
        'player_api.php suffix', () {
      final url = api.buildXtreamTimeshiftUrl(
        'http://host:8121/player_api.php',
        'u',
        'p',
        '7',
        start: 100,
        end: 400,
      );
      final uri = Uri.parse(url);
      expect(uri.path, '/streaming/timeshift.php');
      expect(uri.queryParameters['duration'], '300');
      expect(uri.queryParameters['start'], '100');
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

  group('replayProbeSet', () {
    Channel channel(int id, {String group = 'G', bool replay = false}) =>
        Channel(
          id: '$id',
          name: 'Chaîne $id',
          logoUrl: '',
          streamUrl: 'http://host/u/p/$id',
          group: group,
          supportsReplay: replay,
        );

    test('inclut toutes les chaînes marquées DVR, en premier', () {
      final channels = [
        channel(1, group: 'France HD'),
        channel(2, group: 'France HD', replay: true),
        channel(3, group: 'Sport', replay: true),
        channel(4, group: 'Sport'),
      ];
      final flagged = channels.where((c) => c.supportsReplay).toList();
      final probe = ApiService.replayProbeSet(channels, flagged);
      final ids = probe.map((c) => c.id).toList();
      expect(ids.take(2), ['2', '3']);
      expect(ids, containsAll(['1', '4']));
    });

    test('ne pioche que 3 chaînes par groupe non marqué (round-robin)', () {
      final channels = [
        for (var g = 0; g < 10; g++)
          for (var i = 0; i < 6; i++)
            channel(g * 10 + i, group: 'Groupe $g'),
      ];
      final probe = ApiService.replayProbeSet(channels, const []);
      // Toutes les catégories sont couvertes…
      expect(probe.map((c) => c.group).toSet().length, 10);
      // …mais au plus 3 chaînes par catégorie (30 = 10 × 3 < budget 40).
      final byGroup = <String, int>{};
      for (final c in probe) {
        byGroup[c.group] = (byGroup[c.group] ?? 0) + 1;
      }
      expect(byGroup.values.every((n) => n <= 3), isTrue);
      expect(byGroup.values.every((n) => n >= 3), isTrue);
    });

    test('respecte le budget total de chaînes sondées', () {
      final channels = [
        for (var g = 0; g < 20; g++)
          for (var i = 0; i < 10; i++)
            channel(g * 10 + i, group: 'Groupe $g'),
      ];
      final probe = ApiService.replayProbeSet(channels, const []);
      expect(probe.length, lessThanOrEqualTo(40));
    });
  });
}
