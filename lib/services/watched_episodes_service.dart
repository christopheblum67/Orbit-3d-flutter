import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

/// Stockage local « épisodes déjà vus » (Hive).
///
/// Une entrée = un JSON [WatchedEpisodeEntry] sous la clé canonique
/// `"<profileId>:<seriesId>:S<saison>E<épisode>"`. Le service est sans état :
/// la réactivité est portée par `watchedEpisodesProvider`.
class WatchedEpisodesService {
  static const String _boxName = 'watched_episodes';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> save(WatchedEpisodeEntry entry) async {
    await HiveSync.writeAsync(_boxName, (box) => box.put(entry.key, jsonEncode(entry.toJson())));
  }

  Future<void> remove(String key) async {
    await HiveSync.writeAsync(_boxName, (box) => box.delete(key));
  }

  Future<bool> isWatched(String key) async {
    return HiveSync.read(_boxName, (box) => box.containsKey(key));
  }

  /// Charge tous les épisodes vus (tous profils confondus).
  Future<List<WatchedEpisodeEntry>> loadAll() async {
    return HiveSync.read(_boxName, (box) {
      final entries = <WatchedEpisodeEntry>[];
      for (final raw in box.values) {
        final result = safeSync(
          () {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              return WatchedEpisodeEntry.fromJson(decoded);
            }
            return null;
          },
          context: 'WatchedEpisodesService.loadAll decode',
        );
        if (result.isSuccess && result.valueOrNull != null) {
          entries.add(result.valueOrNull!);
        } else if (result.isFailure) {
          LoggerService.instance.warning('loadAll decode failed', error: result.errorOrNull);
        }
      }
      return entries;
    });
  }

  /// Charge les épisodes vus d'un profil spécifique.
  Future<List<WatchedEpisodeEntry>> loadForProfile(String profileId) async {
    final all = await loadAll();
    return all.where((e) => e.profileId == profileId).toList();
  }
}