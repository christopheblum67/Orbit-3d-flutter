import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:orbit_3d_flutter/services/tmdb_api_key_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    overrideSecretStoreForTesting(InMemorySecretStore());
  });

  tearDown(restoreSecretStoreForTesting);

  test('override vide => on retombe sur la clé partagée (sans .env en test)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tmdbApiKeyOverrideProvider);
    final notifier = container.read(tmdbApiKeyOverrideProvider.notifier);
    await notifier.load();

    expect(notifier.state, isEmpty);
    // Pas de .env chargé en test : la clé effective est vide aussi.
    expect(TmdbApiKeyStore.instance.effectiveKey, isEmpty);
  });

  test('override persisté et rechargé (migré depuis les préférences legacy)',
      () async {
    // Valeur écrite par l'ancienne version du code (préférences en clair) :
    // le chargement doit la migrer vers le coffre puis la relire de là.
    SharedPreferences.setMockInitialValues({
      'tmdb_api_key_override': 'ma-cle-tmdb',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tmdbApiKeyOverrideProvider);
    final notifier = container.read(tmdbApiKeyOverrideProvider.notifier);
    await notifier.load();

    expect(notifier.state, 'ma-cle-tmdb');
    expect(TmdbApiKeyStore.instance.effectiveKey, 'ma-cle-tmdb');
    expect(
      await secretStore.read('tmdb_api_key_override'),
      'ma-cle-tmdb',
      reason: 'l\'override doit vivre dans le coffre sécurisé',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tmdb_api_key_override'), isNull);
  });

  test('setOverride enregistre puis vide le réglage', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tmdbApiKeyOverrideProvider);
    final notifier = container.read(tmdbApiKeyOverrideProvider.notifier);
    await notifier.load();

    await notifier.setOverride('  abc123  ');
    expect(notifier.state, 'abc123');
    expect(TmdbApiKeyStore.instance.effectiveKey, 'abc123');
    expect(
      await secretStore.read('tmdb_api_key_override'),
      'abc123',
      reason: 'la saisie est écrite dans le coffre',
    );

    // Effacer la clé restaure la valeur vide.
    await notifier.setOverride('');
    expect(notifier.state, isEmpty);
    expect(TmdbApiKeyStore.instance.effectiveKey, isEmpty);
    expect(await secretStore.read('tmdb_api_key_override'), isNull);
  });
}
