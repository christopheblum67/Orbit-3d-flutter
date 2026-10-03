import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé API OpenSubtitles, pour la recherche de sous-titres en ligne.
///
/// ## Où est stockée la clé
///
/// Uniquement dans les préférences de l'application, saisies UNE fois depuis
/// les réglages. Elle n'est jamais écrite dans le code ni dans un commit : une
/// clé d'API en dur dans le dépôt finit par fuiter, et celle-ci permet de
/// consommer le quota de téléchargement d'un compte.
///
/// ## Pourquoi c'est facultatif
///
/// L'API autorise la recherche anonyme, limitée à 5 téléchargements par IP et
/// par 24 h. La clé lève ce plafond et permet le `/login` pour aller jusqu'à
/// 20 par jour. L'application reste donc utilisable sans clé — seulement moins
/// generous.
class OpenSubtitlesKeyStore {
  OpenSubtitlesKeyStore._();

  static final OpenSubtitlesKeyStore instance = OpenSubtitlesKeyStore._();

  /// Volontairement préfixé `opensubtitles_` pour ne jamais entrer en collision
  /// avec les autres clés stockées.
  static const String _prefsKey = 'opensubtitles_api_key';

  String _key = '';

  /// Clé saisie par l'utilisateur. Vide si l'utilisateur en est au mode
  /// anonyme.
  String get apiKey => _key;

  bool get hasKey => _key.isNotEmpty;

  /// Charge la clé persistée (appelé au démarrage de l'application).
  Future<void> load() async {
    final result = await safeAsync<String>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_prefsKey) ?? '';
      },
      context: 'OpenSubtitlesKeyStore.load',
      fallbackValue: '',
    );
    _key = result.valueOrNull ?? '';
  }

  /// Persiste la clé. Une valeur vide efface le réglage et repasse en anonyme.
  Future<void> setApiKey(String value) async {
    _key = value.trim();
    await safeAsync<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        if (_key.isEmpty) {
          await prefs.remove(_prefsKey);
        } else {
          await prefs.setString(_prefsKey, _key);
        }
      },
      context: 'OpenSubtitlesKeyStore.setApiKey',
    );
  }
}
