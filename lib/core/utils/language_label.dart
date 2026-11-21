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

  /// Noms de langue, indexés sur les formes courantes.
  ///
  /// Deux tables et non une : la langue d'une piste s'affiche dans la langue de
  /// l'interface. Une table unique donnait « English » et « Deutsch » à un
  /// utilisateur français — le mélange paradoxal d'une table « Français,
  /// Español » et d'une table « English, Deutsch ». Sur une application dont
  /// la source de vérité est le français (`l10n.yaml` : `app_fr.arb`),
  /// l'utilisateur doit lire « Anglais ».
  static const Map<String, String> _namesFr = {
    // Français
    'fr': 'Français', 'fre': 'Français', 'fra': 'Français',
    'french': 'Français', 'vf': 'Français', 'vff': 'Français',
    // Anglais
    'en': 'Anglais', 'eng': 'Anglais', 'english': 'Anglais',
    // Espagnol — `sp` n'est pas normalisé, mais des panels l'emploient.
    'es': 'Espagnol', 'spa': 'Espagnol', 'sp': 'Espagnol',
    'spanish': 'Espagnol',
    // Allemand
    'de': 'Allemand', 'ger': 'Allemand', 'deu': 'Allemand',
    'german': 'Allemand',
    // Italien
    'it': 'Italien', 'ita': 'Italien', 'italian': 'Italien',
    // Portugais
    'pt': 'Portugais', 'por': 'Portugais', 'prt': 'Portugais',
    // Néerlandais
    'nl': 'Néerlandais', 'dut': 'Néerlandais', 'nld': 'Néerlandais',
    'dutch': 'Néerlandais',
    // Arabe
    'ar': 'Arabe', 'ara': 'Arabe', 'arabic': 'Arabe',
    // Russe
    'ru': 'Russe', 'rus': 'Russe', 'russian': 'Russe',
    // Turc
    'tr': 'Turc', 'tur': 'Turc', 'turkish': 'Turc',
    // Polonais, tchèque, suédois, Norvégien, danois, finnois, grec
    'pl': 'Polonais', 'pol': 'Polonais',
    'cs': 'Tchèque', 'cze': 'Tchèque', 'ces': 'Tchèque',
    'sv': 'Suédois', 'swe': 'Suédois',
    'no': 'Norvégien', 'nob': 'Norvégien', 'nor': 'Norvégien',
    'da': 'Danois', 'dan': 'Danois',
    'fi': 'Finnois', 'fin': 'Finnois',
    'el': 'Grec', 'gre': 'Grec', 'ell': 'Grec',
    // Roumain, hongrois
    'ro': 'Roumain', 'rum': 'Roumain', 'ron': 'Roumain',
    'hu': 'Hongrois', 'hun': 'Hongrois',
    // Ukraine, bulgare
    'uk': 'Ukrainien', 'ukr': 'Ukrainien',
    'bg': 'Bulgare', 'bul': 'Bulgare',
    // Chinois
    'zh': 'Chinois', 'chi': 'Chinois', 'zho': 'Chinois', 'chinese': 'Chinois',
    // Catalan, basque, galicien
    'ca': 'Catalan', 'cat': 'Catalan',
    'eu': 'Basque', 'baq': 'Basque',
    'gl': 'Galicien', 'glg': 'Galicien',
    // Langue inconnue
    'und': 'Inconnue', 'unknown': 'Inconnue',
  };

  /// Noms en anglais, pour une interface en anglais.
  static const Map<String, String> _namesEn = {
    'fr': 'French',
    'fre': 'French',
    'fra': 'French',
    'french': 'French',
    'vf': 'French',
    'vff': 'French',
    'en': 'English',
    'eng': 'English',
    'english': 'English',
    'es': 'Spanish',
    'spa': 'Spanish',
    'sp': 'Spanish',
    'spanish': 'Spanish',
    'de': 'German',
    'ger': 'German',
    'deu': 'German',
    'german': 'German',
    'it': 'Italian',
    'ita': 'Italian',
    'italian': 'Italian',
    'pt': 'Portuguese',
    'por': 'Portuguese',
    'prt': 'Portuguese',
    'nl': 'Dutch',
    'dut': 'Dutch',
    'nld': 'Dutch',
    'dutch': 'Dutch',
    'ar': 'Arabic',
    'ara': 'Arabic',
    'arabic': 'Arabic',
    'ru': 'Russian',
    'rus': 'Russian',
    'russian': 'Russian',
    'tr': 'Turkish',
    'tur': 'Turkish',
    'turkish': 'Turkish',
    'pl': 'Polish',
    'pol': 'Polish',
    'cs': 'Czech',
    'cze': 'Czech',
    'ces': 'Czech',
    'sv': 'Swedish',
    'swe': 'Swedish',
    'no': 'Norwegian',
    'nob': 'Norwegian',
    'nor': 'Norwegian',
    'da': 'Danish',
    'dan': 'Danish',
    'fi': 'Finnish',
    'fin': 'Finnish',
    'el': 'Greek',
    'gre': 'Greek',
    'ell': 'Greek',
    'ro': 'Romanian',
    'rum': 'Romanian',
    'ron': 'Romanian',
    'hu': 'Hungarian',
    'hun': 'Hungarian',
    'uk': 'Ukrainian',
    'ukr': 'Ukrainian',
    'bg': 'Bulgarian',
    'bul': 'Bulgarian',
    'zh': 'Chinese',
    'chi': 'Chinese',
    'zho': 'Chinese',
    'chinese': 'Chinese',
    'ca': 'Catalan',
    'cat': 'Catalan',
    'eu': 'Basque',
    'baq': 'Basque',
    'gl': 'Galician',
    'glg': 'Galician',
    'und': 'Unknown',
    'unknown': 'Unknown',
  };

  static Map<String, String> _tableFor(String? localeCode) =>
      const {'en', 'de', 'es', 'it', 'ar'}.contains(localeCode)
          ? _namesEn
          : _namesFr;

  // Noms canoniques anglais vers allemand, espagnol, italien et arabe.
  static const Map<String, List<String>> _translatedNames = {
    'French': ['Französisch', 'Francés', 'Francese', 'الفرنسية'],
    'English': ['Englisch', 'Inglés', 'Inglese', 'الإنجليزية'],
    'Spanish': ['Spanisch', 'Español', 'Spagnolo', 'الإسبانية'],
    'German': ['Deutsch', 'Alemán', 'Tedesco', 'الألمانية'],
    'Italian': ['Italienisch', 'Italiano', 'Italiano', 'الإيطالية'],
    'Portuguese': ['Portugiesisch', 'Portugués', 'Portoghese', 'البرتغالية'],
    'Dutch': ['Niederländisch', 'Neerlandés', 'Olandese', 'الهولندية'],
    'Arabic': ['Arabisch', 'Árabe', 'Arabo', 'العربية'],
    'Russian': ['Russisch', 'Ruso', 'Russo', 'الروسية'],
    'Turkish': ['Türkisch', 'Turco', 'Turco', 'التركية'],
    'Polish': ['Polnisch', 'Polaco', 'Polacco', 'البولندية'],
    'Czech': ['Tschechisch', 'Checo', 'Ceco', 'التشيكية'],
    'Swedish': ['Schwedisch', 'Sueco', 'Svedese', 'السويدية'],
    'Norwegian': ['Norwegisch', 'Noruego', 'Norvegese', 'النرويجية'],
    'Danish': ['Dänisch', 'Danés', 'Danese', 'الدنماركية'],
    'Finnish': ['Finnisch', 'Finés', 'Finlandese', 'الفنلندية'],
    'Greek': ['Griechisch', 'Griego', 'Greco', 'اليونانية'],
    'Romanian': ['Rumänisch', 'Rumano', 'Rumeno', 'الرومانية'],
    'Hungarian': ['Ungarisch', 'Húngaro', 'Ungherese', 'الهنغارية'],
    'Ukrainian': ['Ukrainisch', 'Ucraniano', 'Ucraino', 'الأوكرانية'],
    'Bulgarian': ['Bulgarisch', 'Búlgaro', 'Bulgaro', 'البلغارية'],
    'Chinese': ['Chinesisch', 'Chino', 'Cinese', 'الصينية'],
    'Catalan': ['Katalanisch', 'Catalán', 'Catalano', 'الكتالونية'],
    'Basque': ['Baskisch', 'Euskera', 'Basco', 'الباسكية'],
    'Galician': ['Galicisch', 'Gallego', 'Galiziano', 'الغاليثية'],
    'Unknown': ['Unbekannt', 'Desconocido', 'Sconosciuta', 'غير معروفة'],
  };

  static String _localizeName(String name, String? localeCode) {
    final index = switch (localeCode) {
      'de' => 0,
      'es' => 1,
      'it' => 2,
      'ar' => 3,
      _ => null,
    };
    final translations = _translatedNames[name];
    return index == null || translations == null ? name : translations[index];
  }

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
    String? code,
    Set<String> tokens,
    Set<String> fragments,
  ) {
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
  static String of(String? code, {String? fallback, String? localeCode}) {
    final names = _tableFor(localeCode);
    final raw = (code ?? '').trim();
    if (raw.isEmpty) return (fallback ?? '').trim();

    final lower = raw.toLowerCase();

    // Base linguistique : on retire les modificateurs ET leur position. La
    // forme `forced_fr` met le modificateur EN TÊTE, et sans ce retrait le
    // premier jeton vaut « forced » — affiché comme un nom de langue.
    final stripped = lower
        .replaceAll(RegExp(r'\.(srt|vtt|sub|ass|ssa)$'), '')
        .split(RegExp(r'[-_.\s+]+'))
        .where(
          (part) =>
              part.isNotEmpty &&
              !_qualifiers.containsKey(part) &&
              !_forcedTokens.contains(part) &&
              !_sdhTokens.contains(part),
        )
        .toList();

    // Un libellé déjà rédigé (« Français ») n'est pas un code : on le garde tel
    // quel, mais les modificateurs qui l'accompagnent s'appliquent encore.
    final direct = names[lower];
    if (direct != null) {
      return _withQualifier(
          _localizeName(direct, localeCode), lower, localeCode);
    }

    for (final part in stripped) {
      final found = names[part];
      if (found != null) {
        return _withQualifier(
            _localizeName(found, localeCode), lower, localeCode);
      }
    }

    // Le libellé explicite l'emporte quand il n'est pas un code.
    final label = (fallback ?? '').trim();
    if (label.isNotEmpty && names[label.toLowerCase()] == null) {
      return _withQualifier(label, lower, localeCode);
    }
    return raw;
  }

  static String _withQualifier(String name, String lower, String? localeCode) {
    // Le nom de langue doit être reconstruit après avoir retiré les
    // modificateurs : `_names['fr']` existe, mais `_names['forced']` non, et la
    // forme `forced_fr` n'a aucune entrée.
    if (isForced(lower)) {
      final qualifier = switch (localeCode) {
        'en' => 'forced',
        'de' => 'erzwungen',
        'es' => 'forzado',
        'it' => 'forzato',
        'ar' => 'إجباري',
        _ => 'forcé',
      };
      return '$name ($qualifier)';
    }
    if (isHearingImpaired(lower)) {
      final qualifier = switch (localeCode) {
        'en' => 'deaf and hard of hearing',
        'de' => 'für Hörgeschädigte',
        'es' => 'para personas sordas y con dificultades auditivas',
        'it' => 'per persone sorde e ipoudenti',
        'ar' => 'للصم وضعاف السمع',
        _ => 'sourds et malentendants',
      };
      return '$name ($qualifier)';
    }
    return name;
  }
}
