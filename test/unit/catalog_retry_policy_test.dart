import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/catalog_retry_policy.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

class _PlaylistApi extends ApiService {
  _PlaylistApi(this.failures);

  final List<Object> failures;
  int calls = 0;

  @override
  Future<M3uPlaylist> fetchM3uPlaylist(String url) async {
    calls++;
    if (calls <= failures.length) throw failures[calls - 1];
    return const M3uPlaylist(channels: [], radios: [], movies: [], series: []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ordinary errors have three bounded exponential retries', () {
    final error = StateError('offline');
    expect(
      List.generate(5, (count) => catalogRetryUnlessRateLimited(count, error)),
      [
        const Duration(milliseconds: 200),
        const Duration(milliseconds: 400),
        const Duration(milliseconds: 800),
        null,
        null,
      ],
    );
  });

  test('rate limits never retry, including wrapped panel errors', () {
    final errors = [
      StateError('HTTP 429'),
      StreamNetworkException('Limite de requêtes dépassée'),
      StreamNetworkException('request failed', original: Exception('429')),
    ];
    for (final error in errors) {
      for (var count = 0; count <= 3; count++) {
        expect(catalogRetryUnlessRateLimited(count, error), isNull);
      }
    }
  });

  ProviderContainer containerFor(_PlaylistApi api) {
    final sub = Subscription(
      id: 'm3u',
      name: 'playlist',
      type: SubscriptionType.m3u,
      m3uUrl: 'https://example.test/playlist',
      createdAt: DateTime(2026),
    );
    return ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(api),
        activeSubscriptionProvider.overrideWithValue(sub),
      ],
    );
  }

  test('playlist provider retries a transient failure', () async {
    final api = _PlaylistApi([StateError('offline')]);
    final container = containerFor(api);
    addTearDown(container.dispose);
    final listener = container.listen(m3uPlaylistProvider, (_, __) {});
    addTearDown(listener.close);
    await container.read(m3uPlaylistProvider.future);
    expect(api.calls, 2);
  });

  test('playlist provider does not retry a rate limit', () async {
    final api = _PlaylistApi([StreamNetworkException('HTTP 429')]);
    final container = containerFor(api);
    addTearDown(container.dispose);
    final listener = container.listen(m3uPlaylistProvider, (_, __) {});
    addTearDown(listener.close);
    await expectLater(
      container.read(m3uPlaylistProvider.future),
      throwsA(isA<StreamNetworkException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(api.calls, 1);
  });

  test('playlist provider stops after three retries', () async {
    final api = _PlaylistApi(List.generate(4, (_) => StateError('offline')));
    final container = containerFor(api);
    addTearDown(container.dispose);
    final listener = container.listen(m3uPlaylistProvider, (_, __) {});
    addTearDown(listener.close);
    await expectLater(
      container.read(m3uPlaylistProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(api.calls, 4);
  });
}
