import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/models/m3u_playlist.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';
import 'package:orbit_3d_flutter/services/playlist_fetch_service.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _FailingApi extends ApiService {
  @override
  Future<Response<dynamic>> get(String url) async {
    throw Exception('réseau simulé en échec');
  }
}

class _RejectedApi extends ApiService {
  @override
  Future<Response<dynamic>> get(String url) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: {
          'user_info': {'auth': 0},
        },
        statusCode: 200,
      );
}

class _SuccessfulApi extends ApiService {
  int expiryCalls = 0;

  @override
  Future<Response<dynamic>> get(String url) async => Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: <dynamic>[],
        statusCode: 200,
      );

  @override
  Future<DateTime?> fetchExpiration() async {
    expiryCalls++;
    return DateTime(2030);
  }
}

class _PlaylistApi extends ApiService {
  _PlaylistApi(this.body, this.directory);

  final String body;
  final Directory directory;

  @override
  Future<M3uPlaylist> fetchM3uPlaylist(String url) => PlaylistFetchService(
        cache: ConditionalPlaylistCache(directory: () async => directory),
        log: (_) {},
        get: (url, {options}) async => Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          statusCode: 200,
          data: body,
        ),
      ).fetch(url);
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
    expect(
      state.single.lastTestError,
      contains('Configuration Xtream incomplète'),
    );

    // `addSubscription` déclenche `refreshValidity` SANS `await` (tâche en
    // feu-et-oubli qui appelle le vrai ApiService) : sans ce délai, la tâche
    // survit au tearDown, ferme Hive en dessous d'elle et corrompt le test
    // suivant (« Box has already been closed »). On lui laisse le temps de
    // se terminer dans le test courant.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('testConnection signale une erreur réseau via une API injectée',
      () async {
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

    // Même tâche `refreshValidity` lancée sans `await` par `addSubscription` :
    // on la laisse se terminer dans le test courant (voir test précédent).
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('testConnection détecte des identifiants refusés malgré HTTP 200',
      () async {
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(subscriptionsProvider.notifier);
    final sub = Subscription(
      id: 'rejected',
      name: 'Test',
      type: SubscriptionType.xtream,
      baseUrl: 'https://example.test',
      username: 'user',
      password: 'pass',
      createdAt: DateTime.now(),
    );
    await notifier.addSubscription(sub);
    await notifier.testConnection(sub, api: _RejectedApi());
    expect(container.read(subscriptionsProvider).single.lastTestResult,
        TestResultStatus.error);
  });

  for (final example in [
    (name: 'réponse vide', body: '', success: false),
    (name: 'page HTML', body: '<html>Erreur</html>', success: false),
    (name: 'playlist sans entrées', body: '#EXTM3U\n', success: false),
    (
      name: 'chaîne',
      body: '#EXTM3U\n#EXTINF:-1,Chaîne\nhttps://example.test/live\n',
      success: true
    ),
    (
      name: 'film',
      body: '#EXTM3U\n#EXTINF:-1 group-title="Films",Film\n'
          'https://example.test/movie/film.mp4\n',
      success: true
    ),
    (
      name: 'série',
      body: '#EXTM3U\n#EXTINF:-1 group-title="Series",Série S01E01\n'
          'https://example.test/series/episode.mp4\n',
      success: true
    ),
    (
      name: 'radio',
      body: '#EXTM3U\n#EXTINF:-1 tvg-type="radio",Radio\n'
          'https://example.test/radio\n',
      success: true
    ),
  ]) {
    test('testConnection M3U : ${example.name}', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(subscriptionsProvider.notifier);
      final sub = Subscription(
        id: 'm3u',
        name: 'Test',
        type: SubscriptionType.m3u,
        m3uUrl: 'https://example.test/playlist',
        createdAt: DateTime.now(),
      );
      await notifier.addSubscription(sub);
      await notifier.testConnection(sub,
          api: _PlaylistApi(example.body, tempDir));
      final result = container.read(subscriptionsProvider).single;
      expect(result.lastTestResult,
          example.success ? TestResultStatus.success : TestResultStatus.error);
      if (!example.success) expect(result.lastTestError, contains('vide'));
    });
  }

  test(
      'le test d’un abonnement inactif ne récupère pas la date du compte actif',
      () async {
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(subscriptionsProvider.notifier);
    final sub = Subscription(
      id: 'inactive',
      name: 'Test',
      type: SubscriptionType.xtream,
      baseUrl: 'https://example.test',
      username: 'user',
      password: 'pass',
      createdAt: DateTime.now(),
    );
    final api = _SuccessfulApi();
    await notifier.addSubscription(sub);
    await notifier.testConnection(sub, api: api);
    expect(container.read(subscriptionsProvider).single.lastTestResult,
        TestResultStatus.success);
    expect(container.read(subscriptionsProvider).single.validUntil, isNull);
    expect(api.expiryCalls, 0);
  });
}
