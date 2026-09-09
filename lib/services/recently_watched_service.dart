import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';

/// Stockage local « récemment regardé » (Hive).
///
/// Une entrée = un JSON [RecentEntry] sous la clé `"<profileId>:<type>:<id>"`
/// (par ex. `albert:live:42`). Seule la dernière lecture d'un contenu est conservée
/// (remplacement à chaque nouvelle lecture). La liste est bornée à
/// [maxEntries] éléments par profil, les plus récents d'abord.
class RecentlyWatchedService {
  static const String _boxName = 'recently_watched';
  static const int maxEntries = 50;

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> save(RecentEntry entry) async {
    final box = Hive.box<String>(_boxName);
    await box.put(entry.key, jsonEncode(entry.toJson()));
  }

  Future<void> remove(String key) async {
    final box = Hive.box<String>(_boxName);
    await box.delete(key);
  }

  Future<void> clearAll() async {
    final box = Hive.box<String>(_boxName);
    await box.clear();
  }

  /// Returns all persisted entries for a profile, most recent first, capped.
  Future<List<RecentEntry>> loadForProfile(String profileId) async {
    final box = Hive.box<String>(_boxName);
    final entries = <RecentEntry>[];
    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final entry = RecentEntry.fromJson(decoded);
          if (entry.profileId == profileId) entries.add(entry);
        }
      } catch (_) {
        // Entrée corrompue ou au format historique : on l'ignore.
      }
    }
    entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    if (entries.length > maxEntries) {
      return entries.sublist(0, maxEntries);
    }
    return entries;
  }

  /// Legacy: charge toutes les entrées (tous profils confondus) pour compatibilité tests.
  Future<List<RecentEntry>> loadAll() async {
    final box = Hive.box<String>(_boxName);
    final entries = <RecentEntry>[];
    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          entries.add(RecentEntry.fromJson(decoded));
        }
      } catch (_) {
        // Entrée corrompue ou au format historique : on l'ignore.
      }
    }
    entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    if (entries.length > maxEntries) {
      return entries.sublist(0, maxEntries);
    }
    return entries;
  }
}
