import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/http_byte_range.dart';

void main() {
  test('calcule les plages explicites, ouvertes et suffixes', () {
    for (final (header, expectedStart, expectedEnd) in [
      ('bytes=2-5', 2, 5),
      ('bytes=2-', 2, 9),
      ('bytes=-3', 7, 9),
      ('bytes=-100', 0, 9),
      ('bytes=8-99', 8, 9),
    ]) {
      final range = parseHttpByteRange(header, 10) as HttpByteRange;
      expect((range.start, range.end, range.length),
          (expectedStart, expectedEnd, expectedEnd - expectedStart + 1));
    }
  });

  test('distingue plage impossible et syntaxe non prise en charge', () {
    expect(parseHttpByteRange('bytes=10-', 10), isA<UnsatisfiableByteRange>());
    expect(parseHttpByteRange('bytes=-0', 10), isA<UnsatisfiableByteRange>());
    expect(parseHttpByteRange('bytes=0-', 0), isA<UnsatisfiableByteRange>());
    expect(parseHttpByteRange('bytes=3-2', 10), isA<UnsupportedByteRange>());
    expect(parseHttpByteRange('bytes=0-1,4-5', 10), isA<UnsupportedByteRange>());
    expect(parseHttpByteRange('bytes=-', 10), isA<UnsupportedByteRange>());
    expect(() => parseHttpByteRange('bytes=0-', -1), throwsArgumentError);
  });
}
