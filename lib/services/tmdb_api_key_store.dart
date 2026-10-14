import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé API TMDB pour les classements FlixPatrol.
///
/// Origines, par ordre de priorité :
///  1. Override saisie par l'utilisateur (Réglages → Contenu).
///  2. `TMDB_API_KEY` du fichier `.env` (gitignoré, embarqué dans l'APK).
class TmdbApiKeyStore {
  TmdbApiKeyStore._();

  static final TmdbApiKeyStore instance = TmdbApiKeyStore._();

  static const String _prefsKey = 'tmdb_api_key_override';

  String _override = '';

  /// Override saisi par l'utilisateur (Réglages → Contenu → Clé API TMDB).
  String get override => _override;

  /// Clé effective : override utilisateur sinon `TMDB_API_KEY` du `.env`.
  String get effectiveKey {
    final fromOverride = _override.trim();
    if (fromOverride.isNotEmpty) return fromOverride;
    final result = safeSync<String>(
      () => dotenv.maybeGet('TMDB_API_KEY')?.trim() ?? '',
      context: 'TmdbApiKeyStore.effectiveKey',
      fallbackValue: '',
    );
    return result.valueOrNull ?? '';
  }

  bool get hasEffectiveKey => effectiveKey.isNotEmpty;

  /// Clé dédiée aux résolutions de genre pour le % d'affinité (grille VOD).
  ///
  /// Raison : la grille peut lancer une recherche TMDB par tuile visible. Si ces
  /// requêtes partageaient le quota de la clé principale, elles pourraient
  /// retarder/étouffer les appels TMDB de la fiche détail. En fournissant
  /// `TMDB_API_KEY_AFFINITY` dans le `.env`, l'affinité dispose de son propre
  /// quota. À défaut, on retombe sur la clé effective (override ou
  /// `TMDB_API_KEY`) — la file d'attente reste de toute façon séparée, car
  /// [TmdbService] est instancié dédié pour l'affinité.
  String get affinityKey {
    final dedicated = safeSync<String>(
          () => dotenv.maybeGet('TMDB_API_KEY_AFFINITY')?.trim() ?? '',
          context: 'TmdbApiKeyStore.affinityKey',
          fallbackValue: '',
        ).valueOrNull ??
        '';
    return dedicated.isNotEmpty ? dedicated : effectiveKey;
  }

  /// Charge l'override persistant (appelé au démarrage de l'app).
  ///
  /// Le secret vit dans le coffre ([SecretStore]) ; une valeur encore présente
  /// dans les préférences provient d'une version antérieure (en clair) et est
  /// migrée puis retirée.
  Future<void> load() async {
    final result = await safeAsync<String>(
      () async {
        final secret = await secretStore.read(_prefsKey);
        if (secret != null && secret.isNotEmpty) return secret;
        final prefs = await SharedPreferences.getInstance();
        final legacy = prefs.getString(_prefsKey);
        if (legacy != null && legacy.isNotEmpty) {
          await secretStore.write(_prefsKey, legacy);
          await prefs.remove(_prefsKey);
          return legacy;
        }
        return '';
      },
      context: 'TmdbApiKeyStore.load',
      fallbackValue: '',
    );
    _override = result.valueOrNull ?? '';
  }

  /// Persiste l'override. Une valeur vide efface le réglage.
  Future<void> setOverride(String value) async {
    _override = value.trim();
    await safeAsync<void>(
      () async {
        if (_override.isEmpty) {
          await secretStore.delete(_prefsKey);
        } else {
          await secretStore.write(_prefsKey, _override);
        }
      },
      context: 'TmdbApiKeyStore.setOverride',
    );
  }
}
