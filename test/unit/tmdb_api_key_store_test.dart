import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/tmdb_api_key_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('override vide => on retombe sur la clé partagée (sans .env en test)', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = TmdbApiKeyOverrideNotifier();
    await notifier.load();

    expect(notifier.state, isEmpty);
    // Pas de .env chargé en test : la clé effective est vide aussi.
    expect(TmdbApiKeyStore.instance.effectiveKey, isEmpty);
  });

  test('override persisté et rechargé', () async {
    SharedPreferences.setMockInitialValues({
      'tmdb_api_key_override': 'ma-cle-tmdb',
    });
    final notifier = TmdbApiKeyOverrideNotifier();
    await notifier.load();

    expect(notifier.state, 'ma-cle-tmdb');
    expect(TmdbApiKeyStore.instance.effectiveKey, 'ma-cle-tmdb');
  });

  test('setOverride enregistre puis vide le réglage', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = TmdbApiKeyOverrideNotifier();
    await notifier.load();

    await notifier.setOverride('  abc123  ');
    expect(notifier.state, 'abc123');
    expect(TmdbApiKeyStore.instance.effectiveKey, 'abc123');

    // Effacer la clé restaure la valeur vide.
    await notifier.setOverride('');
    expect(notifier.state, isEmpty);
    expect(TmdbApiKeyStore.instance.effectiveKey, isEmpty);
  });
}