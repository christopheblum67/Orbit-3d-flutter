import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé API OpenSubtitles, pour la recherche de sous-titres en ligne.
///
/// ## Où est stockée la clé
///
/// Dans le coffre sécurisé de l'application ([SecretStore], chiffrement
/// Keystore Android), saisie UNE fois depuis les réglages. Elle n'est jamais
/// écrite dans le code ni dans un commit : une clé d'API en dur dans le dépôt
/// finit par fuiter, et celle-ci permet de consommer le quota de
/// téléchargement d'un compte. Une valeur encore présente dans les anciennes
/// préférences (version d'avant la migration S1) est migrée au premier
/// chargement puis retirée.
class OpenSubtitlesKeyStore {
  OpenSubtitlesKeyStore._();

  static final OpenSubtitlesKeyStore instance = OpenSubtitlesKeyStore._();

  /// Volontairement préfixé `opensubtitles_` pour ne jamais entrer en collision
  /// avec les autres clés stockées.
  static const String _prefsKey = 'opensubtitles_api_key';

  String _key = '';

  /// Clé API saisie par l'utilisateur. Vide = recherche anonyme, au quota
  /// bien plus bas (l'API reste utilisable sans clé, contrairement à ce que
  /// affirmait l'ancienne version de ce fichier).
  String get apiKey => _key;

  bool get hasKey => _key.isNotEmpty;

  /// Nettie une clé collée avant stockage.
  ///
  /// ## Pourquoi
  ///
  /// `String.trim()` ne supprime que les espaces de BORD, et seulement ceux
  /// qu'il connaît. Une clé recopiée depuis une page web arrive très souvent
  /// entourée ou truffée de caractères INVISIBLES : espace insécable, zéro-espace,
  /// tiret doux, marques bidirectionnelles, BOM. Le stockage les conservait, et
  /// l'API répondait alors `401` sur une clé pourtant parfaitement correcte.
  ///
  /// Or pour l'utilisateur, un 401 est indiscernable d'une clé fausse : il
  /// ressaisit la même clé et le même 401 revient, indéfiniment.
  ///
  /// ## Choix d'écriture
  ///
  /// Les caractères sont énumérés par CODE DE POINT et non comme littéraux. Un
  /// caractère invisible écrit dans le source est indétectable à la relecture,
  /// se casse au premier changement d'encodage CRLF/LF, et — bien pire — on ne
  /// peut plus le distinguer d'un caractère « propre » en relisant le fichier.
  /// Un entier reste lisible et vérifiable.
  ///
  /// Les espaces INTERNES sont retirés aussi : une clé coupée en deux par un
  /// retour à la ligne, c'est de la mise en forme, pas du contenu.
  static String sanitise(String value) {
    const invisibles = <int>{
      0x0009, // tabulation
      0x000A, // fin de ligne
      0x000B, // saut de ligne verticale
      0x000C, // saut de page
      0x000D, // retour chariot
      0x0020, // espace
      0x00A0, // espace insécable
      0x00AD, // tiret doux
      0x200B, // zéro-espace
      0x200C, // zéro-espace non-jonctionneur
      0x200D, // zéro-espace joncteur
      0x200E, // marque gauche-à-droite
      0x200F, // marque droite-à-gauche
      0x2028, // séparateur de ligne : rien à l'écran
      0x2029, // séparateur de paragraphe : rien à l'écran
      0x202A, 0x202B, 0x202C, 0x202D, 0x202E, // isolants bidirectionnels
      0x2060, // « mot insécable »
      0xFEFF, // BOM
    };
    final out = StringBuffer();
    for (final rune in value.runes) {
      if (invisibles.contains(rune)) continue;
      out.writeCharCode(rune);
    }
    return out.toString();
  }

  /// Charge la clé persistée (appelé au démarrage de l'application).
  ///
  /// La clé vit dans le coffre ([SecretStore]) ; une valeur encore présente
  /// dans les préférences provient d'une version antérieure (stockage en
  /// clair) et est migrée puis retirée.
  Future<void> load() async {
    final result = await safeAsync<String>(
      () async {
        final secret = await secretStore.read(_prefsKey);
        if (secret != null && secret.isNotEmpty) return sanitise(secret);
        final prefs = await SharedPreferences.getInstance();
        final legacy = prefs.getString(_prefsKey);
        if (legacy != null && legacy.isNotEmpty) {
          // Une clé enregistrée AVANT l'introduction de [sanitise] peut encore
          // contenir des invisibles : on ne la ressort pas telle quelle.
          final clean = sanitise(legacy);
          await secretStore.write(_prefsKey, clean);
          await prefs.remove(_prefsKey);
          return clean;
        }
        return '';
      },
      context: 'OpenSubtitlesKeyStore.load',
      fallbackValue: '',
    );
    _key = result.valueOrNull ?? '';
  }

  /// Persiste la clé. Une valeur vide l'efface : la recherche en ligne devient
  /// alors anonyme, au quota plus bas mais non nul.
  Future<void> setApiKey(String value) async {
    _key = sanitise(value);
    await safeAsync<void>(
      () async {
        if (_key.isEmpty) {
          await secretStore.delete(_prefsKey);
        } else {
          await secretStore.write(_prefsKey, _key);
        }
      },
      context: 'OpenSubtitlesKeyStore.setApiKey',
    );
  }
}