import 'dart:convert';

import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';

/// Versioned, encrypted key/value data for one profile and data category.
///
/// The returned revision must be supplied to the next write. A concurrent
/// writer causes [CloudSyncConflict], rather than overwriting its changes.
class EncryptedScopeStore {
  EncryptedScopeStore(this._store);

  static const _schemaVersion = 1;
  static const _maxPlaintextBytes = 700000;
  final EncryptedCloudStore _store;

  String _documentId(String profileId, String scope) {
    if (profileId.isEmpty || scope.isEmpty) {
      throw ArgumentError('Profile and scope are required.');
    }
    final id = base64Url
        .encode(utf8.encode(jsonEncode([profileId, scope])))
        .replaceAll('=', '');
    if (id.length > 500) throw ArgumentError('Profile or scope is too long.');
    return 'scope_$id';
  }

  Future<EncryptedScopeSnapshot?> read({
    required String uid,
    required String profileId,
    required String scope,
    required String passphrase,
  }) async {
    final document = await _store.read(
      uid: uid,
      documentId: _documentId(profileId, scope),
      passphrase: passphrase,
    );
    if (document == null) return null;
    final payload = document.payload;
    final entries = payload['entries'];
    if (payload['schemaVersion'] != _schemaVersion ||
        payload['profileId'] != profileId ||
        payload['scope'] != scope ||
        entries is! Map ||
        entries.entries.any((e) => e.key is! String || e.value is! String)) {
      throw const FormatException('Données de synchronisation invalides.');
    }
    return EncryptedScopeSnapshot(
      revision: document.revision,
      entries: Map<String, String>.from(entries),
    );
  }

  Future<int> write({
    required String uid,
    required String profileId,
    required String scope,
    required String passphrase,
    required EncryptedScopeSnapshot snapshot,
  }) {
    final documentId = _documentId(profileId, scope);
    final payload = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'profileId': profileId,
      'scope': scope,
      'entries': snapshot.entries,
    };
    if (utf8.encode(jsonEncode(payload)).length > _maxPlaintextBytes) {
      throw StateError(
        'Les données à synchroniser dépassent la taille autorisée.',
      );
    }
    return _store.write(
      uid: uid,
      documentId: documentId,
      passphrase: passphrase,
      payload: payload,
      expectedRevision: snapshot.revision,
    );
  }
}

class EncryptedScopeSnapshot {
  EncryptedScopeSnapshot({
    required this.revision,
    required Map<String, String> entries,
  }) : entries = Map.unmodifiable(entries) {
    if (revision < 0) throw ArgumentError.value(revision, 'revision');
  }

  final int revision;
  final Map<String, String> entries;
}

class ScopeMergeConflict implements Exception {
  ScopeMergeConflict(Set<String> keys) : keys = Set.unmodifiable(keys);

  final Set<String> keys;

  @override
  String toString() => 'Des modifications concurrentes nécessitent un choix.';
}

/// A three-way merge that never silently chooses between concurrent edits.
Map<String, String> mergeScopeEntries({
  required Map<String, String> local,
  required Map<String, String> remote,
  Map<String, String>? baseline,
}) {
  final merged = <String, String>{};
  final conflicts = <String>{};
  final keys = <String>{...local.keys, ...remote.keys, ...?baseline?.keys};
  for (final key in keys) {
    final localValue = local[key];
    final remoteValue = remote[key];
    String? value;
    if (localValue == remoteValue) {
      value = localValue;
    } else if (baseline == null) {
      if (localValue != null && remoteValue != null) {
        conflicts.add(key);
        continue;
      }
      value = localValue ?? remoteValue;
    } else {
      final baseValue = baseline[key];
      if (localValue == baseValue) {
        value = remoteValue;
      } else if (remoteValue == baseValue) {
        value = localValue;
      } else {
        conflicts.add(key);
        continue;
      }
    }
    if (value != null) merged[key] = value;
  }
  if (conflicts.isNotEmpty) throw ScopeMergeConflict(conflicts);
  return Map.unmodifiable(merged);
}
