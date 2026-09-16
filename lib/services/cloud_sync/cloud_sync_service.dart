import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';

/// Résultat de la fusion local ↔ cloud pour un scope donné.
class CloudSyncMergeResult {
  const CloudSyncMergeResult({
    required this.merged,
    required this.localWrites,
    required this.localRemoves,
    required this.remoteWins,
    required this.pushRequired,
  });

  /// Snapshot fusionné : à pousser vers le cloud (si [pushRequired]) et à
  /// mémoriser comme nouveau miroir local.
  final CloudSyncSnapshot merged;

  /// Écritures à appliquer localement : clé -> JSON (maj ou insertion).
  final Map<String, String> localWrites;

  /// Suppressions à appliquer localement (l'entrée a été retirée côté cloud).
  final Set<String> localRemoves;

  /// True si le cloud a imposé des changements à l'appareil local.
  final bool remoteWins;

  /// True si le contenu fusionné diffère du dernier snapshot cloud : une
  /// poussée est nécessaire.
  final bool pushRequired;
}

/// Moteur de fusion Last-Write-Wins par entrée pour la synchronisation cloud.
///
/// Principe :
///  - Chaque entrée du cloud porte un horodatage ([CloudSyncEntry.updatedAt]).
///  - Côté local, l'horodatage d'une entrée *inchangée* est reconstruit depuis
///    le miroir (dernier état cloud connu). Une entrée *modifiée* localement
///    reçoit l'horodatage courant.
///  - L'écriture la plus récente gagne. Sur premier contact (pas de miroir),
///    les deux côtés sont conservés (union), le local étant privilégié en cas
///    de conflit d'une même clé.
class CloudSyncService {
  CloudSyncService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  CloudSyncMergeResult merge({
    required CloudSyncScope scope,
    required String profileId,
    required Map<String, String> local,
    CloudSyncSnapshot? remote,
    CloudSyncSnapshot? mirror,
  }) {
    final now = _now();
    final remoteEntries = remote?.entries ?? const <String, CloudSyncEntry>{};
    final mirrorEntries = mirror?.entries ?? const <String, CloudSyncEntry>{};

    final keys = <String>{
      ...local.keys,
      ...remoteEntries.keys,
      ...mirrorEntries.keys,
    };

    final mergedEntries = <String, CloudSyncEntry>{};
    final localWrites = <String, String>{};
    final localRemoves = <String>{};
    var remoteWins = false;

    for (final key in keys) {
      final localJson = local[key];
      final remoteEntry = remoteEntries[key];
      final mirrorEntry = mirrorEntries[key];

      // Horodatage local reconstruit.
      final DateTime localTs;
      if (localJson == null) {
        // Pas de donnée locale : la clé ne "coûte" rien côté local.
        localTs = _epoch;
      } else if (mirrorEntry != null && mirrorEntry.json == localJson) {
        // Entrée inchangée depuis la dernière sync : on garde son horodatage.
        localTs = mirrorEntry.updatedAt;
      } else {
        // Entrée modifiée localement (ou premier contact) : maintenant.
        localTs = now;
      }
      final remoteTs = remoteEntry?.updatedAt ?? _epoch;

      final remotePresent = remoteEntry != null;
      final remoteWon = remotePresent && remoteTs.isAfter(localTs);

      if (remotePresent) {
        if (remoteWon) {
          // Le cloud est plus récent : on applique sa valeur localement.
          remoteWins = true;
          final j = remoteEntry.json;
          if (localJson == null) {
            if (j.isNotEmpty) localWrites[key] = j;
          } else if (localJson != j) {
            localWrites[key] = j;
          }
          if (j.isNotEmpty) {
            mergedEntries[key] =
                CloudSyncEntry(json: j, updatedAt: remoteTs);
          }
        } else {
          // Local gagne (indifférent) : la valeur locale sera poussée.
          if (localJson != null && localJson.isNotEmpty) {
            mergedEntries[key] =
                CloudSyncEntry(json: localJson, updatedAt: localTs);
          }
        }
      } else if (mirrorEntry != null && localJson != null) {
        // L'entrée existait côté cloud (miroir) et n'y est plus.
        if (localJson == mirrorEntry.json) {
          // Local inchangé : on entérine la suppression cloud.
          remoteWins = true;
          localRemoves.add(key);
        } else {
          // Local modifié depuis : la modification locale ressurvit et sera
          // repoussée au prochain cycle.
          mergedEntries[key] =
              CloudSyncEntry(json: localJson, updatedAt: localTs);
        }
      } else if (localJson != null && localJson.isNotEmpty) {
        mergedEntries[key] = CloudSyncEntry(json: localJson, updatedAt: localTs);
      }
    }

    final snapshot = CloudSyncSnapshot(
      scope: scope,
      profileId: profileId,
      entries: mergedEntries,
      updatedAt: now,
      version: (remote?.version ?? 0) +
          (remote == null && mergedEntries.isNotEmpty ? 1 : 0),
    );
    final pushRequired = remote == null
        ? mergedEntries.isNotEmpty
        : !snapshot.sameContentAs(remote);

    return CloudSyncMergeResult(
      merged: snapshot,
      localWrites: localWrites,
      localRemoves: localRemoves,
      remoteWins: remoteWins,
      pushRequired: pushRequired,
    );
  }
}