import 'package:flutter/foundation.dart' show setEquals;
import 'package:meta/meta.dart';
import 'package:orbit_3d_flutter/models/movie.dart';

/// Tri appliqué à une liste de films déjà filtrée.
///
/// Injecté plutôt que d'appeler `MediaLibraryManager` directement, pour que
/// cette classe reste testable sans Riverpod ni I/O.
typedef VodSorter = List<Movie> Function(List<Movie> movies, String sortMode);

/// Résultat d'un passage du pipeline.
class VodCatalogResult {
  const VodCatalogResult({
    required this.visibleMovies,
    required this.visibleCount,
    required this.favoriteCount,
    required this.recentCount,
    required this.categoryCounts,
  });

  /// Films affichés, triés.
  final List<Movie> visibleMovies;

  /// Nombre de films visibles avant le filtre texte (compteur « Tous »).
  final int visibleCount;

  /// Compteur « Favoris », sur la même base.
  final int favoriteCount;

  /// Compteur « Récemment », sur la même base.
  final int recentCount;

  /// Nombre de films par catégorie, sur les films hors catégories masquées.
  ///
  /// Mémoïsé : l'écran reconstruisait cette carte à chaque `build()` en
  /// parcourant tout le catalogue.
  final Map<String, int> categoryCounts;
}

/// Pipeline catalogue VOD mémoïsé.
///
/// Le catalogue Xtream fait ~100 000 entrées. Filtrer, minusculiser, trier et
/// remapper cette liste dans un `build()` revenait à parcourir 100 000 films —
/// avec deux `toLowerCase()` par film, donc ~200 000 allocations — à chaque
/// frappe au clavier.
///
/// Ce pipeline découpe le travail en trois étages, chacun réutilisé tant que
/// ses entrées n'ont pas changé :
///
/// 1. **[A]** films hors catégories masquées ;
/// 2. **[B]** films de la catégorie sélectionnée + clés de recherche
///    minusculisées, calculées une seule fois par changement de catégorie ;
/// 3. **[C]** tri du résultat de recherche.
///
/// Le filtre texte est la seule étape recalculée à chaque frappe, et il ne
/// fait plus qu'un `contains` par film sur des chaînes déjà minusculisées.
///
/// La mémoïsation est purement par identité et égalité de contenu : le résultat
/// est **strictement identique** à celui du pipeline naïf.
class VodCatalogPipeline {
  VodCatalogPipeline({required VodSorter sorter}) : _sorter = sorter;

  final VodSorter _sorter;

  List<Movie>? _aSource;
  Set<String>? _aHidden;
  List<Movie>? _aResult;
  int _aFavoriteCount = 0;
  int _aRecentCount = 0;
  Map<String, int> _aCategoryCounts = const <String, int>{};

  List<Movie>? _bSource;
  Set<String>? _bFav;
  Set<String>? _bRecent;
  String _bCategory = '\u0000';
  List<Movie>? _bResult;
  List<String> _bKeys = const <String>[];

  List<Movie>? _cSource;
  String? _cMode;
  List<Movie>? _cResult;

  /// Nombre de fois où le filtre texte a été recalculé.
  ///
  /// Exposé pour les tests : c'est la mesure directe du travail évité.
  int searchPasses = 0;

  /// Nombre de fois où le tri a été recalculé.
  ///
  /// Contrairement aux étages [A] et [B], celui-ci EST rejoué à chaque
  /// frappe : la requête change l'ensemble des correspondances, donc une
  /// nouvelle liste triée est nécessaire. Ce qui disparaît de la boucle, c'est
  /// tout ce qui l'entourait — refiltrage par catégorie, reminusculisation,
  /// compteurs, aller-retour par `MediaItem` — et, dans `applySort`, les deux
  /// `toLowerCase()` qui s'exécutaient à chaque comparaison.
  int sortPasses = 0;

  /// Nombre de fois où l'étage [A] a réellement recalculé (passe complète).
  int stageAPasses = 0;

  /// Nombre de fois où l'étage [B] a réellement recalculé (filtre + clés).
  int stageBPasses = 0;

