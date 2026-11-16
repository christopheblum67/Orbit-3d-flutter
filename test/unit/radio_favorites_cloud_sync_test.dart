import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_radio_favorites_scope.dart';
import 'package:orbit_3d_flutter/services/radio_favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Documents implements EncryptedDocumentStore {
  final documents = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String uid, String documentId) async =>
      documents['$uid/$documentId'];

  @override
  Future<void> writeIfRevisionMatches(String uid, String documentId,
      int expectedRevision, Map<String, dynamic> data) async {
    final key = '$uid/$documentId';
    if ((documents[key]?['revision'] ?? 0) != expectedRevision) {
      throw const CloudSyncConflict();
    }
    documents[key] = data;
  }
}

class _Baselines implements ScopeBaselineStore {
  ScopeBaseline? baseline;

  @override
  Future<ScopeBaseline?> read(
          String uid, String profileId, String scope) async =>
      baseline;

  @override
  Future<void> write(String uid, String profileId, String scope,
      Map<String, String> entries) async {
    baseline = ScopeBaseline.fromEntries(entries, List.filled(32, 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('synchronizes and deletes radio favorites between two devices',
      () async {
    final documents = _Documents();
    final remote = EncryptedScopeStore(EncryptedCloudStore(store: documents));
    final first =
        EncryptedScopeSynchronizer(remote: remote, baselines: _Baselines());
    final second =
        EncryptedScopeSynchronizer(remote: remote, baselines: _Baselines());
    final local = LocalRadioFavoritesScope('profile');

    Future<void> sync(EncryptedScopeSynchronizer synchronizer) async {
      await synchronizer.synchronize(
        uid: 'account',
        profileId: 'profile',
        scope: 'radioFavorites',
        passphrase: 'phrase secrète suffisamment longue',
        local: local,
        checkSession: () {},
      );
    }

    await RadioFavoritesStore.toggle('profile', 'Private station');
    await RadioFavoritesStore.toggle('other', 'Other station');
    await sync(first);
    expect(jsonEncode(documents.documents), isNot(contains('Private station')));
    SharedPreferences.setMockInitialValues({});
    await sync(second);
    expect(await RadioFavoritesStore.read('profile'), {'Private station'});
    expect(await RadioFavoritesStore.read('other'), isEmpty);
    await RadioFavoritesStore.toggle('profile', 'Private station');
    await sync(second);
    SharedPreferences.setMockInitialValues({
      'radio_favorites_profile': ['Private station'],
      'radio_favorites_other': ['Other station'],
    });
    await sync(first);
    expect(await RadioFavoritesStore.read('profile'), isEmpty);
    expect(await RadioFavoritesStore.read('other'), {'Other station'});
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('serializes concurrent toggles and rejects stale cloud snapshots',
      () async {
    await Future.wait([
      RadioFavoritesStore.toggle('profile', 'A'),
      RadioFavoritesStore.toggle('profile', 'B'),
    ]);
    final local = LocalRadioFavoritesScope('profile');
    expect(await local.read(), {'A': '1', 'B': '1'});
    await expectLater(
      local.applyIfUnchanged({'A': '1'}, {'C': '1'}, () {}),
      throwsStateError,
    );
    expect(await local.read(), {'A': '1', 'B': '1'});
    expect(() => local.validate({'C': 'invalid'}), throwsFormatException);
  });

  test('restores local favorites if the session changes during a write',
      () async {
    final local = LocalRadioFavoritesScope('profile');
    await RadioFavoritesStore.toggle('profile', 'A');
    var checks = 0;
    await expectLater(
      local.applyIfUnchanged({'A': '1'}, {'B': '1'}, () {
        if (++checks == 2) throw StateError('session changed');
      }),
      throwsStateError,
    );
    expect(await local.read(), {'A': '1'});
  });
}
