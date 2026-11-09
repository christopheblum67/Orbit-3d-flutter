import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';

class _MemoryStore implements EncryptedDocumentStore {
  final documents = <String, Map<String, dynamic>>{};
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
    documents[key] = data;
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
}
