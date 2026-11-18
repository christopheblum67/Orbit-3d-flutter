import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';

class _MemoryStore
    implements EncryptedDocumentStore, EncryptedCloudMaintenance {
  final documents = <String, Map<String, dynamic>>{};
  int writes = 0;
  void Function()? afterRead;

  @override
  Future<Map<String, dynamic>?> read(String uid, String documentId) async {
    final result = documents['$uid/$documentId'];
    afterRead?.call();
    return result;
  }

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
    writes++;
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

UserProfile _profile(String id, {ProfileType type = ProfileType.child}) =>
    UserProfile(
      id: id,
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(2015),
      gender: '',
      favoriteGenres: const [],
      profileType: type,
      pinHash: 'private-pin-hash',
      settings: const {'playlist': 'https://private.example/secret'},
    );

void main() {
  test('rejects changed profiles before a grouped publication', () async {
    final store = _MemoryStore();
    final recovery = CloudProfileRecovery(
      catalog: EncryptedProfileCatalog(EncryptedCloudStore(store: store)),
      currentUid: () => 'account',
      addLocalProfile: (_, __) async {},
    );
    await expectLater(
      recovery.publishMissing('account', '123456', [_profile('one')],
          checkProfiles: () => throw StateError('changed')),
      throwsStateError,
    );
    expect(store.writes, 0);
  });

  test(
      'publishes selected missing profiles atomically without replacing others',
      () async {
    final store = _MemoryStore();
    final recovery = CloudProfileRecovery(
      catalog: EncryptedProfileCatalog(EncryptedCloudStore(store: store)),
      currentUid: () => 'account',
      addLocalProfile: (_, __) async {},
    );
    const secret = '1234567890';
    await recovery.publish('account', secret, _profile('existing'));
    final before =
        (await recovery.load('account', secret)).profiles['existing'];
    final result = await recovery.publishMissing('account', secret, [
      _profile('existing', type: ProfileType.adult),
      _profile('one'),
      _profile('two'),
    ]);
    expect(store.writes, 2);
    expect(result.profiles.keys, containsAll(['existing', 'one', 'two']));
    expect(result.profiles['existing'], before);
    expect((await recovery.load('account', secret)).profiles, result.profiles);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
      'encrypted manual backup and explicit recovery preserve local identities',
      () async {
    final store = _MemoryStore();
    final catalog = EncryptedProfileCatalog(EncryptedCloudStore(store: store));
    var uid = 'account-a';
    final local = <String, UserProfile>{'local': _profile('local')};
    final recovery = CloudProfileRecovery(
      catalog: catalog,
      currentUid: () => uid,
      addLocalProfile: (profile, check) async {
        check();
        if (local.containsKey(profile.id)) throw StateError('exists');
        local[profile.id] = profile;
      },
    );
    const phrase = 'independent private phrase';
    await recovery.publish(uid, phrase, _profile('cloud'));
    final raw = jsonEncode(store.documents);
    expect(raw, isNot(contains('Alex')));
    expect(raw, isNot(contains('private-pin-hash')));
    expect(raw, isNot(contains('private.example')));
    final snapshot = await recovery.load(uid, phrase);
    expect(snapshot.profiles.keys, ['cloud']);
    expect(local.keys, ['local']);
    await recovery.restore(uid, phrase, 'cloud');
    expect(local.keys, containsAll(['local', 'cloud']));
    expect(local['cloud']!.profileType, ProfileType.child);
    expect(local['cloud']!.pinHash, 'private-pin-hash');
    await expectLater(recovery.restore(uid, phrase, 'cloud'), throwsStateError);
    await expectLater(
        recovery.load(uid, 'wrong phrase'), throwsA(isA<Exception>()));
    uid = 'account-b';
    expect((await recovery.load(uid, phrase)).profiles, isEmpty);
    expect(local.keys, containsAll(['local', 'cloud']));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('account changes during read prevent local restoration', () async {
    final store = _MemoryStore();
    final catalog = EncryptedProfileCatalog(EncryptedCloudStore(store: store));
    var uid = 'account-a';
    var restored = false;
    final recovery = CloudProfileRecovery(
      catalog: catalog,
      currentUid: () => uid,
      addLocalProfile: (_, check) async {
        check();
        restored = true;
      },
    );
    await recovery.publish(uid, 'secret', _profile('cloud'));
    store.afterRead = () => uid = 'account-b';
    await expectLater(
      recovery.restore('account-a', 'secret', 'cloud'),
      throwsStateError,
    );
    expect(restored, isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('recovers the latest encrypted profile rather than the old catalog',
      () async {
    final memory = _MemoryStore();
    final encrypted = EncryptedCloudStore(store: memory);
    final scopes = EncryptedScopeStore(encrypted);
    UserProfile? restored;
    final recovery = CloudProfileRecovery(
      catalog: EncryptedProfileCatalog(encrypted),
      profileScopes: scopes,
      currentUid: () => 'account',
      addLocalProfile: (profile, check) async {
        check();
        restored = profile;
      },
    );
    const phrase = 'independent private phrase';
    await recovery.publish(
        'account', phrase, _profile('p1', type: ProfileType.adult));
    await scopes.write(
      uid: 'account',
      profileId: 'p1',
      scope: 'profile',
      passphrase: phrase,
      snapshot: EncryptedScopeSnapshot(
        revision: 0,
        entries: {'p1': jsonEncode(_profile('p1').toMap())},
      ),
    );
    await recovery.restore('account', phrase, 'p1');
    expect(restored!.profileType, ProfileType.child);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('account changes during catalog load prevent a backup', () async {
    final store = _MemoryStore();
    final catalog = EncryptedProfileCatalog(EncryptedCloudStore(store: store));
    var uid = 'account-a';
    final recovery = CloudProfileRecovery(
      catalog: catalog,
      currentUid: () => uid,
      addLocalProfile: (_, __) async {},
    );
    store.afterRead = () => uid = 'account-b';
    await expectLater(
      recovery.publish('account-a', 'secret', _profile('cloud')),
      throwsStateError,
    );
    expect(store.documents, isEmpty);
  });

  test('invalid child profile cannot fall back to an adult identity', () {
    final data = _profile('child').toMap()..remove('profileType');
    expect(() => validateCloudProfile(data, 'child'), throwsFormatException);
    expect(
      () => validateCloudProfile(_profile('other').toMap(), 'child'),
      throwsFormatException,
    );
  });

  test('Hive recovery never replaces an existing profile key', () async {
    final directory = Directory(
      'build\\profile_recovery_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    await directory.create(recursive: true);
    Hive.init(directory.path);
    try {
      final box = await Hive.openBox<dynamic>('profiles');
      await box.put('same', {'unreadable': 'preserve'});
      await expectLater(
        addRecoveredLocalProfile(_profile('same'), () {}),
        throwsStateError,
      );
      expect(box.get('same'), {'unreadable': 'preserve'});
      await addRecoveredLocalProfile(_profile('new'), () {});
      expect((box.get('new') as Map)['profileType'], 'child');
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('deletes only the selected cloud profile and its activity', () async {
    final backing = _MemoryStore();
    final encrypted = EncryptedCloudStore(store: backing);
    final recovery = CloudProfileRecovery(
      catalog: EncryptedProfileCatalog(encrypted),
      profileScopes: EncryptedScopeStore(encrypted),
      currentUid: () => 'account',
      addLocalProfile: (_, __) async {},
    );
    const phrase = '123456';
    await recovery.publish('account', phrase, _profile('one'));
    await recovery.publish('account', phrase, _profile('two'));
    final scopes = EncryptedScopeStore(encrypted);
    for (final id in ['one', 'two']) {
      await scopes.write(
        uid: 'account',
        profileId: id,
        scope: 'favorites',
        passphrase: phrase,
        snapshot: EncryptedScopeSnapshot(
          revision: 0,
          entries: {'movie': 'favorite'},
        ),
      );
    }

    await recovery.deleteCloudProfile('account', phrase, 'one');

    expect((await recovery.load('account', phrase)).profiles.keys, ['two']);
    expect(
      await scopes.read(
        uid: 'account',
        profileId: 'one',
        scope: 'favorites',
        passphrase: phrase,
      ),
      isNull,
    );
    expect(
      (await scopes.read(
        uid: 'account',
        profileId: 'two',
        scope: 'favorites',
        passphrase: phrase,
      ))
          ?.entries,
      {'movie': 'favorite'},
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('cloud reset invalidates the old code and retains an empty catalog',
      () async {
    final backing = _MemoryStore();
    final encrypted = EncryptedCloudStore(store: backing);
    final recovery = CloudProfileRecovery(
      catalog: EncryptedProfileCatalog(encrypted),
      currentUid: () => 'account',
      addLocalProfile: (_, __) async {},
    );
    await recovery.publish('account', 'old-code', _profile('one'));

    await recovery.resetCloud('account', 'new-code');

    final empty = await recovery.load('account', 'new-code');
    expect(empty.profiles, isEmpty);
    expect(empty.verified, isTrue);
    await expectLater(
      recovery.load('account', 'old-code'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    expect(backing.documents.keys, {'account/__control__'});
  }, timeout: const Timeout(Duration(minutes: 2)));
}
