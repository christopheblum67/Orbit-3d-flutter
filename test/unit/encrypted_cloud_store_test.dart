import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';

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
    final existing = documents[key];
    if ((existing?['revision'] ?? 0) != expectedRevision) {
      throw const CloudSyncConflict();
    }
    documents[key] = data;
  }
}

void main() {
  test('encrypts content and rejects stale writes and wrong passwords',
      () async {
    final backing = _MemoryStore();
    final store = EncryptedCloudStore(store: backing);
    const passphrase = 'une phrase secrete pour mes appareils';
    final revision = await store.write(
      uid: 'user-a',
      documentId: 'profile-a',
      passphrase: passphrase,
      payload: {'url': 'https://example.test/secret?password=private'},
      expectedRevision: 0,
    );
    expect(revision, 1);
    expect(jsonEncode(backing.documents), isNot(contains('password')));
    final restored = await store.read(
      uid: 'user-a',
      documentId: 'profile-a',
      passphrase: passphrase,
    );
    expect(restored!.revision, 1);
    expect(restored.payload['url'],
        'https://example.test/secret?password=private');
    await expectLater(
      store.write(
        uid: 'user-a',
        documentId: 'profile-a',
        passphrase: passphrase,
        payload: {'name': 'stale'},
        expectedRevision: 0,
      ),
      throwsA(isA<CloudSyncConflict>()),
    );
    await expectLater(
      store.read(
        uid: 'user-a',
        documentId: 'profile-a',
        passphrase: 'phrase incorrecte',
      ),
      throwsA(isA<Exception>()),
    );
    final document = backing.documents['user-a/profile-a']!;
    document['revision'] = 2;
    await expectLater(
      store.read(
        uid: 'user-a',
        documentId: 'profile-a',
        passphrase: passphrase,
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      await store.read(
          uid: 'user-b', documentId: 'profile-a', passphrase: passphrase),
      isNull,
    );
  });
}
