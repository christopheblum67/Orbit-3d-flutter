import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/drm/drm_provider.dart';
import 'package:orbit_3d_flutter/drm/widevine_config_store.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

void main() {
  late InMemorySecretStore secrets;
  late WidevineConfigStore store;

  setUp(() {
    secrets = InMemorySecretStore();
    overrideSecretStoreForTesting(secrets);
    store = WidevineConfigStore.instance;
  });

  tearDown(restoreSecretStoreForTesting);

  test('persists and reloads the global license configuration', () async {
    final config = WidevineConfig(
      licenseUrl: 'https://license.example.test/widevine',
      headers: const {'Authorization': 'Bearer token'},
      certificateBase64: 'Y2VydA==',
    );

    await store.save(config);
    final restored = await store.load();

    expect(restored?.licenseUrl, config.licenseUrl);
    expect(restored?.headers, config.headers);
    expect(restored?.certificateBase64, config.certificateBase64);
  });

  test('removes the stored configuration when cleared', () async {
    await store.save(
      WidevineConfig(licenseUrl: 'https://license.example.test'),
    );

    await store.save(null);

    expect(await store.load(), isNull);
  });

  test('ignores malformed stored configuration', () async {
    await secrets.write('widevine_config', '{invalid');

    expect(await store.load(), isNull);
  });

  test('rejects non-HTTPS license URLs', () async {
    await expectLater(
      store.save(WidevineConfig(licenseUrl: 'http://license.example.test')),
      throwsArgumentError,
    );
  });

  test('provider exposes saved global configuration', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final config = WidevineConfig(
      licenseUrl: 'https://license.example.test/widevine',
    );

    await container.read(widevineConfigProvider.notifier).setConfig(config);

    expect(
      container.read(widevineConfigProvider)?.licenseUrl,
      config.licenseUrl,
    );
  });
}
