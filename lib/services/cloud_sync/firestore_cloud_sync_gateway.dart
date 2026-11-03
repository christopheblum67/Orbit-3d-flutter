import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_gateway.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';

/// Gateway cloud basée sur Cloud Firestore.
///
/// Chaque (utilisateur, scope, profil) est un document unique. La fusion LWW
/// (voir [CloudSyncService]) résout les conflits au niveau entrée.
///
/// Les règles (voir `firestore.rules` à la racine) autorisent les appareils
/// authentifiés à lire/écrire cette collection partagée.
class FirestoreCloudSyncGateway implements CloudSyncGateway {
  FirestoreCloudSyncGateway({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'Un utilisateur Firebase doit être connecté pour synchroniser.',
      );
    }
    return _db.collection('users').doc(uid).collection('orbit_sync');
  }

  String _docId(CloudSyncScope scope, String profileId) =>
      '${scope.name}__$profileId';

  @override
  Future<CloudSyncSnapshot?> fetchSnapshot(
    CloudSyncScope scope,
    String profileId,
  ) async {
    final doc = await _collection.doc(_docId(scope, profileId)).get();
    final data = doc.data();
    if (data == null) return null;
    return CloudSyncSnapshot.fromJson(data);
  }

  @override
  Future<void> pushSnapshot(CloudSyncSnapshot snapshot) async {
    await _collection
        .doc(_docId(snapshot.scope, snapshot.profileId))
        .set(snapshot.toJson());
  }
}
