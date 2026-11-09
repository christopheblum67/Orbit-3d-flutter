import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_snapshot.dart';

class _MemoryStore implements EncryptedDocumentStore {
  final documents = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String uid, String documentId) async =>
      documents['$uid/$documentId'];

  @override
  Future<void> writeIfRevisionMatches(
    String uid,
    String documentId,
    int expectedRevision,
    Map<String, dynamic> data,
  ) async {
    final key = '$uid/$documentId';
    if ((documents[key]?['revision'] ?? 0) != expectedRevision) {
      throw const CloudSyncConflict();
    }
    documents[key] = data;
  }
}

void main() {
  ProfileDataSnapshot snapshot({int revision = 0}) => ProfileDataSnapshot(
        profileId: 'p1',
        revision: revision,
        profile: {'id': 'p1', 'firstName': 'Alex'},
        preferences: {'language': 'fr'},
        favorites: [
          {'profileId': 'p1', 'streamUrl': 'https://example.test/secret'},
        ],
        recents: [],
        watchedEpisodes: [],
        playback: {
          'movie-1': {'positionMs': 123, 'durationMs': 456, 'updatedAt': 1},
        },
      );

  test('round trips private profile data and rejects stale changes', () async {
    final memory = _MemoryStore();
    final store = EncryptedProfileSnapshotStore(EncryptedCloudStore(store: memory));
    const secret = 'phrase indépendante de synchronisation';
    expect(await store.read(uid: 'u1', profileId: 'p1', passphrase: secret), isNull);
    expect(await store.write(uid: 'u1', passphrase: secret, snapshot: snapshot()), 1);
    expect(jsonEncode(memory.documents), isNot(contains('example.test')));
    final restored = await store.read(uid: 'u1', profileId: 'p1', passphrase: secret);
    expect(restored!.revision, 1);
    expect(restored.favorites.single['streamUrl'], 'https://example.test/secret');
    expect(restored.playback['movie-1']!['positionMs'], 123);
    await expectLater(
      store.write(uid: 'u1', passphrase: secret, snapshot: snapshot()),
      throwsA(isA<CloudSyncConflict>()),
    );
    expect(await store.read(uid: 'u2', profileId: 'p1', passphrase: secret), isNull);
  });

  test('rejects mismatched profile identities', () {
    expect(
      () => ProfileDataSnapshot(
        profileId: 'p1',
        revision: 0,
        profile: {'id': 'p1', 'firstName': 'Alex'},
        preferences: {},
        favorites: [
          {'profileId': 'p2'},
        ],
        recents: [],
        watchedEpisodes: [],
        playback: {},
      ),
      throwsFormatException,
    );
    expect(
      () => ProfileDataSnapshot.fromPayload(
        snapshot().toPayload(),
        expectedProfileId: 'p2',
        revision: 1,
      ),
      throwsFormatException,
    );
  });
}
