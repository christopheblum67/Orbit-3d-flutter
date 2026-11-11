/// Normalisation commune des libellés Xtream Code (live, films, séries,
/// replay, radio). Chaque panel nomme ses catégories et ses chaînes à sa
/// manière (`|BE| Antipode`, `FR | NRJ`, `ⓉⓋ ║ FRANCE HD`) : seule la
/// structure `category_id`/`category_name` est commune, pas le contenu.
class XtreamTaxonomy {
  const XtreamTaxonomy._();

  static const String others = 'Autres';

  static final RegExp _namePrefix = RegExp(
    r'^[^A-Za-z0-9]*[|\[(]?\s*([A-Za-z]{2,3})\s*[|\])║:]',
  );
  static final RegExp _separators = RegExp(r'[|║│┃¦]');
  static final RegExp _radioWord = RegExp(r'(^|[^a-z])radios?($|[^a-z])');
  static final RegExp _nonWord = RegExp(r'[^a-z0-9]+');

  /// Libellé de catégorie sans décoration : `ⓉⓋ ║ FRANCE HD` → `FRANCE HD`.
  /// Seuls les segments de tête purement décoratifs (symboles, « TV ») sont
  /// retirés ; `FRANCE HD | OTT` et `FR | Films` restent intacts.
  static String cleanCategory(String name) {
    final parts = _meaningfulParts(name);
    if (parts.isEmpty) return name.trim();
    return parts.join(' | ');
  }

  /// Libellé principal : premier segment significatif (`FRANCE HD | OTT` →
  /// `FRANCE HD`, `ⓉⓋ ║ FRANCE HD` → `FRANCE HD`).
  static String primarySegment(String name) {
    final parts = _meaningfulParts(name.replaceAll(';', '|'));
    return parts.isEmpty ? name.trim() : parts.first;
  }

  static List<String> _meaningfulParts(String name) {
    final parts = [
      for (final part in name.split(_separators))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    while (parts.length > 1 && _isDecoration(parts.first)) {
      parts.removeAt(0);
    }
    return parts;
  }

  static bool _isDecoration(String part) {
    final letters = part.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return letters.isEmpty || letters.toLowerCase() == 'tv';
  }

  /// Code pays lu dans le préfixe d'un nom (`|BE| X`, `FR | X`, `[FR] X`).
  static String? countryFromName(String name) =>
      _namePrefix.firstMatch(name)?.group(1)!.toUpperCase();

  /// Code pays déduit d'un nom de catégorie (`BELGIUM | LUX`, `FRANCE HD`).
  static String? countryFromCategory(String categoryName) {
    final fromPrefix = countryFromName(categoryName);
    if (fromPrefix != null && _countryCodes.contains(fromPrefix)) {
      return fromPrefix;
    }
    final parts = _meaningfulParts(categoryName);
    if (parts.isEmpty) return null;
    final text = ' ${_fold(parts.first).replaceAll(_nonWord, ' ')} ';
    for (final entry in _countryKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(' $keyword ')) return entry.key;
      }
    }
    return null;
  }

  static String _fold(String text) {
    const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }

  /// Pays d'un élément : préfixe du nom, sinon catégorie, sinon « Autres ».
  static String countryOf(String name, {String? categoryName}) {
    final fromName = countryFromName(name);
    if (fromName != null) return fromName;
    if (categoryName != null) {
      final fromCategory = countryFromCategory(categoryName);
      if (fromCategory != null) return fromCategory;
    }
    return others;
  }

  /// Catégorie de stations radio : mot « radio » (radio, radios, web radio…).
  /// « musique »/« music » seuls désignent souvent des chaînes TV musicales.
  static bool isRadioCategory(String categoryName) =>
      _radioWord.hasMatch(categoryName.toLowerCase());

  /// Pays distincts triés, « Autres » toujours en dernier.
  static List<String> sortCountries(Iterable<String> countries) {
    final list = countries.toSet().toList()..sort();
    if (list.remove(others)) list.add(others);
    return list;
  }

  static const Set<String> _countryCodes = {
    'FR', 'BE', 'LU', 'CH', 'NL', 'DE', 'AT', 'PT', 'BR', 'IT', 'ES', 'AR',
    'DZ', 'MA', 'TN', 'CA', 'QC', 'TR', 'AF', 'UK', 'GB', 'US', 'LA', 'GR',
    'AL', 'PL', 'UA', 'RO', 'RU', 'SE', 'NO', 'DK', 'FI', 'IN', 'PK', 'KU',
    'IE', 'EX', 'SA', 'AE', 'EG', 'IR', 'IL', 'CZ', 'HU', 'BG', 'RS', 'HR',
  };

  static const Map<String, List<String>> _countryKeywords = {
    'FR': ['france', 'francais', 'dom tom', 'domtom'],
    'BE': ['belgium', 'belgique', 'belgie'],
    'LU': ['luxembourg', 'lux'],
    'CH': ['switzerland', 'suisse', 'schweiz'],
    'NL': ['netherlands', 'nederland', 'pays bas', 'holland'],
    'DE': ['deutschland', 'germany', 'allemagne'],
    'AT': ['austria', 'osterreich'],
    'PT': ['portugal'],
    'BR': ['brazil', 'brasil', 'bresil'],
    'IT': ['italy', 'italia', 'italie'],
    'ES': ['espana', 'spain', 'espagne'],
    'DZ': ['algeria', 'algerie'],
    'MA': ['maroc', 'morocco'],
    'TN': ['tunisia', 'tunisie'],
    'QC': ['quebec'],
    'CA': ['canada'],
    'TR': ['turkey', 'turquie'],
    'UK': ['u k', 'uk', 'united kingdom', 'royaume uni'],
    'US': ['u s a', 'usa', 'united states'],
    'GR': ['greece', 'grece'],
    'AL': ['albania', 'albanie'],
    'PL': ['poland', 'pologne'],
    'UA': ['ukraine'],
    'RO': ['romania', 'roumanie'],
    'RU': ['russia', 'russie'],
    'IN': ['india'],
    'PK': ['pakistan'],
  };
}
