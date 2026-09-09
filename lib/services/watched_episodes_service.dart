import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';

/// Stockage local « épisodes déjà vus » (Hive).
///
/// Une entrée = un JSON [WatchedEpisodeEntry] sous la clé canonique
/// `"<profileId>:<seriesId>:S<saison>E<épisode>"`. Le service est sans état :
/// la réactivité est portée par `watchedEpisodesProvider`.
class WatchedEpisodesService {
  static const String _boxName = 'watched_episodes';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> save(WatchedEpisodeEntry entry) async {
    final box = Hive.box<String>(_boxName);
    await box.put(entry.key, jsonEncode(entry.toJson()));
  }

  Future<void> remove(String key) async {
    final box = Hive.box<String>(_boxName);
    await box.delete(key);
  }

  Future<bool> isWatched(String key) async {
    final box = Hive.box<String>(_boxName);
    return box.containsKey(key);
  }

  /// Charge tous les épisodes vus (tous profils confondus).
  Future<List<WatchedEpisodeEntry>> loadAll() async {
    final box = Hive.box<String>(_boxName);
    final entries = <WatchedEpisodeEntry>[];
    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          entries.add(WatchedEpisodeEntry.fromJson(decoded));
        }
      } catch (_) {
        // Entrée corrompue ou au format historique : on l'ignore.
      }
    }
    return entries;
  }

  /// Charge les épisodes vus d'un profil spécifique.
  Future<List<WatchedEpisodeEntry>> loadForProfile(String profileId) async {
    final all = await loadAll();
    return all.where((e) => e.profileId == profileId).toList();
  }
}