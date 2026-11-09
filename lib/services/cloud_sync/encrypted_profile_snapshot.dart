import 'dart:convert';

import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';

/// Stores a profile's data as one encrypted document with optimistic locking.
///
/// The caller must resolve conflicts and decide explicitly how to apply a
/// downloaded snapshot; reading it never changes the local profile.
class EncryptedProfileSnapshotStore {
  EncryptedProfileSnapshotStore(this._store);

  static const int _schemaVersion = 1;
  static const int _maxPlaintextBytes = 700000;
  final EncryptedCloudStore _store;

  String _documentId(String profileId) {
    if (profileId.isEmpty || utf8.encode(profileId).length > 500) {
      throw ArgumentError.value(profileId, 'profileId');
    }
    return 'profile_${base64Url.encode(utf8.encode(profileId)).replaceAll('=', '')}';
  }

  Future<ProfileDataSnapshot?> read({
    required String uid,
    required String profileId,
    required String passphrase,
  }) async {
    final document = await _store.read(
      uid: uid,
      documentId: _documentId(profileId),
      passphrase: passphrase,
    );
    if (document == null) return null;
    return ProfileDataSnapshot.fromPayload(
      document.payload,
      expectedProfileId: profileId,
      revision: document.revision,
    );
  }

  Future<int> write({
    required String uid,
    required String passphrase,
    required ProfileDataSnapshot snapshot,
  }) async {
    final payload = snapshot.toPayload();
    if (utf8.encode(jsonEncode(payload)).length > _maxPlaintextBytes) {
      throw StateError('Les données du profil dépassent la taille autorisée.');
    }
    return _store.write(
      uid: uid,
      documentId: _documentId(snapshot.profileId),
      passphrase: passphrase,
      payload: payload,
      expectedRevision: snapshot.revision,
    );
  }
}

class ProfileDataSnapshot {
  ProfileDataSnapshot({
    required this.profileId,
    required this.revision,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> preferences,
    required List<Map<String, dynamic>> favorites,
    required List<Map<String, dynamic>> recents,
    required List<Map<String, dynamic>> watchedEpisodes,
    required Map<String, Map<String, dynamic>> playback,
  })  : profile = Map.unmodifiable(profile),
        preferences = Map.unmodifiable(preferences),
        favorites = _copyList(favorites),
        recents = _copyList(recents),
        watchedEpisodes = _copyList(watchedEpisodes),
        playback = Map.unmodifiable(
          playback.map(
            (key, value) =>
                MapEntry(key, Map<String, dynamic>.unmodifiable(value)),
          ),
        ) {
    _validate();
  }

  final String profileId;
  final int revision;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> preferences;
  final List<Map<String, dynamic>> favorites;
  final List<Map<String, dynamic>> recents;
  final List<Map<String, dynamic>> watchedEpisodes;
  final Map<String, Map<String, dynamic>> playback;

  static List<Map<String, dynamic>> _copyList(
    List<Map<String, dynamic>> values,
  ) =>
      List.unmodifiable(values.map(Map<String, dynamic>.unmodifiable));

  void _validate() {
    if (profileId.isEmpty ||
        revision < 0 ||
        profile['id'] != profileId ||
        profile['firstName'] is! String) {
      throw const FormatException('Identité du profil invalide.');
    }
    for (final entry in [...favorites, ...recents, ...watchedEpisodes]) {
      if (entry['profileId'] != profileId) {
        throw const FormatException('Données associées à un autre profil.');
      }
    }
    if (playback.keys.any((key) => key.isEmpty)) {
      throw const FormatException('Identifiant de lecture invalide.');
    }
  }

  Map<String, dynamic> toPayload() => {
        'schemaVersion': EncryptedProfileSnapshotStore._schemaVersion,
        'profileId': profileId,
        'profile': profile,
        'preferences': preferences,
        'favorites': favorites,
        'recents': recents,
        'watchedEpisodes': watchedEpisodes,
        'playback': playback,
      };

  factory ProfileDataSnapshot.fromPayload(
    Map<String, dynamic> payload, {
    required String expectedProfileId,
    required int revision,
  }) {
    if (payload['schemaVersion'] != EncryptedProfileSnapshotStore._schemaVersion ||
        payload['profileId'] != expectedProfileId) {
      throw const FormatException('Version ou identité du profil invalide.');
    }

    Map<String, dynamic> mapField(Object? value) {
      if (value is! Map) {
        throw const FormatException('Données du profil invalides.');
      }
      return Map<String, dynamic>.from(value);
    }

    List<Map<String, dynamic>> listField(Object? value) {
      if (value is! List) {
        throw const FormatException('Liste du profil invalide.');
      }
      return value.map(mapField).toList();
    }

    final playback = mapField(payload['playback']);
    return ProfileDataSnapshot(
      profileId: expectedProfileId,
      revision: revision,
      profile: mapField(payload['profile']),
      preferences: mapField(payload['preferences']),
      favorites: listField(payload['favorites']),
      recents: listField(payload['recents']),
      watchedEpisodes: listField(payload['watchedEpisodes']),
      playback: playback.map((key, value) => MapEntry(key, mapField(value))),
    );
  }
}
