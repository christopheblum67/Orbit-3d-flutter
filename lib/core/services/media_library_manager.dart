import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types de tri disponibles.
///
/// Chaque critère (nom, note, année, date d'ajout, durée, affinité) n'existe
/// qu'en une entrée dans la liste de choix : le sens se règle avec le bouton
/// ↑/↓ de la barre d'outils (`SortModeDirection.reversed`), au lieu
/// d'apparaître comme deux options distinctes dans le menu.
enum SortMode {
  nameAsc, // A -> Z
  nameDesc, // Z -> A
  ratingDesc, // Mieux notés (XCIPTV)
  ratingAsc, // Moins bien notés d'abord
  yearDesc, // Plus récents par année de sortie
  yearAsc, // Années anciennes d'abord
  recentlyAdded, // Ajoutés récemment à la liste
  recentlyAddedAsc, // Ajoutés le plus anciennement d'abord
  resumeFirst, // Intuitif : À reprendre en priorité
  durationShort, // Durée : Plus courts d'abord
  durationLong, // Durée : Plus longs d'abord
  affinity, // Affinité matchmaking : score du profil, ordre décroissant
  affinityAsc, // Affinité matchmaking : score du profil, ordre croissant
}

/// Sens d'un mode de tri et possibilité de l'inverser.
///
/// Le bouton ↑/↓ de la barre d'outils lit ces trois getters :
/// `reversed` dit quoi appliquer au clic (`null` ⇒ bouton désactivé),
/// `isAscending` dit quelle flèche afficher, `criterion` réduit le mode au
/// critère seul pour marquer l'entrée active de la liste de choix (mode
/// `yearAsc` ⇒ l'entrée « Par année » est active).
extension SortModeDirection on SortMode {
  /// Mode de même critère dans le sens opposé, `null` si le critère n'est pas
  /// inversible.
  ///
  /// « À reprendre » n'a pas d'inverse : son ordre est « commencés non
  /// terminés d'abord, puis les plus récemment vus ». Le retourner mettrait
  /// les contenus jamais lancés en tête et viderait le critère de son sens.
  SortMode? get reversed => switch (this) {
        SortMode.nameAsc => SortMode.nameDesc,
        SortMode.nameDesc => SortMode.nameAsc,
        SortMode.ratingDesc => SortMode.ratingAsc,
        SortMode.ratingAsc => SortMode.ratingDesc,
        SortMode.yearDesc => SortMode.yearAsc,
        SortMode.yearAsc => SortMode.yearDesc,
        SortMode.recentlyAdded => SortMode.recentlyAddedAsc,
        SortMode.recentlyAddedAsc => SortMode.recentlyAdded,
        SortMode.durationShort => SortMode.durationLong,
        SortMode.durationLong => SortMode.durationShort,
        SortMode.affinity => SortMode.affinityAsc,
        SortMode.affinityAsc => SortMode.affinity,
        SortMode.resumeFirst => null,
      };

  /// Vrai si le mode classe du plus petit au plus grand sur son critère.
  bool get isAscending => switch (this) {
        SortMode.nameAsc ||
        SortMode.ratingAsc ||
        SortMode.yearAsc ||
        SortMode.recentlyAddedAsc ||
        SortMode.durationShort ||
        SortMode.affinityAsc =>
          true,
        SortMode.nameDesc ||
        SortMode.ratingDesc ||
        SortMode.yearDesc ||
        SortMode.recentlyAdded ||
        SortMode.durationLong ||
        SortMode.affinity ||
        SortMode.resumeFirst =>
          false,
      };

  /// Critère seul, sans le sens : deux modes de même critère partagent le même
  /// `criterion` (ex. `yearDesc` et `yearAsc` ⇒ `yearDesc`).
  SortMode get criterion => switch (this) {
        SortMode.nameAsc || SortMode.nameDesc => SortMode.nameDesc,
        SortMode.ratingDesc || SortMode.ratingAsc => SortMode.ratingDesc,
        SortMode.yearDesc || SortMode.yearAsc => SortMode.yearDesc,
        SortMode.recentlyAdded ||
        SortMode.recentlyAddedAsc =>
          SortMode.recentlyAdded,
        SortMode.durationShort || SortMode.durationLong => SortMode.durationShort,
        SortMode.affinity || SortMode.affinityAsc => SortMode.affinity,
        SortMode.resumeFirst => SortMode.resumeFirst,
      };

