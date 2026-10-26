import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStorageService extends StorageService {
  _MemoryStorageService(this.subscriptions);

  final List<Subscription> subscriptions;

  @override
  Future<void> migrateFromSharedPreferences() async {}

  @override
  Future<List<Subscription>> getSubscriptions() async => subscriptions;

  @override
  Future<void> saveSubscription(Subscription subscription) async {
    final index = subscriptions.indexWhere(
      (item) => item.id == subscription.id,
    );
    if (index == -1) {
      subscriptions.add(subscription);
    } else {
      subscriptions[index] = subscription;
    }
  }

  @override
  Subscription? getActiveSubscriptionSync() {
    for (final subscription in subscriptions) {
      if (subscription.isActive) return subscription;
    }
    return null;
  }
}

Subscription _subscription(
  String id, {
  required bool active,
  SubscriptionType type = SubscriptionType.m3u,
}) =>
    Subscription(
      id: id,
      name: id,
      type: type,
      baseUrl: type == SubscriptionType.xtream ? 'https://$id.example' : null,
      username: type == SubscriptionType.xtream ? 'user' : null,
      password: type == SubscriptionType.xtream ? 'password' : null,
      m3uUrl:
          type == SubscriptionType.m3u ? 'https://$id.example/list.m3u' : null,
      isActive: active,
      createdAt: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    replaysCache.invalidate();
    channelReplaysCache.invalidate();
  });

  test('le changement recharge le catalogue et invalide les caches', () async {
    final storage = _MemoryStorageService([
      _subscription('old', active: true),
      _subscription('new', active: false),
    ]);
    final api = ApiService();
    var channelLoads = 0;
    api.rateLimiter.onRateLimited(null);
    expect(api.rateLimiter.isCoolingDown, isTrue);

    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        apiServiceProvider.overrideWithValue(api),
        liveChannelsProvider.overrideWith((ref) async {
          channelLoads++;
          return <Channel>[];
        }),
      ],
    );
    addTearDown(container.dispose);

    final channelSubscription = container.listen(
      liveChannelsProvider,
      (_, __) {},
    );
    await container.read(liveChannelsProvider.future);
    expect(channelLoads, 1);

    final staleShortEpg = container.read(shortEpgCacheProvider)
      ..put('channel-id', const []);
    final staleEpgData = container.read(epgDataCacheProvider);
    container
        .read(lastRefreshTimestampProvider.notifier)
        .setTimestamp(DateTime(2026, 1, 1));
    await replaysCache.fetch(() async => const []);
    channelReplaysCache.put('channel-id', const []);

    expect(staleShortEpg.length, 1);
    expect(replaysCache.peek, isNotNull);
    expect(channelReplaysCache.peek('channel-id'), isNotNull);

    await container.read(subscriptionsProvider.notifier).setActive('new');
    await Future<void>.delayed(Duration.zero);
    await container.read(liveChannelsProvider.future);

    expect(
      container.read(subscriptionsProvider).map((item) => item.isActive),
      [false, true],
    );
    expect(channelLoads, 2);
    expect(container.read(activeSubscriptionProvider)?.id, 'new');
    expect(container.read(lastRefreshTimestampProvider), isNull);
    expect(api.rateLimiter.isCoolingDown, isFalse);
    expect(replaysCache.peek, isNull);
    expect(channelReplaysCache.peek('channel-id'), isNull);
    expect(
      identical(container.read(shortEpgCacheProvider), staleShortEpg),
      isFalse,
    );
    expect(container.read(shortEpgCacheProvider).get('channel-id'), isNull);
    expect(
      identical(container.read(epgDataCacheProvider), staleEpgData),
      isFalse,
    );
    channelSubscription.close();
  });

  test(
    'un abonnement inconnu ou déjà actif ne déclenche pas de bascule',
    () async {
      final storage = _MemoryStorageService([
        _subscription('active', active: true),
        _subscription('other', active: false),
      ]);
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(subscriptionsProvider.notifier);
      await notifier.setActive('missing');
      expect(
        container.read(subscriptionsProvider).map((item) => item.isActive),
        [true, false],
      );

      final api = container.read(apiServiceProvider);
      api.rateLimiter.onRateLimited(null);
      await notifier.setActive('active');
      expect(api.rateLimiter.isCoolingDown, isTrue);
      expect(container.read(activeSubscriptionProvider)?.id, 'active');
    },
  );
}
