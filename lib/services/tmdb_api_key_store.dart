import 'package:shared_preferences/shared_preferences.dart';

/// Clé API TMDB pour les classements FlixPatrol.
///
/// **L'utilisateur doit saisir sa propre clé dans Réglages → Contenu.**
/// Plus de clé de build partagée (`.env`) : évite exposition accidentelle.
class TmdbApiKeyStore {
  TmdbApiKeyStore._();

  static final TmdbApiKeyStore instance = TmdbApiKeyStore._();

  static const String _prefsKey = 'tmdb_api_key_override';

  String _override = '';

  /// Override saisi par l'utilisateur (Réglages → Contenu → Clé API TMDB).
  String get override => _override;

  /// Clé effective à injecter dans les requêtes : **uniquement l'override utilisateur**.
  String get effectiveKey => _override.trim();

  bool get hasEffectiveKey => effectiveKey.isNotEmpty;

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