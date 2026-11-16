import 'dart:convert';

import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';

/// An explicit snapshot of independent profiles, never merged by name.
class EncryptedProfileCatalog {
  EncryptedProfileCatalog(this._store);

  static const documentId = 'profiles';
  static const _schemaVersion = 1;
  // Base64 encoding and Firestore field overhead must fit its 1 MiB limit.
  static const _maxPlaintextBytes = 700000;
  final EncryptedCloudStore _store;

  Future<ProfileCatalogSnapshot> load({
    required String uid,
    required String passphrase,
  }) async {
    final document = await _store.read(
      uid: uid,
      documentId: documentId,
      passphrase: passphrase,
    );
    if (document == null) {
      return ProfileCatalogSnapshot(revision: 0, profiles: const {});
    }
    final payload = document.payload;
    final rawProfiles = payload['profiles'];
    if (payload['schemaVersion'] != _schemaVersion || rawProfiles is! Map) {
      throw const FormatException('Catalogue cloud non reconnu.');
    }
    final profiles = <String, Map<String, dynamic>>{};
    for (final entry in rawProfiles.entries) {
      if (entry.key is! String ||
          (entry.key as String).isEmpty ||
          entry.value is! Map) {
        throw const FormatException('Profil cloud invalide.');
      }
      final profile = Map<String, dynamic>.from(entry.value as Map);
      if (profile['id'] != entry.key || profile['firstName'] is! String) {
        throw const FormatException('Identité du profil cloud invalide.');
      }
      profiles[entry.key as String] = profile;
    }
    return ProfileCatalogSnapshot(
        revision: document.revision, profiles: profiles);
  }

  /// Requires the last explicitly loaded revision; concurrent updates fail.
  Future<int> save({
    required String uid,
    required String passphrase,
    required ProfileCatalogSnapshot snapshot,
    void Function()? checkSession,
  }) async {
    for (final entry in snapshot.profiles.entries) {
      if (entry.key.isEmpty ||
          entry.value['id'] != entry.key ||
          entry.value['firstName'] is! String) {
        throw const FormatException('Identité du profil invalide.');
      }
    }
    final payload = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'profiles': snapshot.profiles,
    };
    if (utf8.encode(jsonEncode(payload)).length > _maxPlaintextBytes) {
      throw StateError('Le catalogue de profils dépasse la taille autorisée.');
    }
    return _store.write(
      uid: uid,
      documentId: documentId,
      passphrase: passphrase,
      payload: payload,
      expectedRevision: snapshot.revision,
      checkSession: checkSession,
    );
  }

  /// Publishes a new profile without replacing an existing profile or merging
  /// profiles that happen to have the same display name.
  Future<int> publishNewProfile({
    required String uid,
    required String passphrase,
    required Map<String, dynamic> profile,
  }) async {
    final id = profile['id'];
    if (id is! String || id.isEmpty || profile['firstName'] is! String) {
      throw const FormatException('Identité du profil invalide.');
    }
    final current = await load(uid: uid, passphrase: passphrase);
    if (current.profiles.containsKey(id)) {
      throw StateError('Ce profil existe déjà dans le cloud.');
    }
    return save(
      uid: uid,
      passphrase: passphrase,
      snapshot: ProfileCatalogSnapshot(
        revision: current.revision,
        profiles: {...current.profiles, id: profile},
      ),
    );
  }
}

class ProfileCatalogSnapshot {
  ProfileCatalogSnapshot({
    required this.revision,
    required Map<String, Map<String, dynamic>> profiles,
  }) : profiles = Map<String, Map<String, dynamic>>.unmodifiable(
          profiles.map(
            (key, value) =>
                MapEntry(key, Map<String, dynamic>.unmodifiable(value)),
          ),
        );

  final int revision;
  final Map<String, Map<String, dynamic>> profiles;
}
