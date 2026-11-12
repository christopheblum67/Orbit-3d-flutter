import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

void main() {
  test('uses a protected key, isolates accounts, and fails if the key is lost',
      () async {
    final dir = await Directory.systemTemp.createTemp('orbit_cloud_baseline_');
    Hive.init(dir.path);
    final settings = await Hive.openBox('settings');
    final secrets = InMemorySecretStore();
    overrideSecretStoreForTesting(secrets);
    try {
      final store = HiveScopeBaselineStore();
      await store.write('user-a', 'p1', 'subscriptions', {'id': 'password'});
      final serialized = settings.values.join();
      expect(serialized, isNot(contains('password')));
      expect(serialized,
          isNot(contains(sha256.convert('password'.codeUnits).toString())));
      expect(await store.read('user-b', 'p1', 'subscriptions'), isNull);
      expect(await store.read('user-a', 'p1', 'subscriptions'), isNotNull);
      secrets.clearAll();
      await expectLater(
        store.read('user-a', 'p1', 'subscriptions'),
        throwsStateError,
      );
      await expectLater(
        store.write('user-a', 'p1', 'subscriptions', {'id': 'password'}),
        throwsStateError,
      );
    } finally {
      await Hive.close();
      await dir.delete(recursive: true);
      restoreSecretStoreForTesting();
    }
  });
}
