import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';

/// Point d'accès au stockage cloud de la synchronisation (S2).
///
/// Abstraction volontairement étroite : lecture d'un snapshot et poussée d'un
/// snapshot. L'implémentation Firestore est branchée en production ; une
/// implémentation en mémoire sert aux tests.
abstract interface class CloudSyncGateway {
  Future<CloudSyncSnapshot?> fetchSnapshot(CloudSyncScope scope, String profileId);

  Future<void> pushSnapshot(CloudSyncSnapshot snapshot);
}

/// Gateway en mémoire — réservée aux tests unitaires.
class InMemoryCloudSyncGateway implements CloudSyncGateway {
  final Map<String, CloudSyncSnapshot> store = {};

  String key(CloudSyncScope scope, String profileId) => '${scope.name}:$profileId';

  @override
  Future<CloudSyncSnapshot?> fetchSnapshot(
    CloudSyncScope scope,
    String profileId,
  ) async =>
      store[key(scope, profileId)];

  @override
  Future<void> pushSnapshot(CloudSyncSnapshot snapshot) async {
    store[key(snapshot.scope, snapshot.profileId)] = snapshot;
  }

  int get count => store.length;
}