  /// Vrai si le tri est piloté par le titre plutôt que par une métadonnée
  /// (note, année, …). Ces modes vivent sur le bouton A→Z, pas dans la liste.
  bool get isAlphabetical =>
      this == SortMode.nameAsc || this == SortMode.nameDesc;
}

/// Epoch utilisé comme borne basse des dates de lecture, hors comparateur.
final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// Modèle Unifié pour Chaîne, Film ou Série
class MediaItem {
  final String id;
  final String title;
  final String streamUrl;
  final String? posterUrl;
  final String? categoryId;
  final double rating; // Note (ex: 8.5)
  final int releaseYear; // Année (ex: 2024)
  final int durationMinutes; // Durée en minutes
  /// Date d'import/addition. Nullable car tous les panels Xtream ne renvoie pas
  /// le champ `added` : forcer `DateTime.now()` rendait le tri « récemment
  /// ajouté » vide de sens (tous les items à l'heure courante).
  final DateTime? addedDate;

  // Attributs de lecture dynamique
  int lastPositionMs;
  int totalDurationMs;
  DateTime? lastWatchedAt;

  MediaItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.posterUrl,
    this.categoryId,
    this.rating = 0.0,
    this.releaseYear = 0,
    this.durationMinutes = 0,
    required this.addedDate,
    this.lastPositionMs = 0,
    this.totalDurationMs = 0,
    this.lastWatchedAt,
  });

  // Calcul du pourcentage de progression
  double get playbackProgress {
    if (totalDurationMs == 0) return 0.0;
    return (lastPositionMs / totalDurationMs).clamp(0.0, 1.0);
  }

  bool get isUnfinished => playbackProgress > 0.05 && playbackProgress < 0.92;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'streamUrl': streamUrl,
        'posterUrl': posterUrl,
        'categoryId': categoryId,
        'rating': rating,
        'releaseYear': releaseYear,
        'durationMinutes': durationMinutes,
        'addedDate': addedDate?.toIso8601String(),
        'lastPositionMs': lastPositionMs,
        'totalDurationMs': totalDurationMs,
        'lastWatchedAt': lastWatchedAt?.toIso8601String(),
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'],
        title: json['title'],
        streamUrl: json['streamUrl'],
        posterUrl: json['posterUrl'],
        categoryId: json['categoryId'],
        rating: (json['rating'] ?? 0.0).toDouble(),
        releaseYear: json['releaseYear'] ?? 0,
        durationMinutes: json['durationMinutes'] ?? 0,
        addedDate: DateTime.parse(json['addedDate']),
        lastPositionMs: json['lastPositionMs'] ?? 0,
        totalDurationMs: json['totalDurationMs'] ?? 0,
        lastWatchedAt: json['lastWatchedAt'] != null
            ? DateTime.parse(json['lastWatchedAt'])
            : null,
      );
}

/// Service de Gestion du Stockage & des Métadonnées
///
/// Les favoris ne font PAS partie de ce service : ils sont gérés par
/// `favoritesProvider`, sur Hive, avec une clé par profil. Ce service en
/// portait une seconde implémentation dans `shared_preferences`, jamais appelée
/// — deux systèmes de favoris parallèles pour un seul écran.
class MediaLibraryManager extends ChangeNotifier {
  static const String _historyKey = 'orbit_recently_watched';

  List<MediaItem> _historyItems = [];

  List<MediaItem> get recentlyWatched => _historyItems;

  /// Initialisation et chargement du stockage local
  Future<void> init(List<MediaItem> rawPlaylist) async {
    final prefs = await SharedPreferences.getInstance();

    // Historique des contenus regardés.
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    _historyItems =
        historyJson.map((str) => MediaItem.fromJson(jsonDecode(str))).toList();

    notifyListeners();
  }