  /// Clé de recherche pré-minusculisée d'un film.
  ///
  /// `\u0000` sépare titre et genre. Aucune saisie clavier ne peut contenir
  /// ce caractère, donc `contains` ne peut pas faire de correspondance à
  /// cheval d'un champ sur l'autre.
  @visibleForTesting
  static String searchKey(Movie m) =>
      '${m.title.toLowerCase()}\u0000${m.genre.toLowerCase()}';

  VodCatalogResult apply({
    required List<Movie> movies,
    required Set<String> hiddenCategories,
    required String categoryId,
    required Set<String> favoriteIds,
    required Set<String> recentIds,
    required String query,
    required String sortMode,
  }) {
    final categoryVisible =
        _stageA(movies, hiddenCategories, favoriteIds, recentIds);
    final filtered = _stageB(
      categoryVisible,
      categoryId,
      favoriteIds,
      recentIds,
    );

    final q = query.trim().toLowerCase();
    final List<Movie> queryFiltered;
    if (q.isEmpty) {
      queryFiltered = filtered;
    } else {
      searchPasses++;
      queryFiltered = <Movie>[];
      final keys = _bKeys;
      for (var i = 0; i < filtered.length; i++) {
        if (keys[i].contains(q)) queryFiltered.add(filtered[i]);
      }
    }

    final sorted = _stageC(queryFiltered, sortMode);

    return VodCatalogResult(
      visibleMovies: sorted,
      visibleCount: categoryVisible.length,
      favoriteCount: _aFavoriteCount,
      recentCount: _aRecentCount,
      categoryCounts: _aCategoryCounts,
    );
  }

  List<Movie> _stageA(
    List<Movie> movies,
    Set<String> hidden,
    Set<String> favoriteIds,
    Set<String> recentIds,
  ) {
    if (identical(_aSource, movies) &&
        setEquals(_aHidden, hidden) &&
        setEquals(_bFav, favoriteIds) &&
        setEquals(_bRecent, recentIds)) {
      return _aResult!;
    }
    final result = hidden.isEmpty
        ? movies
        : movies
            .where((m) => !hidden.contains(m.categoryId))
            .toList(growable: false);

    var favCount = 0;
    var recentCount = 0;
    final categoryCounts = <String, int>{};
    for (final m in result) {
      if (favoriteIds.contains(m.id)) favCount++;
      if (recentIds.contains(m.id)) recentCount++;
      if (m.categoryId.isNotEmpty) {
        categoryCounts[m.categoryId] = (categoryCounts[m.categoryId] ?? 0) + 1;
      }
    }

    _aSource = movies;
    _aHidden = hidden;
    stageAPasses++;
    _aResult = result;
    _aFavoriteCount = favCount;
    _aRecentCount = recentCount;
    _aCategoryCounts = Map.unmodifiable(categoryCounts);
    return result;
  }

  List<Movie> _stageB(
    List<Movie> source,
    String categoryId,
    Set<String> favoriteIds,
    Set<String> recentIds,
  ) {
    if (identical(_bSource, source) &&
        _bCategory == categoryId &&
        setEquals(_bFav, favoriteIds) &&
        setEquals(_bRecent, recentIds)) {
      return _bResult!;
    }

    final List<Movie> result;
    if (categoryId == 'fav') {
      result = source.where((m) => favoriteIds.contains(m.id)).toList();
    } else if (categoryId == 'recent') {
      result = source.where((m) => recentIds.contains(m.id)).toList();
    } else if (categoryId.isEmpty) {
      result = source;
    } else {
      result = source.where((m) => m.categoryId == categoryId).toList();
    }

    _bSource = source;
    _bCategory = categoryId;
    _bFav = favoriteIds;
    _bRecent = recentIds;
    stageBPasses++;
    _bResult = result;
    _bKeys = [for (final m in result) searchKey(m)];
    return result;
  }

  List<Movie> _stageC(List<Movie> source, String sortMode) {
    if (identical(_cSource, source) && _cMode == sortMode) {
      return _cResult!;
    }
    sortPasses++;
    final result = _sorter(source, sortMode);
    _cSource = source;
    _cMode = sortMode;
    _cResult = result;
    return result;
  }
}
