import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

/// Stockage local des favoris (Hive).
///
/// Les clés incluent le profil et l'abonnement pour les nouveaux favoris.
/// Le service est sans état : la réactivité est portée par `favoritesProvider`.
class FavoritesService {
  static const String _boxName = 'favorites';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> save(FavoriteEntry entry) async {
    await HiveSync.writeAsync(
      _boxName,
      (box) => box.put(entry.key, jsonEncode(entry.toJson())),
    );
  }

  Future<void> remove(String key) async {
    await HiveSync.writeAsync(_boxName, (box) => box.delete(key));
  }

  Future<bool> isFavorite(String key) async {
    return HiveSync.read(_boxName, (box) => box.containsKey(key));
  }

  /// Charge toutes les entrées favorites persistées (tous profils).
  Future<List<FavoriteEntry>> loadAll() async {
    return HiveSync.read(_boxName, (box) {
      final entries = <FavoriteEntry>[];
      for (final raw in box.values) {
        final result = safeSync(
          () {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              return FavoriteEntry.fromJson(decoded);
            }
            return null;
          },
          context: 'FavoritesService.loadAll decode',
        );
        if (result.isSuccess && result.valueOrNull != null) {
          entries.add(result.valueOrNull!);
        } else if (result.isFailure) {
          LoggerService.instance
              .warning('loadAll decode failed', error: result.errorOrNull);
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

  Future<List<FavoriteEntry>> loadForSubscription(
    String profileId,
    String subscriptionId, {
    bool Function()? canMigrateLegacy,
  }) async {
    await HiveSync.writeAsync(_boxName, (box) async {
      if (canMigrateLegacy?.call() != true) return;
      final keys = box.keys.toList();
      for (final key in keys) {
        final raw = box.get(key);
        if (raw is! String) continue;
        final decoded = safeSync(
          () => jsonDecode(raw),
          context: 'FavoritesService.migrate decode',
        );
        final json = decoded.valueOrNull;
        if (json is! Map<String, dynamic>) continue;
        final old = FavoriteEntry.fromJson(json);
        if (old.profileId != profileId ||
            old.subscriptionId.isNotEmpty ||
            old.key != key ||
            canMigrateLegacy?.call() != true) {
          continue;
        }
        final migrated = old.forSubscription(subscriptionId);
        if (box.containsKey(migrated.key)) continue;
        await box.put(migrated.key, jsonEncode(migrated.toJson()));
        await box.delete(key);
      }
    });
    final all = await loadForProfile(profileId);
    return all
        .where((entry) => entry.subscriptionId == subscriptionId)
        .toList();
  }
}
