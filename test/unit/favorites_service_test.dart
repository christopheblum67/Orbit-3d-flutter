import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';

final _activeSubscription =
    NotifierProvider<_ActiveSubscription, Subscription?>(
  _ActiveSubscription.new,
);

class _ActiveSubscription extends Notifier<Subscription?> {
  @override
  Subscription? build() => null;
  void select(Subscription value) => state = value;
}

class _DelayedFavoritesService extends FavoritesService {
  final calls = <String, Completer<List<FavoriteEntry>>>{};

  @override
  Future<List<FavoriteEntry>> loadForSubscription(
    String profileId,
    String subscriptionId, {
    bool Function()? canMigrateLegacy,
  }) =>
      (calls[subscriptionId] ??= Completer<List<FavoriteEntry>>()).future;
}

void main() {
  late Directory tempDir;
  final subscription = Subscription(
    id: 'sub-a',
    name: 'A',
    type: SubscriptionType.m3u,
    createdAt: DateTime(2020),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('favorites_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('FavoritesService', () {
    late FavoritesService service;

    setUp(() async {
      service = FavoritesService();
      await service.init();
    });

    test('round-trip save / loadAll', () async {
      const entry = FavoriteEntry(
        type: ContentType.live,
        id: '42',
        title: 'TF1',
        profileId: 'test_profile',
        posterUrl: 'http://img/tf1.png',
        subtitle: 'Généralistes',
        streamUrl: 'http://cdn/live/42.ts',
      );
      await service.save(entry);

      final all = await service.loadAll();
      expect(all, [entry]);
    });

    test('isFavorite par clé canonique "profile:type:id"', () async {
      expect(await service.isFavorite('test_profile:live:42'), isFalse);

      await service.save(
        const FavoriteEntry(
          type: ContentType.live,
          id: '42',
          title: 'TF1',
          profileId: 'test_profile',
        ),
      );

      expect(await service.isFavorite('test_profile:live:42'), isTrue);
      expect(await service.isFavorite('test_profile:vod:42'), isFalse);
    });

    test('remove ne supprime que la clé visée', () async {
      await service.save(
        const FavoriteEntry(
          type: ContentType.live,
          id: '42',
          title: 'TF1',
          profileId: 'test_profile',
        ),
      );
      await service.save(
        const FavoriteEntry(
          type: ContentType.vod,
          id: '7',
          title: 'Film',
          profileId: 'test_profile',
        ),
      );

      await service.remove('test_profile:live:42');

      expect(await service.isFavorite('test_profile:live:42'), isFalse);
      expect(await service.isFavorite('test_profile:vod:7'), isTrue);
      expect((await service.loadAll()).length, 1);
    });

    test('ignore les entrées corrompues ou non-mapping', () async {
      final box = Hive.box('favorites');
      await box.put('test_profile:live:1', 'pas du json');
      await box.put('test_profile:live:2', jsonEncode([1, 2, 3]));
      await box.put(
        'test_profile:live:3',
        jsonEncode({
          'type': 'live',
          'id': '3',
          'title': 'Bonus',
          'profileId': 'test_profile',
        }),
      );

      final all = await service.loadAll();
      expect(all.length, 1);
      expect(all.single.title, 'Bonus');
    });
  });

  group('FavoritesNotifier (réactivité)', () {
    test('ignore un chargement tardif de l’abonnement précédent', () async {
      final service = _DelayedFavoritesService();
      final other = Subscription(
        id: 'sub-b',
        name: 'B',
        type: SubscriptionType.m3u,
        createdAt: DateTime(2020),
      );
      final container = ProviderContainer(overrides: [
        favoritesServiceProvider.overrideWithValue(service),
        activeSubscriptionProvider
            .overrideWith((ref) => ref.watch(_activeSubscription)),
        subscriptionsProvider
            .overrideWithBuild((ref, notifier) => [subscription, other]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => UserProfile(
              id: 'test_profile',
              firstName: 'Test',
              dateOfBirth: DateTime(2000),
              gender: 'male',
              favoriteGenres: const [],
            )),
      ]);
      addTearDown(container.dispose);
      container.read(_activeSubscription.notifier).select(subscription);
      final notifier = container.read(favoritesProvider.notifier);
      final listener = container.listen(favoritesProvider, (_, __) {});
      addTearDown(listener.close);
      container.read(_activeSubscription.notifier).select(other);
      await container.pump();
      const b = FavoriteEntry(
          type: ContentType.vod,
          id: '42',
          title: 'B',
          profileId: 'test_profile',
          subscriptionId: 'sub-b');
      service.calls['sub-b']!.complete([b]);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.byKey(ContentType.vod, '42')?.title, 'B');
      const a = FavoriteEntry(
          type: ContentType.vod,
          id: '42',
          title: 'A',
          profileId: 'test_profile',
          subscriptionId: 'sub-a');
      service.calls['sub-a']!.complete([a]);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.byKey(ContentType.vod, '42')?.title, 'B');
    });

    test('isole les abonnements et conserve les anciens favoris ambigus',
        () async {
      final service = FavoritesService();
      await service.init();
      final other = Subscription(
        id: 'sub-b',
        name: 'B',
        type: SubscriptionType.m3u,
        createdAt: DateTime(2020),
      );
      const legacy = FavoriteEntry(
        type: ContentType.vod,
        id: 'old',
        title: 'Ancien',
        profileId: 'test_profile',
      );
      await service.save(legacy);
      final container = ProviderContainer(overrides: [
        favoritesServiceProvider.overrideWithValue(service),
        activeSubscriptionProvider
            .overrideWith((ref) => ref.watch(_activeSubscription)),
        subscriptionsProvider
            .overrideWithBuild((ref, notifier) => [subscription, other]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => UserProfile(
              id: 'test_profile',
              firstName: 'Test',
              dateOfBirth: DateTime(2000),
              gender: 'male',
              favoriteGenres: const [],
            )),
      ]);
      addTearDown(container.dispose);
      container.read(_activeSubscription.notifier).select(subscription);
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggle(
          const FavoriteEntry(type: ContentType.vod, id: '42', title: 'A'));
      container.read(_activeSubscription.notifier).select(other);
      await container.pump();
      expect(notifier.isFavorite(ContentType.vod, '42'), isFalse);
      await notifier.toggle(
          const FavoriteEntry(type: ContentType.vod, id: '42', title: 'B'));
      expect(notifier.byKey(ContentType.vod, '42')?.title, 'B');
      await notifier.clearAll();
      container.read(_activeSubscription.notifier).select(subscription);
      await container.pump();
      for (var i = 0;
          i < 50 && !notifier.isFavorite(ContentType.vod, '42');
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(notifier.byKey(ContentType.vod, '42')?.title, 'A');
      expect(await service.isFavorite(legacy.key), isTrue);
      expect((await service.loadAll()).length, 2);
      const synced = FavoriteEntry(
        type: ContentType.vod,
        id: '42',
        title: 'Cloud B',
        profileId: 'test_profile',
        subscriptionId: 'sub-b',
      );
      await notifier.applySyncedProfile([synced], removes: {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifier.byKey(ContentType.vod, '42')?.title, 'A');
      expect(await service.isFavorite(synced.key), isTrue);
      await notifier.applySyncedProfile([], removes: {synced.key});
      expect(await service.isFavorite(synced.key), isFalse);
      expect(await service.isFavorite('test_profile:subscription:sub-a:vod:42'),
          isTrue);
    });

    test('toggle ajoute puis retire, et persiste en Hive', () async {
      final service = FavoritesService();
      await service.init();
      await service.save(
        const FavoriteEntry(
          type: ContentType.live,
          id: '1',
          title: 'Chaîne 1',
          profileId: 'test_profile',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
          activeSubscriptionProvider.overrideWith((ref) => subscription),
          subscriptionsProvider
              .overrideWithBuild((ref, notifier) => [subscription]),
          currentProfileProvider.overrideWithBuild(
            (ref, notifier) => UserProfile(
              id: 'test_profile',
              firstName: 'Test',
              dateOfBirth: DateTime(2000, 1, 1),
              gender: 'male',
              favoriteGenres: const [],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);

      // Attend la fin du chargement initial asynchrone.
      for (var i = 0;
          i < 100 && notifier.forType(ContentType.live).length != 1;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(container.read(favoritesProvider).length, 1);
      expect(notifier.isFavorite(ContentType.live, '1'), isTrue);

      const entry = FavoriteEntry(
        type: ContentType.vod,
        id: '9',
        title: 'Un film',
        streamUrl: 'http://cdn/vod/9.mkv',
      );
      await notifier.toggle(entry);

      expect(notifier.forType(ContentType.vod).length, 1);
      expect(await service.isFavorite('test_profile:subscription:sub-a:vod:9'),
          isTrue);

      await notifier.toggle(entry);

      expect(notifier.forType(ContentType.vod), isEmpty);
      expect(await service.isFavorite('test_profile:subscription:sub-a:vod:9'),
          isFalse);
      expect(notifier.forType(ContentType.live).length, 1);
    });

    test('forType renvoie les favoris du plus récent au plus ancien', () async {
      final service = FavoritesService();
      await service.init();

      final container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
          activeSubscriptionProvider.overrideWith((ref) => subscription),
          subscriptionsProvider
              .overrideWithBuild((ref, notifier) => [subscription]),
          currentProfileProvider.overrideWithBuild(
            (ref, notifier) => UserProfile(
              id: 'test_profile',
              firstName: 'Test',
              dateOfBirth: DateTime(2000, 1, 1),
              gender: 'male',
              favoriteGenres: const [],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      for (var i = 0;
          i < 100 && notifier.forType(ContentType.vod).isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      const first = FavoriteEntry(
        type: ContentType.vod,
        id: 'a',
        title: 'Ajouté en premier',
        streamUrl: 'http://cdn/vod/a.mkv',
      );
      const second = FavoriteEntry(
        type: ContentType.vod,
        id: 'b',
        title: 'Ajouté ensuite',
        streamUrl: 'http://cdn/vod/b.mkv',
      );
      await notifier.toggle(first);
      await notifier.toggle(second);

      final vod = notifier.forType(ContentType.vod);
      expect(vod.map((e) => e.id), ['b', 'a']);
    });

    test('clearAll vide le state et la box Hive', () async {
      final service = FavoritesService();
      await service.init();

      final container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
          activeSubscriptionProvider.overrideWith((ref) => subscription),
          subscriptionsProvider
              .overrideWithBuild((ref, notifier) => [subscription]),
          currentProfileProvider.overrideWithBuild(
            (ref, notifier) => UserProfile(
              id: 'test_profile',
              firstName: 'Test',
              dateOfBirth: DateTime(2000, 1, 1),
              gender: 'male',
              favoriteGenres: const [],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      for (var i = 0;
          i < 100 && notifier.forType(ContentType.vod).isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await notifier.toggle(
        const FavoriteEntry(
          type: ContentType.live,
          id: '1',
          title: 'TF1',
          profileId: 'test_profile',
        ),
      );
      await notifier.toggle(
        const FavoriteEntry(
          type: ContentType.live,
          id: '2',
          title: 'France 2',
          profileId: 'test_profile',
        ),
      );

      await notifier.clearAll();

      expect(container.read(favoritesProvider), isEmpty);
      expect(await service.loadAll(), isEmpty);
    });
  });
}
