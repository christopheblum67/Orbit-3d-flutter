import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';

/// Mémorisation locale des derniers snapshots cloud observés (miroirs).
///
/// Le miroir joue le rôle d'horloge locale : il permet de reconstruire
/// l'horodatage d'une entrée restée inchangée lors de la fusion LWW
/// ([CloudSyncService.merge]).
class CloudSyncMirrorStore {
  static const String _boxName = 'cloud_sync_mirrors';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  String _key(CloudSyncScope scope, String profileId) =>
      '${scope.name}:$profileId';

  Future<CloudSyncSnapshot?> getMirror(
    CloudSyncScope scope,
    String profileId,
  ) async {
    return HiveSync.read(_boxName, (box) {
      final raw = box.get(_key(scope, profileId));
      if (raw == null) return null;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return CloudSyncSnapshot.fromJson(decoded);
        }
      } catch (_) {
        // Miroir corrompu : on repart sans miroir (sync suivante le recrée).
      }
      return null;
    });
  }

  Future<void> saveMirror(CloudSyncSnapshot snapshot) async {
    await HiveSync.writeAsync(
      _boxName,
      (box) => box.put(
        _key(snapshot.scope, snapshot.profileId),
        jsonEncode(snapshot.toJson()),
      ),
    );
  }
}