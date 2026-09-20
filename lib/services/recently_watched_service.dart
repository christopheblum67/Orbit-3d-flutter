import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

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
    await Hive.openBox(_boxName);
  }

  Future<void> save(RecentEntry entry) async {
    await HiveSync.writeAsync(_boxName, (box) => box.put(entry.key, jsonEncode(entry.toJson())));
  }

  Future<void> remove(String key) async {
    await HiveSync.writeAsync(_boxName, (box) => box.delete(key));
  }

  Future<void> clearAll() async {
    await HiveSync.writeAsync(_boxName, (box) => box.clear());
  }

  /// Returns all persisted entries for a profile, most recent first, capped.
  Future<List<RecentEntry>> loadForProfile(String profileId) async {
    return HiveSync.read(_boxName, (box) {
      final entries = <RecentEntry>[];
      for (final raw in box.values) {
        final entry = safeSync<RecentEntry?>(
          () {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              return RecentEntry.fromJson(decoded);
            }
            return null;
          },
          context: 'RecentlyWatchedService.loadForProfile.decode',
        ).valueOrNull;
        if (entry != null && entry.profileId == profileId) entries.add(entry);
      }
      entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      if (entries.length > maxEntries) {
        return entries.sublist(0, maxEntries);
      }
      return entries;
    });
  }

  /// Legacy: charge toutes les entrées (tous profils confondus) pour compatibilité tests.
  Future<List<RecentEntry>> loadAll() async {
    return HiveSync.read(_boxName, (box) {
      final entries = <RecentEntry>[];
      for (final raw in box.values) {
        final entry = safeSync<RecentEntry?>(
          () {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              return RecentEntry.fromJson(decoded);
            }
            return null;
          },
          context: 'RecentlyWatchedService.loadAll.decode',
        ).valueOrNull;
        if (entry != null) entries.add(entry);
      }
      entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      if (entries.length > maxEntries) {
        return entries.sublist(0, maxEntries);
      }
      return entries;
    });
  }
}