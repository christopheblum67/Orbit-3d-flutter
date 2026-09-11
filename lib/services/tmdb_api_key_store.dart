import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé API TMDB pour les classements FlixPatrol.
///
/// Priorité à l'override saisi dans Réglages (option A validée), repli sur la
/// clé de build `TMDB_API_KEY` (`.env`). Pas de blocage réseau au démarrage :
/// la clé est lue à chaque requête (intercepteur Dio).
class TmdbApiKeyStore {
  TmdbApiKeyStore._();

  static final TmdbApiKeyStore instance = TmdbApiKeyStore._();

  static const String _prefsKey = 'tmdb_api_key_override';

  String _override = '';

  /// Override saisi par l'utilisateur (Réglages → Classements TMDB).
  String get override => _override;

  /// Clé effective à injecter dans les requêtes : override sinon `.env`.
  String get effectiveKey {
    final overridden = _override.trim();
    if (overridden.isNotEmpty) return overridden;
    return _env('TMDB_API_KEY');
  }

  bool get hasEffectiveKey => effectiveKey.isNotEmpty;

  static String _env(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Charge l'override persistant (appelé au démarrage de l'app).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _override = prefs.getString(_prefsKey) ?? '';
    } catch (_) {
      _override = '';
    }
  }

  /// Persiste l'override. Une valeur vide efface le réglage.
  Future<void> setOverride(String value) async {
    _override = value.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_override.isEmpty) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, _override);
      }
    } catch (_) {
      // Non bloquant : la clé reste en mémoire pour la session.
    }
  }
}