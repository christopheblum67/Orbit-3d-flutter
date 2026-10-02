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
    // orced est déjà présent en clair ci-dessus : on ne le répète pas.
    'frc': 'forcé',
    'ffr': 'forcé',
    'sdh': 'sourds et malentendants',
    'cc': 'sourds et malentendants',
    'hi': 'sourds et malentendants',
  };

  /// Nom affichable de [code], ou [code] tel quel s'il est inconnu.
  ///
  /// Un code non reconnu est rendu tel quel plutôt que masqué : afficher « fr »
  /// vaut mieux que ne rien montrer, et l'utilisateur voit ce que le panel a
  /// publié. C'est aussi ce qui permet de repérer un code maison.
  static String of(String? code, {String? fallback}) {
    final raw = (code ?? '').trim();
    if (raw.isEmpty) return (fallback ?? '').trim();

    final lower = raw.toLowerCase();
    final base = lower.split(RegExp(r'[-_.]')).first;

    // Un libellé déjà rédigé (« Français ») n'est pas un code : on le garde.
    final direct = _names[lower] ?? _names[base];
    if (direct != null) return _withQualifier(direct, lower);

    // Le libellé explicite l'emporte quand il n'est pas un code.
    final label = (fallback ?? '').trim();
    if (label.isNotEmpty && _names[label.toLowerCase()] == null) {
      return label;
    }
    return raw;
  }

  static String _withQualifier(String name, String lower) {
    for (final part in lower.split(RegExp(r'[-_.]'))) {
      final qualifier = _qualifiers[part];
      if (qualifier != null) return '$name ($qualifier)';
    }
    return name;
  }
}
