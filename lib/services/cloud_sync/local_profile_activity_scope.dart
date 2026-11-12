import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';

enum ProfileActivityKind { favorites, recents, watched, playback }

/// Reads and conditionally updates only one profile in its existing Hive box.
class LocalProfileActivityScope implements LocalSyncScope {
  LocalProfileActivityScope(this.profileId, this.kind) {
    if (profileId.isEmpty || profileId.contains(':')) {
      throw ArgumentError.value(profileId, 'profileId');
    }
  }

  final String profileId;
  final ProfileActivityKind kind;

  String get _boxName => switch (kind) {
        ProfileActivityKind.favorites => 'favorites',
        ProfileActivityKind.recents => 'recently_watched',
        ProfileActivityKind.watched => 'watched_episodes',
        ProfileActivityKind.playback => 'playback_progress',
      };

  String get _prefix => kind == ProfileActivityKind.playback
      ? 'profile:$profileId:'
      : '$profileId:';

  String _boxKey(String key) =>
      kind == ProfileActivityKind.playback ? '$_prefix$key' : key;

  Map<String, String> _readBox(Box<dynamic> box) {
    final result = <String, String>{};
    for (final rawKey in box.keys) {
      if (rawKey is! String || !rawKey.startsWith(_prefix)) continue;
      final raw = box.get(rawKey);
      if (raw is! String) {
        throw const FormatException('Donnée locale de profil invalide.');
      }
      final key = kind == ProfileActivityKind.playback
          ? rawKey.substring(_prefix.length)
          : rawKey;
      _validate(key, raw);
      result[key] = raw;
    }
    return result;
  }

  void _validate(String key, String raw) {
    if (key.isEmpty) throw const FormatException('Identifiant invalide.');
    if (kind == ProfileActivityKind.playback) {
      final parts = raw.split('|');
      if (parts.length != 3 ||
          parts.any((part) => int.tryParse(part) == null) ||
          int.parse(parts[0]) < 0 ||
          int.parse(parts[1]) < 0) {
        throw const FormatException('Progression de lecture invalide.');
      }
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['profileId'] != profileId) {
      throw const FormatException('Profil ou donnée invalide.');
    }
    bool validString(String field) => decoded[field] is String;
    bool validDate(String field) =>
        decoded[field] is String &&
        DateTime.tryParse(decoded[field] as String) != null;

    switch (kind) {
      case ProfileActivityKind.favorites:
      case ProfileActivityKind.recents:
        if (!validString('id') ||
            (decoded['id'] as String).isEmpty ||
            !validString('title') ||
            !ContentType.values.any((type) => type.name == decoded['type']) ||
            (kind == ProfileActivityKind.recents && !validDate('watchedAt'))) {
          throw const FormatException('Contenu du profil invalide.');
        }
        final actualKey = kind == ProfileActivityKind.favorites
            ? FavoriteEntry.fromJson(decoded).key
            : RecentEntry.fromJson(decoded).key;
        if (key != actualKey) throw const FormatException('Clé invalide.');
      case ProfileActivityKind.watched:
        if (!validString('seriesId') ||
            (decoded['seriesId'] as String).isEmpty ||
            decoded['season'] is! int ||
            decoded['episodeNumber'] is! int ||
            !validString('episodeId') ||
            !validDate('watchedAt') ||
            WatchedEpisodeEntry.fromJson(decoded).key != key) {
          throw const FormatException('Épisode regardé invalide.');
        }
      case ProfileActivityKind.playback:
        throw StateError('Unreachable');
    }
  }

  @override
  Future<Map<String, String>> read() => HiveSync.read(_boxName, _readBox);

  @override
  void validate(Map<String, String> entries) {
    for (final entry in entries.entries) {
      _validate(entry.key, entry.value);
    }
  }

  @override
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) async {
    validate(merged);
    await HiveSync.writeAsync(_boxName, (box) async {
      checkSession();
      if (!mapEquals(_readBox(box), expected)) {
        throw StateError('Les données locales ont changé. Réessayez.');
      }
      final updates = <String, String>{
        for (final entry in merged.entries)
          if (expected[entry.key] != entry.value)
            _boxKey(entry.key): entry.value,
      };
      final removes = <String>[
        for (final key in expected.keys)
          if (!merged.containsKey(key)) _boxKey(key),
      ];
      if (updates.isNotEmpty) await box.putAll(updates);
      checkSession();
      if (removes.isNotEmpty) await box.deleteAll(removes);
    });
  }
}
