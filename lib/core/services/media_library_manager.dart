import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types de tri disponibles
enum SortMode {
  nameAsc,          // A -> Z
  nameDesc,         // Z -> A
  ratingDesc,       // Mieux notés (XCIPTV)
  yearDesc,         // Plus récents par année de sortie
  recentlyAdded,    // Ajoutés récemment à la liste
  resumeFirst,      // Intuitif : À reprendre en priorité
  durationShort,    // Durée : Plus courts d'abord
  durationLong,     // Durée : Plus longs d'abord
}

/// Modèle Unifié pour Chaîne, Film ou Série
class MediaItem {
  final String id;
  final String title;
  final String streamUrl;
  final String? posterUrl;
  final String? categoryId;
  final double rating;        // Note (ex: 8.5)
  final int releaseYear;      // Année (ex: 2024)
  final int durationMinutes;  // Durée en minutes
  final DateTime addedDate;   // Date d'import

  // Attributs de lecture dynamique
  bool isFavorite;
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
    this.isFavorite = false,
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
        'addedDate': addedDate.toIso8601String(),
        'isFavorite': isFavorite,
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
        isFavorite: json['isFavorite'] ?? false,
        lastPositionMs: json['lastPositionMs'] ?? 0,
        totalDurationMs: json['totalDurationMs'] ?? 0,
        lastWatchedAt: json['lastWatchedAt'] != null
            ? DateTime.parse(json['lastWatchedAt'])
            : null,
      );
}

/// Service de Gestion du Stockage & des Métadonnées
class MediaLibraryManager extends ChangeNotifier {
  static const String _favsKey = 'orbit_favorites_ids';
  static const String _historyKey = 'orbit_recently_watched';

  List<MediaItem> _allItems = [];
  Set<String> _favoriteIds = {};
  List<MediaItem> _historyItems = [];

  List<MediaItem> get favorites =>
      _allItems.where((item) => _favoriteIds.contains(item.id)).toList();

  List<MediaItem> get recentlyWatched => _historyItems;

  /// Initialisation et chargement du stockage local
  Future<void> init(List<MediaItem> rawPlaylist) async {
    _allItems = rawPlaylist;
    final prefs = await SharedPreferences.getInstance();

    // 1. Charger les Favoris
    final favList = prefs.getStringList(_favsKey) ?? [];
    _favoriteIds = favList.toSet();

    for (var item in _allItems) {
      if (_favoriteIds.contains(item.id)) {
        item.isFavorite = true;
      }
    }

    // 2. Charger les Récemment Regardés
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    _historyItems = historyJson
        .map((str) => MediaItem.fromJson(jsonDecode(str)))
        .toList();

    notifyListeners();
  }

  /// Basculer l'état Favori
  Future<void> toggleFavorite(MediaItem item) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteIds.contains(item.id)) {
      _favoriteIds.remove(item.id);
      item.isFavorite = false;
    } else {
      _favoriteIds.add(item.id);
      item.isFavorite = true;
    }
    await prefs.setStringList(_favsKey, _favoriteIds.toList());
    notifyListeners();
  }

  /// Enregistrer une position de lecture (Historique)
  Future<void> updatePlaybackHistory(
      MediaItem item, int positionMs, int totalMs,) async {
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

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favsKey);
    _favoriteIds.clear();
    for (var item in _allItems) {
      item.isFavorite = false;
    }
    notifyListeners();
  }

  /// Moteur de tri appliqué à une liste
  List<MediaItem> applySort(List<MediaItem> inputList, SortMode mode) {
    final List<MediaItem> sorted = List.from(inputList);

    switch (mode) {
      case SortMode.nameAsc:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortMode.nameDesc:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortMode.ratingDesc:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortMode.yearDesc:
        sorted.sort((a, b) => b.releaseYear.compareTo(a.releaseYear));
        break;
      case SortMode.recentlyAdded:
        sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case SortMode.resumeFirst:
        // Priorité aux vidéos commencées non terminées, puis date de lecture
        sorted.sort((a, b) {
          if (a.isUnfinished && !b.isUnfinished) return -1;
          if (!a.isUnfinished && b.isUnfinished) return 1;
          final aTime = a.lastWatchedAt ?? DateTime(1970);
          final bTime = b.lastWatchedAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
      case SortMode.durationShort:
        sorted.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
      case SortMode.durationLong:
        sorted.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
        break;
    }
    return sorted;
  }
}