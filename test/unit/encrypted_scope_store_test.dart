import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';

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
  test('encrypted scopes isolate accounts and reject concurrent writes',
      () async {
    final memory = _MemoryStore();
    final store = EncryptedScopeStore(EncryptedCloudStore(store: memory));
    const secret = 'une phrase privée différente du compte';
    final initial = EncryptedScopeSnapshot(
      revision: 0,
      entries: {'movie': 'https://example.test/secret?password=private'},
    );
    expect(
      await store.write(
        uid: 'user-a',
        profileId: 'profile-a',
        scope: 'favorites',
        passphrase: secret,
        snapshot: initial,
      ),
      1,
    );
    expect(jsonEncode(memory.documents), isNot(contains('password')));
    final loaded = await store.read(
      uid: 'user-a',
      profileId: 'profile-a',
      scope: 'favorites',
      passphrase: secret,
    );
    expect(loaded!.revision, 1);
    expect(loaded.entries, initial.entries);
    expect(
      await store.read(
        uid: 'user-b',
        profileId: 'profile-a',
        scope: 'favorites',
        passphrase: secret,
      ),
      isNull,
    );
    await expectLater(
      store.write(
        uid: 'user-a',
        profileId: 'profile-a',
        scope: 'favorites',
        passphrase: secret,
        snapshot: initial,
      ),
      throwsA(isA<CloudSyncConflict>()),
    );
    await expectLater(
      store.read(
        uid: 'user-a',
        profileId: 'profile-a',
        scope: 'favorites',
        passphrase: 'phrase incorrecte',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects invalid decrypted scope contents', () async {
    final memory = _MemoryStore();
    final encrypted = EncryptedCloudStore(store: memory);
    final store = EncryptedScopeStore(encrypted);
    final encodedId = base64Url
        .encode(utf8.encode(jsonEncode(['p1', 'favorites'])))
        .replaceAll('=', '');
    await encrypted.write(
      uid: 'user-a',
      documentId: 'scope_$encodedId',
      passphrase: 'phrase secrète',
      expectedRevision: 0,
      payload: {
        'schemaVersion': 1,
        'profileId': 'p1',
        'scope': 'favorites',
        'entries': {'bad': 123},
      },
    );
    await expectLater(
      store.read(
        uid: 'user-a',
        profileId: 'p1',
        scope: 'favorites',
        passphrase: 'phrase secrète',
      ),
      throwsFormatException,
    );
  });

  test('merges independent changes and propagates deletions', () {
    expect(
      mergeScopeEntries(
        baseline: {'a': 'old', 'b': 'old', 'c': 'old'},
        local: {'a': 'new', 'b': 'old'},
        remote: {'a': 'old', 'b': 'new', 'c': 'old', 'd': 'new'},
      ),
      {'a': 'new', 'b': 'new', 'd': 'new'},
    );
    expect(
      mergeScopeEntries(local: {'a': '1'}, remote: {'b': '2'}),
      {'a': '1', 'b': '2'},
    );
  });

  test('rejects concurrent edits, including deletion versus update', () {
    expect(
      () => mergeScopeEntries(
        baseline: {'a': 'old'},
        local: {},
        remote: {'a': 'new'},
      ),
      throwsA(isA<ScopeMergeConflict>().having((e) => e.keys, 'keys', {'a'})),
    );
    expect(
      () => mergeScopeEntries(local: {'a': '1'}, remote: {'a': '2'}),
      throwsA(isA<ScopeMergeConflict>()),
    );
  });
}
