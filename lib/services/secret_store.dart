import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Coffre applicatif des secrets (mots de passe, clés API saisies, PIN).
///
/// ## Pourquoi
///
/// Les secrets étaient stockés EN CLAIR dans SharedPreferences (clé OpenSubtitles,
/// mot de passe du compte, override TMDB) et dans Hive (PIN parental, mot de
/// passe Xtream). Un appareil rooté, un backup applicatif ou une lecture du
/// fichier de préférences les lisait tels quels. La migration S1 remplace ces
/// stockages par [flutter_secure_storage] (Android : chiffrement RSA OAEP +
/// AES-GCM, clés protégées par le Keystore).
///
/// ## Injection pour les tests
///
/// Le plugin natif n'existe pas sous `flutter test` : [overrideSecretStoreForTesting]
/// branche [InMemorySecretStore] (fait globalement par `test/flutter_test_config.dart`).
abstract class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Implémentation réelle : [FlutterSecureStorage] (Keystore Android).
class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Migration automatique des anciens algorithmes résistante aux crashes :
      // copie de sauvegarde par clé avant migration, reprise au dernier point.
      migrateWithBackup: true,
    ),
  );

  @override
  Future<String?> read(String key) async {
    final result = await safeAsync<String?>(
      () => _storage.read(key: key),
      context: 'SecretStore.read($key)',
      fallbackValue: null,
    );
    return result.valueOrNull;
  }

  @override
  Future<void> write(String key, String value) async {
    await safeAsync<void>(
      () => _storage.write(key: key, value: value),
      context: 'SecretStore.write($key)',
    );
  }

  @override
  Future<void> delete(String key) async {
    await safeAsync<void>(
      () => _storage.delete(key: key),
      context: 'SecretStore.delete($key)',
    );
  }
}

/// Implémentation en mémoire pour les tests (le canal natif est absent).
class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  /// Vide le coffre (entre deux tests).
  void clearAll() => _values.clear();
}

SecretStore _secretStore = const SecureSecretStore();

/// Coffre actif. Les stores applicatifs (PIN, TMDB, OpenSubtitles, Xtream)
/// passent TOUS par ce point d'injection.
SecretStore get secretStore => _secretStore;

@visibleForTesting
void overrideSecretStoreForTesting(SecretStore store) {
  _secretStore = store;
}

@visibleForTesting
void restoreSecretStoreForTesting() {
  _secretStore = const SecureSecretStore();
}

/// Clé du coffre pour le mot de passe Xtream d'une subscription.
String subscriptionPasswordSecretKey(String subscriptionId) =>
    'xtream_password_$subscriptionId';