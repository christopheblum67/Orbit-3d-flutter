import 'dart:convert';

/// Décodage des textes encodés en base64 par les panels.
///
/// ## Pourquoi c'est centralisé
///
/// Certains panels encodent en base64 les titres, descriptifs et noms qu'ils
/// publient. Le défaut de conception qui rendait ce problème ingérable : le
/// décodage était appliqué **au cas par cas**, à l'endroit où l'on se
/// trouvait quand le bug a été signalé. Trois fois dans la même soirée, un
/// chemin oublié a suffi à afficher « TxkgTWlsbGlvbg== » à côté de champs
/// corrects — films, replays, EPG.
///
/// La règle est donc inverse : le décodage vit dans les fabriques de modèles
/// (`fromMap`), qui sont le point de contact unique avec le panel. Un nouveau
/// champ passe par là, donc il est décodé sans qu'on y pense.
///
/// ## Prudence
///
/// Le décodage n'est jamais forcé. Une valeur est décodée seulement si elle
/// EST du base64 valide **et** que le résultat ressemble à du texte ; sinon la
/// valeur d'origine est conservée. Sans ces garde-fous, un titre en clair qui
/// ressemble à du base64 — « Actu », « News » — serait corrompu.
class PanelText {
  const PanelText._();

  /// Longueur minimale pour être candidat : en dessous, le rapport signal/bruit
  /// n'est pas favorable et le risque de faux positif augmente.
  static const int _minLength = 8;

  /// Longueur maximale candidate.
  ///
  /// borne doit generous, car ce n'est pas le TITRE qui est borné mais le
  /// SIGNAL : en base64, un synopsis de 500 caractères fait ~668 caractères
  /// encodés. Une limite à 512 laissait donc décoder les titres courts et
  /// refusait les descriptifs longs — d'où des descriptions encore en base64 au
  /// milieu de programmes propres. La borne reste haute pour ne pas traiter un
  /// blob (image, vidage) comme du texte.
  static const int _maxLength = 4096;

  static final RegExp _alphabet = RegExp(r'^([A-Za-z0-9+/]+)(={0,2})$');
  static final RegExp _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

  /// Décode [raw] si elle est du base64 encodant du texte lisible.
  static String decode(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.length < _minLength || value.length > _maxLength) return value;

    // Le base64 SANS padding est fréquent : un texte de 20 octets fait 27
    // caractères, et une garde « multiple de 4 » le rejetait. C'est
    // exactement ce qui faisait que certains titres restaient encodés dans une
    // liste par ailleurs correcte.
    final remainder = value.length % 4;
    if (remainder == 1) return value; // longueur impossible en base64
    final padded =
        remainder == 0 ? value : value.padRight(value.length + (4 - remainder), '=');

    final match = _alphabet.firstMatch(padded);
    if (match == null) return value;

    try {
      final decoded = utf8.decode(base64.decode(padded), allowMalformed: false);
      if (decoded.isEmpty) return value;
      // Un caractère de remplacement trahit une séquence non-UTF8.
      if (decoded.contains('�')) return value;
      // Un contrôleur (retour chariot, tabulation) trahit un faux décodage.
      if (_controlChars.hasMatch(decoded)) return value;
      // Décoder ne doit jamais raccourcir démesurément : du base64 vers du
      // texte lisible, on gagne toujours en longueur.
      if (decoded.length < value.length ~/ 2) return value;
      return decoded;
    } on FormatException {
      return value;
    }
  }

  /// Premier champ non vide parmi [keys], décodé.
  static String first(Iterable<Object?> keys) {
    for (final key in keys) {
      final value = key?.toString().trim() ?? '';
      if (value.isNotEmpty) return decode(value);
    }
    return '';
  }

  /// Copie de [map] avec toutes les valeurs textuelles décodées, récursivement.
  ///
  /// C'est le point d'application dans les fabriques de modèles : on décode
  /// une fois pour toutes, à l'entrée, plutôt que champ par champ. Un champ
  /// ajouté demain est donc couvert automatiquement — c'était exactement la
  /// faille qui a produit trois bugs d'affilée, chacun sur un chemin oublié.
  ///
  /// Le risque d'un décodage inutile est contenu par les garde-fous de
  /// [decode] : une URL n'est pas décodée (elle sort de l'alphabet base64), un
  /// identifiant court est ignoré, et une valeur dont le décodage ne donne pas
  /// du texte lisible est conservée telle quelle.
  static Map<String, dynamic> decodeMap(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((key, value) {
      out[key] = _decodeValue(value, 0);
    });
    return out;
  }

  static Object? _decodeValue(Object? value, int depth) {
    if (depth > 4) return value;
    if (value is String) return decode(value);
    if (value is Map) {
      return decodeMap(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return [
        for (final item in value) _decodeValue(item, depth + 1),
      ];
    }
    return value;
  }
}
