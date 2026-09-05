import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/rust_proxy_manager.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';

void main() {
  group('RustProxyManager constants', () {
    test('defaults align on the listen_addr 127.0.0.1:8787', () {
      expect(kRustProxyPort, 8787);
      expect(kRustProxyBase, 'http://127.0.0.1:$kRustProxyPort');
      expect(RustProxyManager.instance.proxyBase, kRustProxyBase);
      expect(kRustProxyHost, '127.0.0.1');
    });

    test('binary name matches the cargo [[bin]] name', () {
      expect(RustProxyManager.binaryName, 'orbit_proxy_server');
    });

    test('status path matches the axum route', () {
      expect(kRustProxyStatusPath, '/api/proxy-status');
    });

    test('starts idle and not ready, without touching the platform', () {
      final manager = RustProxyManager.instance;
      expect(manager.isReady, isFalse);
      expect(manager.lifecycle, RustProxyLifecycle.idle);
      expect(manager.lastStatus, isNull);
    });

    test('ping returns false when nothing listens (no binary started)',
        () async {
      // Aucun process lancé : la requête échoue proprement sur 127.0.0.1.
      expect(await RustProxyManager.instance.ping(), isFalse);
    });
  });

  group('RustProxyStatus', () {
    test('parses the proxy-status JSON keys', () {
      final status = RustProxyStatus.fromJson(const <String, dynamic>{
        'status': 'running',
        'port': 8787,
        'cache_hit_ratio': 0.42,
        'segments_cached': 17,
        'proxy_mode': 'cloudflare-tls-impersonation',
      });
      expect(status.status, 'running');
      expect(status.port, 8787);
      expect(status.cacheHitRatio, closeTo(0.42, 0.0001));
      expect(status.segmentsCached, 17);
      expect(status.proxyMode, 'cloudflare-tls-impersonation');
    });

    test('tolerates missing keys', () {
      final status = RustProxyStatus.fromJson(const <String, dynamic>{});
      expect(status.status, 'unknown');
      expect(status.port, 0);
      expect(status.segmentsCached, 0);
    });
  });
}
