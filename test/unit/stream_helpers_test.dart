import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

void main() {
  group('parseXmltvDate', () {
    test('parses 14 digits without offset as UTC', () {
      final dt = parseXmltvDate('20260830090000');
      expect(dt, DateTime.utc(2026, 8, 30, 9, 0, 0).toLocal());
    });

    test('parses 14 digits with positive offset', () {
      final dt = parseXmltvDate('20260830090000 +0200');
      expect(dt, DateTime.utc(2026, 8, 30, 7, 0, 0).toLocal());
    });

    test('parses 14 digits with negative offset', () {
      final dt = parseXmltvDate('20260830090000 -0500');
      expect(dt, DateTime.utc(2026, 8, 30, 14, 0, 0).toLocal());
    });

    test('trims surrounding whitespace', () {
      final dt = parseXmltvDate('  20260830090000 +0200  ');
      expect(dt, DateTime.utc(2026, 8, 30, 7, 0, 0).toLocal());
    });

    test('returns null for unexpected format', () {
      expect(parseXmltvDate('hello'), isNull);
      expect(parseXmltvDate(''), isNull);
      expect(parseXmltvDate('20260830'), isNull);
      expect(parseXmltvDate('202608300900000'), isNull);
      expect(parseXmltvDate('2026-08-30 09:00:00'), isNull);
    });
  });
}
