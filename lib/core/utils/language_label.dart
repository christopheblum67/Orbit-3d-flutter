/// Traduction des codes langue en noms affichables.
///
/// ## Pourquoi un utilitaire unique
///
/// Les sous-titres et les pistes audio affichaient leurs codes bruts (`fre`,
/// `eng`, `fr-CA`) — illisibles pour la plupart des utilisateurs — et le
/// parseur de sous-titres possédait sa propre table, privée, que l'audio ne
/// pouvait pas réutiliser. Deux tables finissent toujours par diverger : d'où
/// un seul point, utilisé par les deux.
///
/// ## Formes acceptées
///
/// Les panels écrivent les langues de plusieurs manières : ISO 639-1 sur deux
/// lettres (`fr`), ISO 639-2/639-3 sur trois (`fre`, `fra`, `spa`), parfois
/// avec une région (`fr-FR`, `fr_CA`), un modificateur de piste (`fr_forced`,
/// `en-sdh`, `fr.sdh`) ou un code maison (`sp` pour l'espagnol). Les trois
/// normes coexistent sur les serveurs réels, d'où les trois formes de table.
class LanguageLabel {
  const LanguageLabel._();

  /// Noms en français, indexés sur les formescourantes.
  static const Map<String, String> _names = {
    // Français
    'fr': 'Français', 'fre': 'Français', 'fra': 'Français',
    'french': 'Français', 'vf': 'Français', 'vff': 'Français',
    // Anglais
    'en': 'English', 'eng': 'English', 'english': 'English',
    // Espagnol — `sp` n'est pas normalisé, mais des panels l'emploient.
    'es': 'Español', 'spa': 'Español', 'sp': 'Español', 'spanish': 'Español',
    // Allemand
    'de': 'Deutsch', 'ger': 'Deutsch', 'deu': 'Deutsch', 'german': 'Deutsch',
    // Italien
    'it': 'Italiano', 'ita': 'Italiano', 'italian': 'Italiano',
    // Portugais
    'pt': 'Português', 'por': 'Português', 'prt': 'Português',
    // Néerlandais
    'nl': 'Nederlands', 'dut': 'Nederlands', 'nld': 'Nederlands',
    'dutch': 'Nederlands',
    // Arabe
    'ar': 'العربية', 'ara': 'العربية', 'arabic': 'العربية',
    // Russe
    'ru': 'Русский', 'rus': 'Русский', 'russian': 'Русский',
    // Turc
    'tr': 'Türkçe', 'tur': 'Türkçe', 'turkish': 'Türkçe',
    // Polonais, tchèque, suédois, Norvégien, danois, finnois, grec
    'pl': 'Polski', 'pol': 'Polski',
    'cs': 'Čeština', 'cze': 'Čeština', 'ces': 'Čeština',
    'sv': 'Svenska', 'swe': 'Svenska',
    'no': 'Norsk', 'nob': 'Norsk', 'nor': 'Norsk',
    'da': 'Dansk', 'dan': 'Dansk',
    'fi': 'Suomi', 'fin': 'Suomi',
    'el': 'Ελληνικά', 'gre': 'Ελληνικά', 'ell': 'Ελληνικά',
    // Roumain, hongrois, tchèque (variante)
    'ro': 'Română', 'rum': 'Română', 'ron': 'Română',
    'hu': 'Magyar', 'hun': 'Magyar',
    // Ukraine, tchèque déjà couvert, bulgare
    'uk': 'Українська', 'ukr': 'Українська',
    'bg': 'Български', 'bul': 'Български',
    // Chinois
    'zh': '中文', 'chi': '中文', 'zho': '中文', 'chinese': '中文',
    // Catalan, basque, galicien
    'ca': 'Català', 'cat': 'Català',
    'eu': 'Euskara', 'baq': 'Euskara',
    'gl': 'Galego', 'glg': 'Galego',
    // Langue inconnue
    'und': 'Inconnue', 'unknown': 'Inconnue',
  };

  /// Modificateurs de piste, qui s'ajoutent au nom de la langue.
  static const Map<String, String> _qualifiers = {
    'forced': 'forcé',
    'force': 'forcé',
    'forcedsub': 'forcé',
    'subforced': 'forcé',
    'frc': 'forcé',
    'ffr': 'forcé',
    'sdh': 'sourds et malentendants',
    'cc': 'sourds et malentendants',
    'hi': 'sourds et malentendants',
    'hearing': 'sourds et malentendants',
  };

