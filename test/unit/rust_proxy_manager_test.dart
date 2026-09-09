import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/services/rust_proxy_manager.dart';

void main() {
  group('RustProxyStatus.fromJson', () {
    test('parse tous les champs, y compris WAF/re-bootstrap', () {
      final status = RustProxyStatus.fromJson(const <String, dynamic>{
        'status': 'running',
        'port': 8787,
        'cache_hit_ratio': 0.42,
        'segments_cached': 12,
        'proxy_mode': 'cloudflare-tls-impersonation',
        'waf_blocks': 7,
        'upstream_fallback_retries': 3,
        'session_resets': 1,
      });

      expect(status.status, 'running');
      expect(status.port, 8787);
      expect(status.cacheHitRatio, 0.42);
      expect(status.segmentsCached, 12);
      expect(status.proxyMode, 'cloudflare-tls-impersonation');
      expect(status.wafBlocks, 7);
      expect(status.upstreamFallbackRetries, 3);
      expect(status.sessionResets, 1);
    });

    test('défaut à 0 sur les nouveaux champs si absents (proxy antérieur)', () {
      final status = RustProxyStatus.fromJson(const <String, dynamic>{
        'status': 'running',
        'port': 8787,
        'cache_hit_ratio': 0.1,
        'segments_cached': 4,
        'proxy_mode': 'cloudflare-tls-impersonation',
      });

      expect(status.wafBlocks, 0);
      expect(status.upstreamFallbackRetries, 0);
      expect(status.sessionResets, 0);
    });

    test('tolère le type numérique (Double vs Int) sur waf_blocks', () {
      final status = RustProxyStatus.fromJson(const <String, dynamic>{
        'status': 'running',
        'port': 8787,
        'cache_hit_ratio': 0.0,
        'segments_cached': 0,
        'proxy_mode': '',
        'waf_blocks': 4.0,
        'upstream_fallback_retries': 2.0,
        'session_resets': 0.0,
      });

      expect(status.wafBlocks, 4);
      expect(status.upstreamFallbackRetries, 2);
    });
  });

  group('seuils de renewal proactif', () {
    test('constantes cohérentes (guard anti-boucle > relance simple)', () {
      expect(
        RustProxyManager.wafBlockRestartThreshold,
        greaterThan(1),
      );
      expect(
        RustProxyManager.maxSessionResets,
        greaterThanOrEqualTo(1),
      );
      expect(
        RustProxyManager.maxSessionResets,
        lessThanOrEqualTo(RustProxyManager.maxRestartAttempts * 2),
      );
    });
  });
}