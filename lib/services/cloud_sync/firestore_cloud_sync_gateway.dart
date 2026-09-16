import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_gateway.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';

/// Gateway cloud basée sur Cloud Firestore.
///
/// Chaque (scope, profil) est un document unique de la collection `orbit_sync` :
/// partie par partie, plusieurs appareils du même compte Firebase lisent et
/// écrivent le même document. La fusion LWW (voir [CloudSyncService]) résout
/// les conflits au niveau entrée.
///
/// Les règles (voir `firestore.rules` à la racine) autorisent les appareils
/// authentifiés à lire/écrire cette collection partagée.
class FirestoreCloudSyncGateway implements CloudSyncGateway {
  FirestoreCloudSyncGateway({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('orbit_sync');

  String _docId(CloudSyncScope scope, String profileId) =>
      '${scope.name}__$profileId';

  @override
  Future<CloudSyncSnapshot?> fetchSnapshot(
    CloudSyncScope scope,
    String profileId,
  ) async {
    try {
      final doc = await _collection.doc(_docId(scope, profileId)).get();
      final data = doc.data();
      if (data == null) return null;
      return CloudSyncSnapshot.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> pushSnapshot(CloudSyncSnapshot snapshot) async {
    await _collection
        .doc(_docId(snapshot.scope, snapshot.profileId))
        .set(snapshot.toJson());
  }
}