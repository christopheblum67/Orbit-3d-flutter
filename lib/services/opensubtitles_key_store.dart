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
/// ## Pourquoi la clé est obligatoire
///
/// Une hypothèse de recherche anonyme avait été écrite ici, sur la foi d'un
/// commentaire de bibliothèque tierce : elle était fausse. `/subtitles` et
/// `/features` exigent tous deux l'en-tête `Api-Key` et répondent 401 sans
/// clé. Le mode anonyme n'existe pas sur cette API.
class OpenSubtitlesKeyStore {
  OpenSubtitlesKeyStore._();

  static final OpenSubtitlesKeyStore instance = OpenSubtitlesKeyStore._();

  /// Volontairement préfixé `opensubtitles_` pour ne jamais entrer en collision
  /// avec les autres clés stockées.
  static const String _prefsKey = 'opensubtitles_api_key';

  String _key = '';

  /// Clé saisie par l'utilisateur. Vide = aucune recherche possible.
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

  /// Persiste la clé. Une valeur vide l'efface : la recherche en ligne devient
  /// alors impossible, l'API refusant toute requête sans clé.
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
