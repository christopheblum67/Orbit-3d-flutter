import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_cipher.dart';

class CloudSyncConflict implements Exception {
  const CloudSyncConflict();

  @override
  String toString() =>
      'Le document cloud a changé sur un autre appareil. Rechargez-le avant de réessayer.';
}

class EncryptedCloudDocument {
  const EncryptedCloudDocument({required this.revision, required this.payload});

  final int revision;
  final Map<String, dynamic> payload;
}

abstract interface class EncryptedDocumentStore {
  Future<Map<String, dynamic>?> read(String uid, String documentId);

  Future<void> writeIfRevisionMatches(
    String uid,
    String documentId,
    int expectedRevision,
    Map<String, dynamic> data,
  );
}

abstract interface class EncryptedCloudMaintenance {
  Future<void> deleteDocument(String uid, String documentId);

  Future<int> deleteAllData(String uid);
}

abstract interface class EncryptedCloudChangeSource {
  Stream<String> watch(String uid);
}

class FirestoreEncryptedCloudChangeSource
    implements EncryptedCloudChangeSource {
  FirestoreEncryptedCloudChangeSource(
      {FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<String> watch(String uid) async* {
    void checkAccount() {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous || user.uid != uid) {
        throw StateError('Le compte cloud a changé.');
      }
    }

    checkAccount();
    final collection =
        _firestore.collection('users').doc(uid).collection('encrypted_sync');
    var initialSnapshot = true;
    await for (final snapshot in collection.snapshots()) {
      checkAccount();
      if (initialSnapshot) {
        initialSnapshot = false;
        continue;
      }
      for (final change in snapshot.docChanges) {
        if (!change.doc.metadata.hasPendingWrites) yield change.doc.id;
      }
    }
  }
}

/// Stores encrypted envelopes only. The caller must handle revision conflicts.
class EncryptedCloudStore {
  EncryptedCloudStore(
      {required EncryptedDocumentStore store, CloudSyncCipher? cipher})
      : _store = store,
        _cipher = cipher ?? CloudSyncCipher();

  final EncryptedDocumentStore _store;
  final CloudSyncCipher _cipher;

  static const controlDocumentId = '__control__';
  static const _controlSchemaVersion = 1;

  Future<({int generation, int floorGeneration})> _readControl({
    required String uid,
    required String passphrase,
  }) async {
    final stored = await _store.read(uid, controlDocumentId);
    if (stored == null) return (generation: 0, floorGeneration: 0);
    final revision = stored['revision'];
    final generation = stored['generation'];
    final rawEnvelope = stored['envelope'];
    if (revision is! int ||
        revision < 1 ||
        generation is! int ||
        generation < 1 ||
        rawEnvelope is! Map) {
      throw const FormatException('État de synchronisation cloud invalide.');
    }
    final plaintext = await _cipher.decrypt(
      envelope: Map<String, dynamic>.from(rawEnvelope),
      passphrase: passphrase,
      userId: uid,
      documentId: _authenticatedDocumentId(controlDocumentId, revision),
    );
    final payload = jsonDecode(plaintext);
    if (payload is! Map<String, dynamic> ||
        payload['schemaVersion'] != _controlSchemaVersion ||
        payload['generation'] != generation ||
        payload['floorGeneration'] is! int ||
        (payload['floorGeneration'] as int) < 0 ||
        (payload['floorGeneration'] as int) > generation) {
      throw const FormatException('État de synchronisation cloud invalide.');
    }
    return (
      generation: generation,
      floorGeneration: payload['floorGeneration'] as int,
    );
  }

  Future<EncryptedCloudDocument?> read({
    required String uid,
    required String documentId,
    required String passphrase,
  }) async {
    if (documentId == controlDocumentId) {
      throw ArgumentError.value(documentId, 'documentId');
    }
    final control = await _readControl(uid: uid, passphrase: passphrase);
    final stored = await _store.read(uid, documentId);
    if (stored == null) return null;
    final revision = stored['revision'];
    final generation = stored['generation'] ?? 0;
    final rawEnvelope = stored['envelope'];
    if (revision is! int ||
        revision < 1 ||
        generation is! int ||
        generation < 0 ||
        generation > control.generation ||
        rawEnvelope is! Map) {
      throw const FormatException('Document cloud chiffré invalide.');
    }
    if (generation < control.floorGeneration) return null;
    final plaintext = await _cipher.decrypt(
      envelope: Map<String, dynamic>.from(rawEnvelope),
      passphrase: passphrase,
      userId: uid,
      documentId: _authenticatedDocumentId(documentId, revision),
    );
    final payload = jsonDecode(plaintext);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Contenu cloud chiffré invalide.');
    }
    return EncryptedCloudDocument(revision: revision, payload: payload);
  }

  Future<int> write({
    required String uid,
    required String documentId,
    required String passphrase,
    required Map<String, dynamic> payload,
    required int expectedRevision,
    void Function()? checkSession,
  }) async {
    if (expectedRevision < 0) {
      throw ArgumentError.value(expectedRevision, 'expectedRevision');
    }
    if (documentId == controlDocumentId) {
      throw ArgumentError.value(documentId, 'documentId');
    }
    final control = await _readControl(uid: uid, passphrase: passphrase);
    final envelope = await _cipher.encrypt(
      plaintext: jsonEncode(payload),
      passphrase: passphrase,
      userId: uid,
      documentId: _authenticatedDocumentId(documentId, expectedRevision + 1),
    );
    final nextRevision = expectedRevision + 1;
    checkSession?.call();
    await _store.writeIfRevisionMatches(uid, documentId, expectedRevision, {
      'revision': nextRevision,
      'generation': control.generation,
      'envelope': envelope,
    });
    return nextRevision;
  }

  Future<int> advanceGeneration({
    required String uid,
    required String passphrase,
    required bool reset,
  }) async {
    final existing = await _store.read(uid, controlDocumentId);
    final revision = existing == null ? 0 : existing['revision'];
    final generation = existing == null ? 0 : existing['generation'];
    if (revision is! int ||
        revision < 0 ||
        generation is! int ||
        generation < 0 ||
        (existing != null && (revision == 0 || generation == 0))) {
      throw const FormatException('État de synchronisation cloud invalide.');
    }
    final nextRevision = revision + 1;
    final nextGeneration = generation + 1;
    final floorGeneration = reset
        ? nextGeneration
        : existing == null
            ? 0
            : (await _readControl(uid: uid, passphrase: passphrase))
                .floorGeneration;
    final envelope = await _cipher.encrypt(
      plaintext: jsonEncode({
        'schemaVersion': _controlSchemaVersion,
        'generation': nextGeneration,
        'floorGeneration': floorGeneration,
      }),
      passphrase: passphrase,
      userId: uid,
      documentId: _authenticatedDocumentId(controlDocumentId, nextRevision),
    );
    await _store.writeIfRevisionMatches(uid, controlDocumentId, revision, {
      'revision': nextRevision,
      'generation': nextGeneration,
      'envelope': envelope,
    });
    return nextGeneration;
  }

  Future<bool> hasVerifiedControl({
    required String uid,
    required String passphrase,
  }) async =>
      (await _readControl(uid: uid, passphrase: passphrase)).generation > 0;

  Future<void> deleteDocument(String uid, String documentId) async {
    final maintenance = _store;
    if (maintenance is! EncryptedCloudMaintenance) {
      throw UnsupportedError('La suppression cloud n’est pas disponible.');
    }
    if (documentId == controlDocumentId) {
      throw ArgumentError.value(documentId, 'documentId');
    }
    await (maintenance as EncryptedCloudMaintenance)
        .deleteDocument(uid, documentId);
  }

  Future<int> deleteAllData(String uid) async {
    final maintenance = _store;
    if (maintenance is! EncryptedCloudMaintenance) {
      throw UnsupportedError('La suppression cloud n’est pas disponible.');
    }
    return (maintenance as EncryptedCloudMaintenance).deleteAllData(uid);
  }

  String _authenticatedDocumentId(String documentId, int revision) =>
      jsonEncode([documentId, revision]);
}

