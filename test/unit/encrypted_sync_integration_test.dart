import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_profile_activity_scope.dart';

class _Documents implements EncryptedDocumentStore {
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

class _Baselines implements ScopeBaselineStore {
  _Baselines(this.seed);
  final int seed;
  ScopeBaseline? value;

  @override
  Future<ScopeBaseline?> read(
          String uid, String profileId, String scope) async =>
      value;

  @override
  Future<void> write(
    String uid,
    String profileId,
    String scope,
    Map<String, String> entries,
  ) async {
    value = ScopeBaseline.fromEntries(entries, List.filled(32, seed));
  }
}

void main() {
  test('two devices exchange encrypted favorites and propagate a deletion',
      () async {
    final dir = await Directory.systemTemp.createTemp('orbit_cloud_e2e_');
    Hive.init(dir.path);
    final box = await Hive.openBox('favorites');
    try {
      final documents = _Documents();
      final remote = EncryptedScopeStore(EncryptedCloudStore(store: documents));
      final deviceA =
          EncryptedScopeSynchronizer(remote: remote, baselines: _Baselines(1));
      final deviceB =
          EncryptedScopeSynchronizer(remote: remote, baselines: _Baselines(2));
      final local =
          LocalProfileActivityScope('p1', ProfileActivityKind.favorites);
      Future<void> sync(EncryptedScopeSynchronizer device) async {
        await device.synchronize(
          uid: 'user',
          profileId: 'p1',
          scope: 'favorites',
          passphrase: 'phrase secrète suffisamment longue',
          local: local,
          checkSession: () {},
        );
      }

      String favorite(String id) => jsonEncode(FavoriteEntry(
            id: id,
            title: id,
            profileId: 'p1',
            type: ContentType.live,
            streamUrl: 'https://example.test/private',
          ).toJson());

      await box.put('p1:live:one', favorite('one'));
      await sync(deviceA);
      expect(jsonEncode(documents.documents), isNot(contains('example.test')));

      await box.clear();
      await sync(deviceB);
      expect(box.containsKey('p1:live:one'), isTrue);
      await box.delete('p1:live:one');
      await box.put('p1:live:two', favorite('two'));
      await sync(deviceB);

      await box.clear();
      await box.put('p1:live:one', favorite('one'));
      await sync(deviceA);
      expect(box.containsKey('p1:live:one'), isFalse);
      expect(box.get('p1:live:two'), favorite('two'));
    } finally {
      await Hive.close();
      await dir.delete(recursive: true);
    }
  });
}
