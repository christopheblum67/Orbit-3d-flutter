import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';

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
  test('preserves same-name profiles and rejects concurrent changes', () async {
    final backing = _MemoryStore();
    final catalog =
        EncryptedProfileCatalog(EncryptedCloudStore(store: backing));
    const secret = 'une phrase secrete pour mes appareils';
    final initial = await catalog.load(uid: 'account', passphrase: secret);
    expect(initial.profiles, isEmpty);
    final snapshot = ProfileCatalogSnapshot(
      revision: initial.revision,
      profiles: {
        'one': {'id': 'one', 'firstName': 'Alex'},
        'two': {'id': 'two', 'firstName': 'Alex'},
      },
    );
    expect(
        await catalog.save(
            uid: 'account', passphrase: secret, snapshot: snapshot),
        1);
    expect(jsonEncode(backing.documents), isNot(contains('Alex')));
    final loaded = await catalog.load(uid: 'account', passphrase: secret);
    expect(loaded.profiles.keys, containsAll(['one', 'two']));
    await expectLater(
      catalog.save(uid: 'account', passphrase: secret, snapshot: snapshot),
      throwsA(isA<CloudSyncConflict>()),
    );
    await expectLater(
      catalog.load(uid: 'account', passphrase: 'phrase incorrecte'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      catalog.publishNewProfile(
        uid: 'account',
        passphrase: secret,
        profile: {'id': 'one', 'firstName': 'Remplacement'},
      ),
      throwsStateError,
    );
    expect(backing.documents['account/profiles']!['revision'], 1);
  });
}
