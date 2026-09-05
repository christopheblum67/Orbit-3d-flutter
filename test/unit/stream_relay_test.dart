import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';

void main() {
  group('proxyHashFor', () {
    test('is deterministic for the same url', () {
      const url = 'https://draap.online/video/seg.ts';
      expect(proxyHashFor(url), proxyHashFor(url));
    });

    test('produces 16 lower-hex chars', () {
      expect(
        proxyHashFor('https://draap.online/live/1.m3u8'),
        matches(RegExp(r'^[0-9a-f]{16}$')),
      );
    });

    test('differs between distinct urls', () {
      expect(
        proxyHashFor('https://draap.online/a.ts'),
        isNot(proxyHashFor('https://draap.online/b.ts')),
      );
    });
  });

  group('buildProxyUrl', () {
    test('produces {base}/hls/<hash>/<filename>', () {
      const original = 'https://draap.online/video/segment.ts';
      final url = buildProxyUrl(original);
      expect(url, startsWith('$kRustProxyBase/hls/'));
      expect(url, endsWith('/segment.ts'));
      final hash =
          url.substring('$kRustProxyBase/hls/'.length).split('/').first;
      expect(hash, proxyHashFor(original));
    });

    test('falls back to segment filename when path has no name', () {
      expect(buildProxyUrl('https://draap.online/'), endsWith('/segment'));
    });
  });

  group('isRelayCandidate', () {
    test('matches draap.online exactly', () {
      expect(isRelayCandidate('https://draap.online/live/1.m3u8'), isTrue);
    });

    test('matches subdomains of draap.online', () {
      expect(isRelayCandidate('https://live.draap.online/x/1.m3u8'), isTrue);
    });

    test('rejects other hosts and invalid urls', () {
      expect(isRelayCandidate('https://other.cdn.example/a.ts'), isFalse);
      expect(isRelayCandidate(''), isFalse);
    });
  });

  group('maybeRebaseThroughProxy', () {
    test('returns the original url when the proxy is not ready', () {
      const url = 'https://draap.online/live/1.m3u8';
      expect(maybeRebaseThroughProxy(url, proxyReady: false), url);
    });

    test('relays a manifest through /proxy/hls', () {
      const url = 'https://draap.online/live/1.m3u8';
      final relayed = maybeRebaseThroughProxy(url, proxyReady: true);
      expect(relayed, startsWith('$kRustProxyBase/proxy/hls?url='));
      expect(relayed, contains(Uri.encodeComponent(url)));
    });

    test('relays a segment through /proxy/segment', () {
      const url = 'https://draap.online/live/seg_42.ts';
      final relayed = maybeRebaseThroughProxy(url, proxyReady: true);
      expect(relayed, startsWith('$kRustProxyBase/proxy/segment?url='));
    });

    test('relays a generic media file through /proxy/stream', () {
      const url = 'https://draap.online/movie/15548815/abc123/12345.mkv';
      final relayed = maybeRebaseThroughProxy(url, proxyReady: true);
      expect(relayed, startsWith('$kRustProxyBase/proxy/stream?url='));
    });

    test('leaves non-relay hosts untouched even when ready', () {
      const url = 'https://other.cdn.example/movie/12345.mp4';
      expect(maybeRebaseThroughProxy(url, proxyReady: true), url);
    });

    test('does not double-relay an already relayed url', () {
      const original = 'https://draap.online/live/1.m3u8';
      final first = maybeRebaseThroughProxy(original, proxyReady: true);
      final second = maybeRebaseThroughProxy(first, proxyReady: true);
      expect(second, first);
    });
  });
}
