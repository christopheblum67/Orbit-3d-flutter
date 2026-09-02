import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

void main() {
  group('parseXmltvDate', () {
    test('parses 14 digits without offset as UTC', () {
      final dt = parseXmltvDate('20260830090000');
      expect(dt!.toUtc(), DateTime.utc(2026, 8, 30, 9, 0, 0));
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
      expect(variants, contains('https://host/movie/15548815/l3khgnaaa3mh/12345'));
      expect(variants, contains('https://host/movie/15548815/l3khgnaaa3mh/12345.mp4'));
      expect(variants, contains('https://host/movie/15548815/l3khgnaaa3mh/12345.mkv'));
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/12345'));
    });

    test('standard Xtream /series/{u}/{p}/{id}.ext drops the extension', () {
      final variants = streamUrlVariants(
        'https://host/series/15548815/l3khgnaaa3mh/14190.mkv',
      );
      expect(variants, contains('https://host/series/15548815/l3khgnaaa3mh/14190.mkv'));
      expect(variants, contains('https://host/series/15548815/l3khgnaaa3mh/14190'));
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/14190'));
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/14190.mkv'));
    });

    test('live-style /u/p/id proposes standard media folders', () {
      final variants = streamUrlVariants(
        'https://host/15548815/l3khgnaaa3mh/12345',
      );
      expect(variants, contains('https://host/15548815/l3khgnaaa3mh/12345'));
      expect(variants, contains('https://host/movie/15548815/l3khgnaaa3mh/12345'));
      expect(variants, contains('https://host/series/15548815/l3khgnaaa3mh/12345'));
    });

    test('handles empty / invalid urls gracefully', () {
      expect(streamUrlVariants(''), ['']);
      expect(streamUrlVariants('  '), ['  ']);
    });
  });
}
