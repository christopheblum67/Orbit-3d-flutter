import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/hls_manifest_rewriter.dart';

void main() {
  test('réécrit sous-manifestes, segments, clés et initialisation', () {
    final targets = <Uri>[];
    final result = rewriteHlsManifest(
      '#EXTM3U\r\n'
      '#EXT-X-STREAM-INF:BANDWIDTH=200\r\n'
      '../video/index.m3u8?token=abc\r\n'
      '#EXT-X-KEY:METHOD=AES-128,URI="keys/a.key?x=1",IV=0x1\r\n'
      '#EXT-X-MAP:URI="/init.mp4"\r\n'
      '#EXT-X-MEDIA:NAME="English, URI=original",URI="audio.m3u8"\r\n'
      '#EXT-X-BYTERANGE:10@0\r\n'
      '  seg.ts?x=1  \r\n',
      Uri.parse('https://example.test/redirected/list.m3u8'),
      (target) {
        targets.add(target);
        return Uri.parse('http://127.0.0.1:1234/${targets.length}');
      },
    );
    expect(targets.map((u) => u.toString()), [
      'https://example.test/video/index.m3u8?token=abc',
      'https://example.test/redirected/keys/a.key?x=1',
      'https://example.test/init.mp4',
      'https://example.test/redirected/audio.m3u8',
      'https://example.test/redirected/seg.ts?x=1',
    ]);
    expect(
        result,
        contains(
            '#EXT-X-KEY:METHOD=AES-128,URI="http://127.0.0.1:1234/2",IV=0x1\r\n'));
    expect(result,
        contains('NAME="English, URI=original",URI="http://127.0.0.1:1234/4"'));
    expect(result,
        contains('#EXT-X-BYTERANGE:10@0\r\n  http://127.0.0.1:1234/5  \r\n'));
    expect(result.endsWith('\r\n'), isTrue);
  });

  test('refuse les manifestes invalides et schémas non HTTP', () {
    final base = Uri.parse('https://example.test/a.m3u8');
    expect(() => rewriteHlsManifest('pas HLS', base, (u) => u),
        throwsFormatException);
    expect(() => rewriteHlsManifest('#EXTM3U\nfile:///secret', base, (u) => u),
        throwsFormatException);
    expect(
        () => rewriteHlsManifest(
            '#EXTM3U\n#EXT-X-KEY:URI="data:text/plain,x"', base, (u) => u),
        throwsFormatException);
    expect(
        () => rewriteHlsManifest(
            r'#EXTM3U' '\n' r'{$token}/segment.ts', base, (u) => u),
        throwsFormatException);
    expect(
        () => rewriteHlsManifest('#EXTM3U\n#EXT-X-KEY:URI=""', base, (u) => u),
        throwsFormatException);
    expect(
        () => rewriteHlsManifest(
            '#EXTM3U\n#EXT-X-UNKNOWN:URI="segment.ts"', base, (u) => u),
        throwsFormatException);
  });
}
