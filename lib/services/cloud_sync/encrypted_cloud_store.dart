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

/// Stores encrypted envelopes only. The caller must handle revision conflicts.
class EncryptedCloudStore {
  EncryptedCloudStore(
      {required EncryptedDocumentStore store, CloudSyncCipher? cipher})
      : _store = store,
        _cipher = cipher ?? CloudSyncCipher();

  final EncryptedDocumentStore _store;
  final CloudSyncCipher _cipher;

  Future<EncryptedCloudDocument?> read({
    required String uid,
    required String documentId,
    required String passphrase,
  }) async {
    final stored = await _store.read(uid, documentId);
    if (stored == null) return null;
    final revision = stored['revision'];
    final rawEnvelope = stored['envelope'];
    if (revision is! int || revision < 1 || rawEnvelope is! Map) {
      throw const FormatException('Document cloud chiffré invalide.');
    }
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
  }) async {
    if (expectedRevision < 0) {
      throw ArgumentError.value(expectedRevision, 'expectedRevision');
    }
    final envelope = await _cipher.encrypt(
      plaintext: jsonEncode(payload),
      passphrase: passphrase,
      userId: uid,
      documentId: _authenticatedDocumentId(documentId, expectedRevision + 1),
    );
    final nextRevision = expectedRevision + 1;
    await _store.writeIfRevisionMatches(uid, documentId, expectedRevision, {
      'revision': nextRevision,
      'envelope': envelope,
    });
    return nextRevision;
  }

  String _authenticatedDocumentId(String documentId, int revision) =>
      jsonEncode([documentId, revision]);
}

class FirestoreEncryptedDocumentStore implements EncryptedDocumentStore {
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
}
