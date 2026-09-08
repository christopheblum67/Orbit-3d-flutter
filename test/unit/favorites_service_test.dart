import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';

void main() {
  late Directory tempDir;

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
      final entry = FavoriteEntry(
        type: ContentType.live,
        id: '42',
        title: 'TF1',
        posterUrl: 'http://img/tf1.png',
        subtitle: 'Généralistes',
        streamUrl: 'http://cdn/live/42.ts',
      );
      await service.save(entry);

      final all = await service.loadAll();
      expect(all, [entry]);
    });

    test('isFavorite par clé canonique "type:id"', () async {
      expect(await service.isFavorite('live:42'), isFalse);

      await service
          .save(FavoriteEntry(type: ContentType.live, id: '42', title: 'TF1'));

      expect(await service.isFavorite('live:42'), isTrue);
      expect(await service.isFavorite('vod:42'), isFalse);
    });

    test('remove ne supprime que la clé visée', () async {
      await service
          .save(FavoriteEntry(type: ContentType.live, id: '42', title: 'TF1'));
      await service
          .save(FavoriteEntry(type: ContentType.vod, id: '7', title: 'Film'));

      await service.remove('live:42');

      expect(await service.isFavorite('live:42'), isFalse);
      expect(await service.isFavorite('vod:7'), isTrue);
      expect((await service.loadAll()).length, 1);
    });

    test('ignore les entrées corrompues ou non-mapping', () async {
      final box = Hive.box<String>('favorites');
      await box.put('live:1', 'pas du json');
      await box.put('live:2', jsonEncode([1, 2, 3]));
      await box.put(
          'live:3', jsonEncode({'type': 'live', 'id': '3', 'title': 'Bonus'}));

      final all = await service.loadAll();
      expect(all.length, 1);
      expect(all.single.title, 'Bonus');
    });
  });

  group('FavoritesNotifier (réactivité)', () {
    test('toggle ajoute puis retire, et persiste en Hive', () async {
      final service = FavoritesService();
      await service.init();
      await service.save(
        FavoriteEntry(type: ContentType.live, id: '1', title: 'Chaîne 1'),
      );

      final container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
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

      final entry = FavoriteEntry(
        type: ContentType.vod,
        id: '9',
        title: 'Un film',
        streamUrl: 'http://cdn/vod/9.mkv',
      );
      await notifier.toggle(entry);

      expect(notifier.forType(ContentType.vod).length, 1);
      expect(await service.isFavorite('vod:9'), isTrue);

      await notifier.toggle(entry);

      expect(notifier.forType(ContentType.vod), isEmpty);
      expect(await service.isFavorite('vod:9'), isFalse);
      expect(notifier.forType(ContentType.live).length, 1);
    });

    test('forType renvoie les favoris du plus récent au plus ancien', () async {
      final service = FavoritesService();
      await service.init();

      final container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      for (var i = 0;
          i < 100 && notifier.forType(ContentType.vod).isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final first = FavoriteEntry(
        type: ContentType.vod,
        id: 'a',
        title: 'Ajouté en premier',
        streamUrl: 'http://cdn/vod/a.mkv',
      );
      final second = FavoriteEntry(
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
        FavoriteEntry(type: ContentType.live, id: '1', title: 'TF1'),
      );
      await notifier.toggle(
        FavoriteEntry(type: ContentType.live, id: '2', title: 'France 2'),
      );

      await notifier.clearAll();

      expect(container.read(favoritesProvider), isEmpty);
      expect(await service.loadAll(), isEmpty);
    });
  });
}
