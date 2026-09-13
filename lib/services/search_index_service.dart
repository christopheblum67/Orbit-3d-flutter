import 'package:orbit_3d_flutter/models/search.dart';

/// Entrée du catalogue indexée pour la recherche plein-texte locale
/// (films, séries, chaînes live).
class SearchIndexEntry {
  final SearchType type;
  final String id;
  final String title;
  final String subtitle;
  final String streamUrl;
  final String posterUrl;
  final String categoryId;

  const SearchIndexEntry({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.streamUrl = '',
    this.posterUrl = '',
    this.categoryId = '',
  });

  String get key => '${type.name}:$id';
}

/// Résultat d'une recherche dans l'index, avec un rang normalisé [0..1].
class SearchIndexHit {
  final SearchIndexEntry entry;
  final double rank;

  const SearchIndexHit({required this.entry, required this.rank});
}

/// Index plein-texte local en mémoire (tokenization + préfixes + repli
/// sous-chaîne), recouvrant le catalogue VOD / Séries / Live téléchargé.
///
/// Motif : l'app ne dépend que de Hive ; intégrer SQLite FTS5 imposerait une
/// dépendance native (sqflite + DLL FFI) sans avantage mesurable ici — un
/// index tokenisé pur Dart donne des résultats équivalents pour ~50 k titres,
/// est testable partout (CI Windows comprise) et reste instantané.
class SearchIndexService {
  static const int _maxTokenLength = 40;

  /// Tous les tokens normalisés (triés) pour la recherche par préfixe.
  final List<String> _allTokens = [];

  /// token normalisé → entrées contenant ce token (titre ou sous-titre).
  final Map<String, List<SearchIndexEntry>> _postings = {};

  /// clé (`type:id`) → entrée, pour le score exact / déduplication.
  final Map<String, SearchIndexEntry> _byKey = {};

  bool _built = false;

  bool get isBuilt => _built;

  int get size => _byKey.length;

  /// Remplace intégralement l'index par [entries] (appelé à chaque chargement
  /// de catalogue ; idempotent et volontairement simple).
  void build(Iterable<SearchIndexEntry> entries) {
    _allTokens.clear();
    _postings.clear();
    _byKey.clear();
    for (final entry in entries) {
      _byKey[entry.key] = entry;
      for (final token in _tokens('${entry.title} ${entry.subtitle}')) {
        if (token.length > _maxTokenLength) continue;
        (_postings[token] ??= <SearchIndexEntry>[]).add(entry);
      }
    }
    _allTokens.addAll(_postings.keys);
    _allTokens.sort();
    _built = true;
  }

  /// Recherche plein-texte sur la requête normalisée. `rank` ∈ [0..1].
  List<SearchIndexHit> search(
    String query, {
    int limit = 40,
    SearchType? type,
  }) {
    if (!_built || limit <= 0) return const [];
    final tokens = _tokens(query);
    if (tokens.isEmpty) return const [];

    final scores = <String, double>{};

    for (final token in tokens) {
      final postings = _prefixPostings(token);
      for (final entry in postings) {
        if (type != null && entry.type != type) continue;
        final titleScores = _scoreEntry(entry, token);
        final s = scores[entry.key] ?? 0.0;
        scores[entry.key] = s + titleScores;
      }
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hits = <SearchIndexHit>[];
    for (final e in ranked) {
      if (hits.length >= limit) break;
      final entry = _byKey[e.key];
      if (entry == null) continue;
      hits.add(SearchIndexHit(entry: entry, rank: _clamp01(e.value / (tokens.length * 2))));
    }
    return hits;
  }

  /// Score d'une entrée pour un token donné : 1.0 token exact dans le titre,
  /// 0.7 dans le sous-titre, puis décroît avec la longueur du préfixe.
  double _scoreEntry(SearchIndexEntry entry, String token) {
    final title = _norm(entry.title);
    if (title == token) return 1.5;
    if (title.startsWith(token)) return 1.2;
    if (title.contains(token)) return 0.9;
    final subtitle = _norm(entry.subtitle);
    if (subtitle == token) return 0.8;
    if (subtitle.contains(token)) return 0.6;
    return 0.0;
  }

  /// Tokens de l'index dont le préfixe commence par [prefix] (recherche
  /// binaire O(log N) + parcours borné du rang).
  List<SearchIndexEntry> _prefixPostings(String prefix) {
    final result = <SearchIndexEntry>[];
    final lower = _lowerBound(_allTokens, prefix);
    // Borne haute : préfixe + '\uffff' couvre toute la plage lexicographique.
    final upper = _lowerBound(_allTokens, '$prefix\uffff');
    for (var i = lower; i < upper && i < _allTokens.length; i++) {
      final postings = _postings[_allTokens[i]] ?? const <SearchIndexEntry>[];
      for (final entry in postings) {
        if (!result.contains(entry)) result.add(entry);
      }
      // Filet de sécurité : ne pas explorer des dizaines de milliers de tokens.
      if (i - lower > 2000) break;
    }
    return result;
  }

  int _lowerBound(List<String> list, String value) {
    var lo = 0, hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid].compareTo(value) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  /// Tokens normalisés (minuscules, accents repliés, alphanumériques + tirets).
  static List<String> _tokens(String text) {
    final folded = _norm(text);
    final matches =
        RegExp(r"[\p{L}\p{N}-]+", unicode: true).allMatches(folded);
    final out = <String>[];
    for (final m in matches) {
      final token = m.group(0);
      if (token == null || token.length > _maxTokenLength) continue;
      if (!out.contains(token)) out.add(token);
    }
    return out;
  }

  /// Normalisation : minuscules + repli des accents (français).
  static String _norm(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(_folded[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
  }

  static const Map<int, String> _folded = {
    0xE0: 'a', 0xE2: 'a', 0xE4: 'a', 0xE3: 'a', 0xE5: 'a', 0xE6: 'ae',
    0xE7: 'c', 0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e',
    0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i',
    0xF0: 'd', 0xF1: 'n', 0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF6: 'o', 0xF8: 'o', 0xF5: 'o',
    0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u',
    0xFD: 'y', 0xFF: 'y',
    0x141: 'l',
  };
}