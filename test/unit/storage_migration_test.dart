import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_migration_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(SubscriptionAdapter().typeId)) {
      Hive.registerAdapter<Subscription>(SubscriptionAdapter());
    }
    if (!Hive.isAdapterRegistered(SubscriptionTypeAdapter().typeId)) {
      Hive.registerAdapter<SubscriptionType>(SubscriptionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(TestResultStatusAdapter().typeId)) {
      Hive.registerAdapter<TestResultStatus>(TestResultStatusAdapter());
    }
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('migre les anciennes préférences Xtream vers Hive', () async {
    SharedPreferences.setMockInitialValues({
      'active_source': 'xtream',
      'xtream_base_url': 'https://draap.online',
      'xtream_username': 'user1',
      'xtream_password': 'pass1',
    });

    final storage = StorageService();
    await storage.init();
    await storage.migrateFromSharedPreferences();

    final subs = await storage.getSubscriptions();
    expect(subs, hasLength(1));
    expect(subs.first.type, SubscriptionType.xtream);
    expect(subs.first.baseUrl, 'https://draap.online');
    expect(subs.first.username, 'user1');
    expect(subs.first.password, 'pass1');
    expect(subs.first.isActive, isTrue);
  });

  test('migre la playlist M3U vers Hive', () async {
    SharedPreferences.setMockInitialValues({
      'active_source': 'm3u',
      'm3u_url': 'http://example.com/playlist.m3u',
    });

    final storage = StorageService();
    await storage.init();
    await storage.migrateFromSharedPreferences();

    final subs = await storage.getSubscriptions();
    expect(subs, hasLength(1));
    expect(subs.first.type, SubscriptionType.m3u);
    expect(subs.first.m3uUrl, 'http://example.com/playlist.m3u');
    expect(subs.first.isActive, isTrue);
  });

  test('ne migre pas si la box Hive contient déjà des abonnements', () async {
    SharedPreferences.setMockInitialValues({
      'active_source': 'xtream',
      'xtream_base_url': 'https://legacy.example',
      'xtream_username': 'legacy-user',
    });

    final storage = StorageService();
    await storage.init();
    await storage.saveSubscription(
      Subscription(
        id: 'keep-me',
        name: 'Existant',
        type: SubscriptionType.xtream,
        baseUrl: 'https://new.example',
        username: 'new-user',
        createdAt: DateTime.now(),
      ),
    );
    await storage.migrateFromSharedPreferences();

    final subs = await storage.getSubscriptions();
    expect(subs, hasLength(1));
    expect(subs.first.id, 'keep-me');
    expect(subs.first.username, 'new-user');
  });

  test('ne crée rien sans anciennes préférences', () async {
    final storage = StorageService();
    await storage.init();
    await storage.migrateFromSharedPreferences();

    expect(await storage.getSubscriptions(), isEmpty);
  });
}
