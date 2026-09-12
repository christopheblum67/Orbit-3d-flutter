import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

/// Stockage local des favoris (Hive).
///
/// Une entrée = un JSON [FavoriteEntry] sous la clé `"<profileId>:<type>:<id>"`.
/// Le service est sans état : la réactivité est portée par `favoritesProvider`.
class FavoritesService {
  static const String _boxName = 'favorites';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> save(FavoriteEntry entry) async {
    await HiveSync.write(_boxName, (box) => box.put(entry.key, jsonEncode(entry.toJson())));
  }

  Future<void> remove(String key) async {
    await HiveSync.write(_boxName, (box) => box.delete(key));
  }

  Future<bool> isFavorite(String key) async {
    return HiveSync.read(_boxName, (box) => box.containsKey(key));
  }

  /// Charge toutes les entrées favorites persistées (tous profils).
  Future<List<FavoriteEntry>> loadAll() async {
    return HiveSync.read(_boxName, (box) {
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
    });
  }

  /// Charge les favoris d'un profil spécifique.
  Future<List<FavoriteEntry>> loadForProfile(String profileId) async {
    final all = await loadAll();
    return all.where((e) => e.profileId == profileId).toList();
  }
}