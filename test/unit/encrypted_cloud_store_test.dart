import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';

class _MemoryStore
    implements EncryptedDocumentStore, EncryptedCloudMaintenance {
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

  @override
  Future<void> deleteDocument(String uid, String documentId) async {
    documents.remove('$uid/$documentId');
  }

  @override
  Future<int> deleteAllData(String uid) async {
    final keys = documents.keys
        .where((key) => key.startsWith('$uid/') && key != '$uid/__control__')
        .toList();
    for (final key in keys) {
      documents.remove(key);
    }
    return keys.length;
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

  test('reset rotates the code and makes old encrypted documents unreadable',
      () async {
    final backing = _MemoryStore();
    final store = EncryptedCloudStore(store: backing);
    await store.write(
      uid: 'user-a',
      documentId: 'profile-a',
      passphrase: 'old-code',
      payload: {'name': 'old profile'},
      expectedRevision: 0,
    );

    await store.advanceGeneration(
      uid: 'user-a',
      passphrase: 'new-code',
      reset: true,
    );
    await store.deleteAllData('user-a');

    expect(
      await store.read(
        uid: 'user-a',
        documentId: 'profile-a',
        passphrase: 'new-code',
      ),
      isNull,
    );
    await expectLater(
      store.read(
        uid: 'user-a',
        documentId: 'profile-a',
        passphrase: 'old-code',
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    expect(backing.documents.keys, {'user-a/__control__'});
  });
}
