import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_key_store.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifiants du compte OpenSubtitles, pour les téléchargements authentifiés.
///
/// ## Limite de sécurité — à lire avant d'utiliser cette classe
///
/// L'IDENTIFIANT (public, non sensible) reste dans SharedPreferences. Le MOT
/// DE PASSE vit dans le coffre [SecretStore] (chiffrement Keystore Android) :
/// il a quitté SharedPreferences — où il était stocké EN CLAIR — lors de la
/// migration S1. Règle inchangée : le mot de passe ne doit JAMAIS être
/// journalisé, ni sa valeur ni une partie.
@immutable
class OpenSubtitlesCredentials {
  const OpenSubtitlesCredentials({this.username = '', this.password = ''});

  /// Identifiant du compte. Vide = aucun compte configuré.
  final String username;

  /// Mot de passe du compte. JAMAIS journalisé.
  final String password;

  /// Aucun compte exploitable : il manque l'identifiant ou le mot de passe.
  bool get isEmpty => username.trim().isEmpty || password.isEmpty;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      other is OpenSubtitlesCredentials &&
      other.username == username &&
      other.password == password;

  @override
  int get hashCode => Object.hash(username, password);

  @override
  String toString() =>
      'OpenSubtitlesCredentials(username: ${username.isEmpty ? 'vide' : 'présent'}, '
      'password: ${password.isEmpty ? 'vide' : 'présent'})';
}

/// Stockage des identifiants du compte OpenSubtitles.
///
/// Patron du [OpenSubtitlesKeyStore] : singleton, écriture dans
/// [SharedPreferences], et lectures protégées par [safeAsync].
class OpenSubtitlesCredentialsStore {
  OpenSubtitlesCredentialsStore._();

  static final OpenSubtitlesCredentialsStore instance =
      OpenSubtitlesCredentialsStore._();

  /// Volontairement préfixés `opensubtitles_` pour ne jamais entrer en
  /// collision avec les autres clés stockées. Le mot de passe vit dans le
  /// coffre ; la clé `_passwordPrefsKey` ne sert qu'à la migration S1 (et doit
  /// rester vide après).
  static const String _usernamePrefsKey = 'opensubtitles_username';
  static const String _passwordPrefsKey = 'opensubtitles_password';

  OpenSubtitlesCredentials _credentials = const OpenSubtitlesCredentials();

  /// Identifiants persistés. Vides = aucun compte configuré.
  OpenSubtitlesCredentials get credentials => _credentials;

  bool get hasCredentials => _credentials.isNotEmpty;

  /// Charge les identifiants persistés (appelé au démarrage de l'application).
  ///
  /// Le mot de passe vient du coffre ; une valeur encore présente dans les
  /// préférences provient d'une version antérieure (stockage en clair) et est
  /// migrée puis retirée.
  Future<void> load() async {
    final result = await safeAsync<OpenSubtitlesCredentials>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        // Même nettoyage que la clé API : un identifiant collé depuis une
        // page web peut transporter des invisibles qui le rendent invalide.
        final username = OpenSubtitlesKeyStore.sanitise(
          prefs.getString(_usernamePrefsKey) ?? '',
        );
        var password =
            (await secretStore.read(_passwordPrefsKey))?.trim() ?? '';
        if (password.isEmpty) {
          final legacy = prefs.getString(_passwordPrefsKey);
          if (legacy != null && legacy.isNotEmpty) {
            // Le mot de passe ne subit QUE `trim()` : jamais de retrait des
            // espaces INTERNES, un mot de passe peut légitimement en contenir.
            password = legacy.trim();
            await secretStore.write(_passwordPrefsKey, password);
            await prefs.remove(_passwordPrefsKey);
          }
        }
        return OpenSubtitlesCredentials(
          username: username,
          password: password,
        );
      },
      context: 'OpenSubtitlesCredentialsStore.load',
      fallbackValue: const OpenSubtitlesCredentials(),
    );
    _credentials = result.valueOrNull ?? const OpenSubtitlesCredentials();
  }

  /// Persiste les identifiants. Des valeurs vides effacent le compte.
  Future<void> setCredentials(OpenSubtitlesCredentials credentials) async {
    _credentials = OpenSubtitlesCredentials(
      username: OpenSubtitlesKeyStore.sanitise(credentials.username),
      password: credentials.password.trim(),
    );
    await safeAsync<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        if (_credentials.username.isEmpty) {
          await prefs.remove(_usernamePrefsKey);
        } else {
          await prefs.setString(_usernamePrefsKey, _credentials.username);
        }
        if (_credentials.password.isEmpty) {
          await secretStore.delete(_passwordPrefsKey);
        } else {
          await secretStore.write(_passwordPrefsKey, _credentials.password);
        }
      },
      context: 'OpenSubtitlesCredentialsStore.setCredentials',
    );
  }

  /// Efface le compte enregistré.
  Future<void> clear() async =>
      setCredentials(const OpenSubtitlesCredentials());

  /// Vide l'état en MÉMOIRE, sans toucher aux préférences. Pour les tests d'un
  /// singleton qu'on ne peut pas reconstruire.
  void reset() {
    _credentials = const OpenSubtitlesCredentials();
  }
}