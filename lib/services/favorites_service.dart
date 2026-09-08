import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';

/// Stockage local des favoris (Hive).
///
/// Une entrée = un JSON [FavoriteEntry] sous la clé canonique
/// `"<type>:<id>"` (par ex. `live:42`). Le service est délibérément sans état :
/// la réactivité est portée par `favoritesProvider` (`FavoritesNotifier`).
class FavoritesService {
  static const String _boxName = 'favorites';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> save(FavoriteEntry entry) async {
    final box = Hive.box<String>(_boxName);
    await box.put(entry.key, jsonEncode(entry.toJson()));
  }

  Future<void> remove(String key) async {
    final box = Hive.box<String>(_boxName);
    await box.delete(key);
  }

  Future<bool> isFavorite(String key) async {
    final box = Hive.box<String>(_boxName);
    return box.containsKey(key);
  }

  /// Charge toutes les entrées favorites persistées (la liste n'est pas triée,
  /// l'ordre d'affichage est géré par l'écran).
  Future<List<FavoriteEntry>> loadAll() async {
    final box = Hive.box<String>(_boxName);
    final entries = <FavoriteEntry>[];
    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          entries.add(FavoriteEntry.fromJson(decoded));
        }
      } catch (_) {
        // Entrée corrompue ou au format historique : on l'ignore.
      }
    }
    return entries;
  }
}
