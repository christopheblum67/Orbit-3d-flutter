import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _FailingApi extends ApiService {
  @override
  Future<Response<dynamic>> get(String url) async {
    throw Exception('réseau simulé en échec');
  }
}

void main() {
  late StorageService storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_connection_test');
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

    storage = StorageService();
    await storage.init();
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('_buildXtreamTestUrl construit player_api.php avec credentials', () {
    final url = SubscriptionsNotifier.buildXtreamTestUrl(
      'https://draap.online/',
      'u1',
      'p1',
    );
    expect(
      url,
      'https://draap.online/player_api.php?username=u1&password=p1&action=get_live_streams',
    );
  });

  test('testConnection échoue gentiment si la config Xtream est incomplète',
      () async {
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionsProvider.notifier);
    final sub = Subscription(
      id: 'incomplete',
      name: 'Incomplète',
      type: SubscriptionType.xtream,
      createdAt: DateTime.now(),
    );
    await notifier.addSubscription(sub);

    await notifier.testConnection(sub);

    final state = container.read(subscriptionsProvider);
    expect(state.single.lastTestResult, TestResultStatus.error);
    expect(state.single.lastTestError, contains('Configuration Xtream incomplète'));
  });

  test('testConnection signale une erreur réseau via une API injectée', () async {
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionsProvider.notifier);
    final sub = Subscription(
      id: 'draap',
      name: 'Draap',
      type: SubscriptionType.xtream,
      baseUrl: 'https://draap.online',
      username: 'user',
      password: 'pass',
      createdAt: DateTime.now(),
    );
    await notifier.addSubscription(sub);

    await notifier.testConnection(sub, api: _FailingApi());

    final state = container.read(subscriptionsProvider);
    expect(state.single.lastTestResult, TestResultStatus.error);
    expect(state.single.lastTestError, contains('réseau simulé en échec'));
  });
}