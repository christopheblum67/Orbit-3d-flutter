import 'dart:convert';

/// Décodage des fichiers de sous-titres, qui ne sont pas tous en UTF-8.
///
/// ## Le défaut que cela corrige
///
/// Le repli était `latin1.decode`, c'est-à-dire de l'ISO-8859-1. Or les
/// sous-titres français utilize très souvent l'**apostrophe typographique**
/// (`l'économie`) et les guillemets « ». Encodés par les outils Windows, ces
/// caractères sont les octets `0x92`, `0x93`, `0x94` — et ISO-8859-1 ne définit
/// pas cette plage : elle la laisse en caractères de contrôle C1.
///
/// Mesuré sur le SDK Dart :
///
/// ```text
/// latin1.decode([0x92]) -> U+0092   (contrôle, invisible à l'écran)
/// attendu              -> U+2019   (apostrophe ’)
/// ```
///
/// Conséquence : chaque `l'`, `d'`, `qu'`, `n'` d'un sous-titre français
/// disparaissait à l'affichage, sans que rien ne signale l'erreur. Les
/// sous-titres semblaient simplement incomplets.
///
/// Windows-1252 est l'encodage « ANSI » que Subtitle Edit et les outils de
/// sous-titrage désignent comme le format legacy du SRT. C'est ISO-8859-1 sur
/// `0x00-0x7F` et `0xA0-0xFF`, et diffère seulement sur `0x80-0x9F` — donc le
/// corriger n'affecte aucun caractère qui fonctionnait déjà.
class SubtitleEncoding {
  SubtitleEncoding._();

  /// Correspondance Windows-1252 pour `0x80`-`0x9F`.
  ///
  /// `null` = octet non attribué par la norme. On le rend en U+FFFD plutôt que
  /// de le laisser passer en contrôle C1 : un caractère de remplacement est
  /// visible comme anomalie, un contrôle invisible ne se remarque pas.
  static const List<int?> _cp1252High = <int?>[
    0x20AC, // € euro
    null, // 0x81 non attribué
    0x201A, // ‚ guillemet simple bas
    0x0192, // ƒ f minuscule
    0x201E, // „ guillemet double bas
    0x2026, // … points de suspension
    0x2020, // † dagger
    0x2021, // ‡ double dagger
    0x02C6, // ˆ accent circonflexe modificateur
    0x2030, // ‰ pour mille
    0x0160, // Š S caron
    0x2039, // ‹ angle simple gauche
    0x0152, // Œ O ligature
    null, // 0x8D non attribué
    0x017D, // Ž Z caron
    null, // 0x8F non attribué
    null, // 0x90 non attribué
    0x2018, // ' guillemet simple gauche
    0x2019, // ' apostrophe typographique
    0x201C, // " guillemet double gauche
    0x201D, // " guillemet double droit
    0x2022, // • puce
    0x2013, // – demi-cadratin
    0x2014, // — cadratin
    0x02DC, // ˜ tilde modificateur
    0x2122, // ™ marque de commerce
    0x0161, // š s caron
    0x203A, // › angle simple droit
    0x0153, // œ o ligature
    null, // 0x9D non attribué
    0x017E, // ž z caron
    0x0178, // Ÿ Y avec diaeresis
  ];

  /// Décode un payload de sous-titre.
  ///
  /// UTF-8 **strict** d'abord : c'est la format recommandé, et l'échec de cette
  /// tentative est un signal fiable de « ce n'est pas de l'UTF-8 ». Le repli
  /// Windows-1252 est appliqué à l'octet près, ce qui conserve les accents
  /// français (`é` en `0xE9`) que le simple Latin-1 gérait déjà.
  ///
  /// On ne devine pas au-delà : aucun fichier court ne permet de distinguer
  /// Windows-1251, Windows-1250 ou ISO-8859-2, et les détecter « au feeling »
  /// ferait plus de dégâts que le repli unique et documenté.
  static String decode(List<int> bytes) {
    if (bytes.isEmpty) return '';
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return decodeCp1252(bytes);
    }
  }

  /// Décodage Windows-1252, y compris la plage `0x80-0x9F`.
  ///
  /// Exposé pour être mesuré directement : c'est le chemin qui produit
  /// l'apostrophe typographique, donc celui qui était cassé.
  static String decodeCp1252(List<int> bytes) {
    final out = StringBuffer();
    for (final b in bytes) {
      if (b >= 0x80 && b <= 0x9F) {
        final mapped = _cp1252High[b - 0x80];
        out.writeCharCode(mapped ?? 0xFFFD);
      } else {
        out.writeCharCode(b);
      }
    }
    return out.toString();
  }
}