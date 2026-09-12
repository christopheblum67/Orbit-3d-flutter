import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/recently_watched_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recently_watched_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('RecentlyWatchedService', () {
    late RecentlyWatchedService service;

    setUp(() async {
      service = RecentlyWatchedService();
      await service.init();
    });

    test('round-trip save / loadAll, plus récent d\'abord', () async {
      final first = RecentEntry(
        type: ContentType.live,
        id: 'a',
        title: 'TF1',
        profileId: 'test_profile',
        streamUrl: 'http://cdn/live/a.ts',
        watchedAt: DateTime(2026, 9, 7, 10),
      );
      final second = RecentEntry(
        type: ContentType.live,
        id: 'b',
        title: 'France 2',
        profileId: 'test_profile',
        streamUrl: 'http://cdn/live/b.ts',
        watchedAt: DateTime(2026, 9, 7, 11),
      );
      await service.save(first);
      await service.save(second);

      final all = await service.loadAll();
      expect(all.map((e) => e.id), ['b', 'a']);
    });

    test('clearAll vide la box', () async {
      await service.save(RecentEntry(
        type: ContentType.vod,
        id: '1',
        title: 'Film',
        profileId: 'test_profile',
        streamUrl: 'http://x',
        watchedAt: DateTime(2026, 9, 7),
      ),);
      await service.clearAll();
      expect(await service.loadAll(), isEmpty);
    });
  });

  group('RecentlyWatchedNotifier', () {
    test('record remplace le doublon et remonte en tête', () async {
      final service = RecentlyWatchedService();
      await service.init();

      final container = ProviderContainer(
        overrides: [
          recentlyWatchedServiceProvider.overrideWithValue(service),
          currentProfileProvider.overrideWith((ref) => UserProfile(id: 'test_profile', firstName: 'Test', dateOfBirth: DateTime(2000, 1, 1), gender: 'male', favoriteGenres: const [])),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(recentlyWatchedProvider.notifier);
      // Attend la fin du chargement initial asynchrone.
      for (var i = 0;
          i < 100 && container.read(recentlyWatchedProvider).isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await notifier.record(ContentType.live, '1', 'TF1');
      await notifier.record(ContentType.live, '2', 'France 2');
      // Re-lecture de TF1 : remonte en tête, pas de doublon.
      await notifier.record(ContentType.live, '1', 'TF1');

      final typo = notifier.forType(ContentType.live);
      expect(typo.length, 2);
      expect(typo.first.id, '1');
      expect(await service.loadAll(), hasLength(2));
    });
  });
}
