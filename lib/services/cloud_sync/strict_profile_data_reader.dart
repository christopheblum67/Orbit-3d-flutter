import 'dart:convert';

import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';

/// Reads only the requested profile and fails rather than omitting corrupt data.
class StrictProfileDataReader {
  const StrictProfileDataReader();

  Future<List<FavoriteEntry>> favorites(String profileId) => _read(
        'favorites',
        profileId,
        (json) {
          _requireString(json, 'id');
          _requireString(json, 'title');
          _requireContentType(json);
          return FavoriteEntry.fromJson(json);
        },
        (entry) => entry.key,
      );

  Future<List<RecentEntry>> recents(String profileId) => _read(
        'recently_watched',
        profileId,
        (json) {
          _requireString(json, 'id');
          _requireString(json, 'title');
          _requireContentType(json);
          _requireDate(json, 'watchedAt');
          return RecentEntry.fromJson(json);
        },
        (entry) => entry.key,
      );

  Future<List<WatchedEpisodeEntry>> watchedEpisodes(String profileId) => _read(
        'watched_episodes',
        profileId,
        (json) {
          _requireString(json, 'seriesId');
          _requireDate(json, 'watchedAt');
          if (json['season'] is! num || json['episodeNumber'] is! num) {
            throw const FormatException('Numéro d’épisode invalide.');
          }
          return WatchedEpisodeEntry.fromJson(json);
        },
        (entry) => entry.key,
      );

  Future<List<T>> _read<T>(
    String boxName,
    String profileId,
    T Function(Map<String, dynamic>) decode,
    String Function(T) entryKey,
  ) {
    if (profileId.isEmpty || profileId.contains(':')) {
      throw ArgumentError.value(profileId, 'profileId');
    }
    return HiveSync.read(boxName, (box) {
      final result = <T>[];
      for (final key in box.keys) {
        if (key is! String || !key.startsWith('$profileId:')) continue;
        final raw = box.get(key);
        if (raw is! String) {
          throw FormatException('Donnée locale illisible dans $boxName.');
        }
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic> ||
            decoded['profileId'] != profileId) {
          throw FormatException('Donnée locale invalide dans $boxName.');
        }
        final entry = decode(decoded);
        if (entryKey(entry) != key) {
          throw FormatException('Identité locale invalide dans $boxName.');
        }
        result.add(entry);
      }
      return result;
    });
  }

  static void _requireString(Map<String, dynamic> json, String key) {
    if (json[key] is! String || (json[key] as String).isEmpty) {
      throw FormatException('Champ local invalide : $key.');
    }
  }

  static void _requireDate(Map<String, dynamic> json, String key) {
    if (json[key] is! String ||
        DateTime.tryParse(json[key] as String) == null) {
      throw FormatException('Date locale invalide : $key.');
    }
  }

  static void _requireContentType(Map<String, dynamic> json) {
    if (json['type'] is! String ||
        !ContentType.values.any((type) => type.name == json['type'])) {
      throw const FormatException('Type de contenu local invalide.');
    }
  }
}
