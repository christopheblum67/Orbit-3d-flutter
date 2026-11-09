import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:orbit_3d_flutter/drm/widevine/widevine_delegate.dart';
import 'package:orbit_3d_flutter/drm/widevine_config_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('secure storage isolates Widevine configurations by subscription',
      (tester) async {
    final store = WidevineConfigStore.instance;
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final firstId = 'integration-first-$suffix';
    final secondId = 'integration-second-$suffix';
    addTearDown(() async {
      await store.saveForSubscription(firstId, null);
      await store.saveForSubscription(secondId, null);
    });

    final first = WidevineConfig(
      licenseUrl: 'https://first.example.test/license',
      headers: const {'Authorization': 'test-first'},
    );
    final second = WidevineConfig(
      licenseUrl: 'https://second.example.test/license',
      headers: const {'Authorization': 'test-second'},
    );

    await store.saveForSubscription(firstId, first);
    await store.saveForSubscription(secondId, second);
    expect((await store.loadForSubscription(firstId))?.headers, first.headers);
    expect(
      (await store.loadForSubscription(secondId))?.headers,
      second.headers,
    );

    await store.saveForSubscription(firstId, null);
    expect(await store.loadForSubscription(firstId), isNull);
    expect(
      (await store.loadForSubscription(secondId))?.headers,
      second.headers,
    );
  });
}