  /// Jetons « forcé », testés aussi bien en token qu'en fragment.
  ///
  /// Les fragments sont volontairement limités aux formes longues et sans
  /// ambiguïté (`forced`, `sdh`) : tester `contains('cc')` ou `contains('hi')`
  /// sur un descripteur entier produit des faux positifs dès qu'un nom de langue
  /// contient ces lettres. Les codes courts (`cc`, `hi`, `ffr`, `frc`) ne sont
  /// donc acceptés qu'en token entier.
  static const Set<String> _forcedTokens = {
    'forced',
    'force',
    'forcedsub',
    'subforced',
    'frc',
    'ffr',
  };

  static const Set<String> _sdhTokens = {
    'sdh',
    'cc',
    'hi',
    'hearing',
  };

  /// Le descripteur décrit-il un sous-titre forcé ?
  ///
  /// Les deux ordres sont couverts : `fr_forced` et `forced_fr` comme
  /// `subforced` ou `1234_fr_subforced.srt`. Un simple découpage sur les
  /// séparateurs ne donne que le premier ordre, et affichait « forced » comme
  /// un nom de langue.
  static bool isForced(String? code) =>
      _matches(code, _forcedTokens, const {'forced'});

  /// Le descripteur décrit-il un sous-titre pour sourds et malentendants ?
  static bool isHearingImpaired(String? code) =>
      _matches(code, _sdhTokens, const {'sdh'});

  static bool _matches(
      String? code, Set<String> tokens, Set<String> fragments) {
    if (code == null || code.isEmpty) return false;
    final lower =
        code.toLowerCase().replaceAll(RegExp(r'\.(srt|vtt|sub|ass|ssa)$'), '');
    final parts =
        lower.split(RegExp(r'[-_.\s+]+')).where((p) => p.isNotEmpty).toList();

    // Un code COURT n'est un modificateur que s'il accompagne une langue.
    //
    // `hi` signifie « hard of hearing » dans `fr_hi`, mais c'est aussi le code
    // ISO du hindi. Sans cette condition, un hindi s'afficherait
    // « हिन्दी (sourds et malentendants) ». Même règle pour `cc`, `ffr`, `frc`.
    // Les formes longues (`forced`, `sdh`) n'ont pas cette ambiguïté.
    final hasLanguagePart = parts
        .where((p) => !_forcedTokens.contains(p) && !_sdhTokens.contains(p))
        .isNotEmpty;

    for (final part in parts) {
      if (!tokens.contains(part)) continue;
      if (part.length > 2 || hasLanguagePart) return true;
    }
    // Fragment collé, sans séparateur : `subforced`, `forcedsub`.
    return fragments.any(lower.contains);
  }

  /// Nom affichable de [code], ou [code] tel quel s'il est inconnu.
  ///
  /// Un code non reconnu est rendu tel quel plutôt que masqué : afficher « fr »
  /// vaut mieux que ne rien montrer, et l'utilisateur voit ce que le panel a
  /// publié. C'est aussi ce qui permet de repérer un code maison.
  static String of(String? code, {String? fallback}) {
    final raw = (code ?? '').trim();
    if (raw.isEmpty) return (fallback ?? '').trim();

    final lower = raw.toLowerCase();

    // Base linguistique : on retire les modificateurs ET leur position. La
    // forme `forced_fr` met le modificateur EN TÊTE, et sans ce retrait le
    // premier jeton vaut « forced » — affiché comme un nom de langue.
    final stripped = lower
        .replaceAll(RegExp(r'\.(srt|vtt|sub|ass|ssa)$'), '')
        .split(RegExp(r'[-_.\s+]+'))
        .where((part) =>
            part.isNotEmpty &&
            !_qualifiers.containsKey(part) &&
            !_forcedTokens.contains(part) &&
            !_sdhTokens.contains(part))
        .toList();

    // Un libellé déjà rédigé (« Français ») n'est pas un code : on le garde tel
    // quel, mais les modificateurs qui l'accompagnent s'appliquent encore.
    final direct = _names[lower];
    if (direct != null) return _withQualifier(direct, lower);

    for (final part in stripped) {
      final found = _names[part];
      if (found != null) return _withQualifier(found, lower);
    }

    // Le libellé explicite l'emporte quand il n'est pas un code.
    final label = (fallback ?? '').trim();
    if (label.isNotEmpty && _names[label.toLowerCase()] == null) {
      return _withQualifier(label, lower);
    }
    return raw;
  }

  static String _withQualifier(String name, String lower) {
    // Le nom de langue doit être reconstruit après avoir retiré les
    // modificateurs : `_names['fr']` existe, mais `_names['forced']` non, et la
    // forme `forced_fr` n'a aucune entrée.
    if (isForced(lower)) return '$name (forcé)';
    if (isHearingImpaired(lower)) return '$name (sourds et malentendants)';
    return name;
  }
}