class FirestoreEncryptedDocumentStore
    implements EncryptedDocumentStore, EncryptedCloudMaintenance {
  FirestoreEncryptedDocumentStore(
      {FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _document(
    String uid,
    String documentId,
  ) {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Connectez-vous au compte cloud avant de synchroniser.');
    }
    if (documentId.isEmpty || documentId.contains('/')) {
      throw ArgumentError.value(documentId, 'documentId');
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('encrypted_sync')
        .doc(documentId);
  }

  @override
  Future<Map<String, dynamic>?> read(String uid, String documentId) async {
    final snapshot = await _document(uid, documentId).get(
      const GetOptions(source: Source.server),
    );
    _document(uid, documentId);
    return snapshot.data();
  }

  @override
  Future<void> writeIfRevisionMatches(
    String uid,
    String documentId,
    int expectedRevision,
    Map<String, dynamic> data,
  ) async {
    final document = _document(uid, documentId);
    await _firestore.runTransaction((transaction) async {
      _document(uid, documentId);
      final snapshot = await transaction.get(document);
      final existing = snapshot.data();
      final currentRevision = existing == null ? 0 : existing['revision'];
      if (currentRevision is! int || currentRevision < 0) {
        throw const FormatException('Révision cloud invalide.');
      }
      if (currentRevision != expectedRevision) throw const CloudSyncConflict();
      _document(uid, documentId);
      transaction.set(document, data);
    });
  }

  @override
  Future<void> deleteDocument(String uid, String documentId) async {
    if (documentId == EncryptedCloudStore.controlDocumentId) {
      throw ArgumentError.value(documentId, 'documentId');
    }
    await _document(uid, documentId).delete();
    _document(uid, documentId);
  }

  @override
  Future<int> deleteAllData(String uid) async {
    final collection =
        _firestore.collection('users').doc(uid).collection('encrypted_sync');
    var deleted = 0;
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      _document(uid, EncryptedCloudStore.controlDocumentId);
      var query = collection.orderBy(FieldPath.documentId).limit(450);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final page = await query.get(const GetOptions(source: Source.server));
      if (page.docs.isEmpty) return deleted;
      final batch = _firestore.batch();
      var pageDeleted = 0;
      for (final document in page.docs) {
        if (document.id == EncryptedCloudStore.controlDocumentId) continue;
        batch.delete(document.reference);
        pageDeleted++;
      }
      if (pageDeleted > 0) await batch.commit();
      deleted += pageDeleted;
      cursor = page.docs.last;
    }
  }
}
