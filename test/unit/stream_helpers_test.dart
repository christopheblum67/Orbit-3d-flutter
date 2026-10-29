import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

void main() {
  group('parseXmltvDate', () {
    test('parses 14 digits without offset as LOCAL time', () {
      // Les panels Xtream servent l'heure de leur serveur sans décalage.
      // L'interpréter en UTC décalait tout le guide de 1 à 2 h selon la
      // saison, ce qui faisait échouer la recherche du programme en cours.
      final dt = parseXmltvDate('20260830090000');
      expect(dt, isNotNull);
      expect(dt!.isUtc, isFalse);
      expect(dt.year, 2026);
      expect(dt.month, 8);
      expect(dt.day, 30);
      expect(dt.hour, 9);
      expect(dt.minute, 0);
    });

    test('parses 14 digits with positive offset', () {
      final dt = parseXmltvDate('20260830090000 +0200');
      expect(dt!.toUtc(), DateTime.utc(2026, 8, 30, 7, 0, 0));
    });

    test('parses 14 digits with negative offset', () {
      final dt = parseXmltvDate('20260830090000 -0500');
      expect(dt!.toUtc(), DateTime.utc(2026, 8, 30, 14, 0, 0));
    });

    test('trims surrounding whitespace', () {
      final dt = parseXmltvDate('  20260830090000 +0200  ');
      expect(dt!.toUtc(), DateTime.utc(2026, 8, 30, 7, 0, 0));
    });

    test('returns null for unexpected format', () {
      expect(parseXmltvDate('hello'), isNull);
      expect(parseXmltvDate(''), isNull);
      expect(parseXmltvDate('20260830'), isNull);
      expect(parseXmltvDate('202608300900000'), isNull);
      expect(parseXmltvDate('2026-08-30 09:00:00'), isNull);
    });
  });

  group('streamUrlVariants', () {
    test('standard Xtream /movie/{u}/{p}/{id} proposes ext + live-style', () {
      final variants = streamUrlVariants(
        'https://host/movie/15548815/l3khgnaaa3mh/12345',
      );
      expect(
        variants,
        contains('https://host/movie/15548815/l3khgnaaa3mh/12345'),
      );
      expect(
        variants,
        contains('https://host/movie/15548815/l3khgnaaa3mh/12345.mp4'),
      );
      expect(
        variants,
        contains('https://host/movie/15548815/l3khgnaaa3mh/12345.mkv'),
      );
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/12345'));
    });

    test('keeps a panel-provided VOD extension as the first candidate', () {
      const url = 'https://host/movie/user/pass/12345.mkv';
      final variants = streamUrlVariants(url);

      expect(variants.first, url);
      expect(
        variants,
        contains('https://host/movie/user/pass/12345'),
      );
      expect(
        variants,
        contains('https://host/user/pass/12345.mkv'),
      );
    });

    test('standard Xtream /series/{u}/{p}/{id}.ext drops the extension', () {
      final variants = streamUrlVariants(
        'https://host/series/15548815/l3khgnaaa3mh/14190.mkv',
      );
      expect(
        variants,
        contains('https://host/series/15548815/l3khgnaaa3mh/14190.mkv'),
      );
      expect(
        variants,
        contains('https://host/series/15548815/l3khgnaaa3mh/14190'),
      );
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/14190'));
      expect(
        variants,
        contains('https://host/15548815/l3khgnaaa3mh/14190.mkv'),
      );
    });

    test('live-style /u/p/id proposes only the original url', () {
      final variants = streamUrlVariants(
        'https://host/15548815/l3khgnaaa3mh/12345',
      );
      expect(variants, ['https://host/15548815/l3khgnaaa3mh/12345']);
    });

    test(
        'timeshift /streaming/timeshift.php proposes only the original url '
        '(anti-leech)', () {
      const url = 'https://host/streaming/timeshift.php?username=u&password=p'
          '&stream=55&start=1785643200&duration=3600';
      final variants = streamUrlVariants(url);
      expect(variants, [url]);
    });

    test('player_api.php script urls are not manipulated', () {
      final variants = streamUrlVariants(
        'https://host/player_api.php?username=u&password=p&action=get_live_streams',
      );
      expect(variants.length, 1);
    });

    test('live-style /u/p/id.ext proposes the extensionless form', () {
      final variants = streamUrlVariants(
        'https://host/15548815/l3khgnaaa3mh/12345.mkv',
      );
      expect(
          variants, contains('https://host/15548815/l3khgnaaa3mh/12345.mkv'),);
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/12345'));
      expect(variants,
          isNot(contains('https://host/movie/15548815/l3khgnaaa3mh/12345')),);
      expect(variants,
          isNot(contains('https://host/series/15548815/l3khgnaaa3mh/12345')),);
    });

    test('handles empty / invalid urls gracefully', () {
      expect(streamUrlVariants(''), ['']);
      expect(streamUrlVariants('  '), ['  ']);
    });
  });
}