  /// Enregistrer une position de lecture (Historique)
  Future<void> updatePlaybackHistory(
    MediaItem item,
    int positionMs,
    int totalMs,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    item.lastPositionMs = positionMs;
    item.totalDurationMs = totalMs;
    item.lastWatchedAt = DateTime.now();

    // Supprimer le doublon si existant
    _historyItems.removeWhere((i) => i.id == item.id);
    // Insérer en première position (Le plus récent)
    _historyItems.insert(0, item);

    // Limiter la taille de l'historique à 50 éléments
    if (_historyItems.length > 50) {
      _historyItems = _historyItems.sublist(0, 50);
    }

    final encoded = _historyItems.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_historyKey, encoded);
    notifyListeners();
  }

  /// --- ERGONOMIE : NETTOYAGE DU CACHE & MÉMOIRE ---
  Future<void> clearRecentlyWatched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    _historyItems.clear();
    notifyListeners();
  }

  /// Moteur de tri appliqué à une liste
  List<MediaItem> applySort(List<MediaItem> inputList, SortMode mode) {
    // Tri par nom : clé de comparaison calculée UNE fois par item.
    //
    // `a.title.toLowerCase().compareTo(b.title.toLowerCase())` allouait deux
    // chaînes À CHAQUE comparaison. `List.sort` est un quicksort dual-pivot en
    // place, donc O(n log n) comparaisons : trier 10 000 films produisait
    // ~260 000 allocations de chaînes, et ce tri se relançait à chaque frappe
    // au clavier dans la grille VOD.
    if (mode == SortMode.nameAsc || mode == SortMode.nameDesc) {
      final keyed = [
        for (final item in inputList) (item, item.title.toLowerCase()),
      ];
      keyed.sort(mode == SortMode.nameAsc
          ? (a, b) => a.$2.compareTo(b.$2)
          : (a, b) => b.$2.compareTo(a.$2),);
      return [for (final e in keyed) e.$1];
    }

    final List<MediaItem> sorted = List.from(inputList);

    switch (mode) {
      case SortMode.nameAsc:
      case SortMode.nameDesc:
        // Inatteignables : traités et retournés avant le switch. Conservés
        // uniquement pour l'exhaustivité de l'analyse de switch.
        break;
      case SortMode.ratingDesc:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortMode.ratingAsc:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case SortMode.yearDesc:
        sorted.sort((a, b) => b.releaseYear.compareTo(a.releaseYear));
        break;
      case SortMode.yearAsc:
        sorted.sort((a, b) => a.releaseYear.compareTo(b.releaseYear));
        break;
      case SortMode.recentlyAdded:
        // Les items sans date d'ajout (panel qui n'envoie pas `added`) passent
        // en fin de liste au lieu de planter la comparaison.
        sorted.sort((a, b) {
          final da = a.addedDate;
          final db = b.addedDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
        break;
      case SortMode.recentlyAddedAsc:
        // Même politique pour les dates absentes : une date inconnue n'est pas
        // une date ancienne, elle reste en fin de liste dans les deux sens.
        sorted.sort((a, b) {
          final da = a.addedDate;
          final db = b.addedDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
      case SortMode.resumeFirst:
        // Priorité aux vidéos commencées non terminées, puis date de lecture
        sorted.sort((a, b) {
          if (a.isUnfinished && !b.isUnfinished) return -1;
          if (!a.isUnfinished && b.isUnfinished) return 1;
          // Constante hissée hors du comparateur : `DateTime(1970)` était
          // alloué à chaque comparaison pour chaque item sans date de lecture,
          // soit O(n log n) allocations pour un tri.
          return (b.lastWatchedAt ?? _epoch)
              .compareTo(a.lastWatchedAt ?? _epoch);
        });
        break;
      case SortMode.durationShort:
        sorted.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
      case SortMode.durationLong:
        sorted.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
        break;
      case SortMode.affinity:
      case SortMode.affinityAsc:
        // Jamais atteint par les écrans Films/Séries : ils interceptent ces
        // modes AVANT `applySort` et trient avec le score matchmaking
        // (`ProfileAffinityScorer`, sur le genre TMDB corrigé). Repli défensif
        // ici (écran Parcourir) : la note reste le meilleur signal sans profil.
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return sorted;
  }
}
