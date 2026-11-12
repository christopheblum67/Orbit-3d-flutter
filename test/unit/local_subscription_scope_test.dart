import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_subscription_scope.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/subscription_cloud_record.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _FailOnceStore implements SecretStore {
  _FailOnceStore(this.delegate, this.failKey);
  final SecretStore delegate;
  final String failKey;
  bool failed = false;

  @override
  Future<String?> read(String key) => delegate.read(key);

  @override
  Future<void> write(String key, String value) {
    if (key == failKey && !failed) {
      failed = true;
      throw StateError('Keystore unavailable');
    }
    return delegate.write(key, value);
  }

  @override
  Future<void> delete(String key) => delegate.delete(key);
}

void main() {
  late Directory dir;
  late StorageService storage;

  Subscription sub(String id, {String password = 'old', bool active = false}) =>
      Subscription(
        id: id,
        name: id,
        type: SubscriptionType.xtream,
        baseUrl: 'https://example.test',
        username: 'user',
        password: password,
        isActive: active,
        createdAt: DateTime.utc(2025),
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_cloud_subscriptions_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(SubscriptionAdapter().typeId)) {
      Hive.registerAdapter(SubscriptionAdapter());
      Hive.registerAdapter(SubscriptionTypeAdapter());
      Hive.registerAdapter(TestResultStatusAdapter());
    }
    overrideSecretStoreForTesting(InMemorySecretStore());
    storage = StorageService();
    await storage.init();
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
    restoreSecretStoreForTesting();
  });

  test('restores secrets securely and preserves the local active selection',
      () async {
    await storage.saveSubscription(sub('active', active: true));
    final scope = LocalSubscriptionScope(storage);
    final before = await scope.read();
    final merged = {
      'active': SubscriptionCloudRecord.fromSubscription(
        sub('active', password: 'new'),
        'new',
      ).encode(),
      'other': SubscriptionCloudRecord.fromSubscription(
        sub('other', password: 'private'),
        'private',
      ).encode(),
    };
    await scope.applyIfUnchanged(before, merged, () {});
    final box = Hive.box('subscriptions');
    expect((box.get('active') as Subscription).isActive, isTrue);
    expect((box.get('other') as Subscription).isActive, isFalse);
    expect((box.get('other') as Subscription).password, isEmpty);
    expect(
        await secretStore.read(subscriptionPasswordSecretKey('active')), 'new');
    expect(await secretStore.read(subscriptionPasswordSecretKey('other')),
        'private');
    expect(await scope.read(), merged);
    await expectLater(
        scope.applyIfUnchanged(before, {}, () {}), throwsStateError);
    await expectLater(
      scope.applyIfUnchanged(merged, {'other': merged['other']!}, () {}),
      throwsA(isA<ActiveSubscriptionSyncRemoval>()),
    );
    expect(box.containsKey('active'), isTrue);
  });

  test('rolls back a partially applied change after interruption', () async {
    await storage.saveSubscription(sub('a', password: 'old'));
    final box = Hive.box('subscriptions');
    final previous = (box.get('a') as Subscription).toMap();
    await Hive.box('settings')
        .put('cloud_subscription_journal_pending_v1', true);
    await secretStore.write(
      'cloud_subscription_journal_v1',
      jsonEncode({
        'version': 1,
        'id': 'a',
        'subscription': previous,
        'secret': 'old',
      }),
    );
    await secretStore.write(subscriptionPasswordSecretKey('a'), 'new');
    await box.put('a', sub('a', password: '').copyWith(name: 'changed'));
    await storage.init();
    expect((box.get('a') as Subscription).name, 'a');
    expect(await secretStore.read(subscriptionPasswordSecretKey('a')), 'old');
    expect(await secretStore.read('cloud_subscription_journal_v1'), isNull);
    expect(Hive.box('settings').get('cloud_subscription_journal_pending_v1'),
        isNull);
  });

  test('rolls back when a secure write fails or the account changes', () async {
    await storage.saveSubscription(sub('a', password: 'old'));
    final scope = LocalSubscriptionScope(storage);
    final before = await scope.read();
    final merged = {
      'a': SubscriptionCloudRecord.fromSubscription(
        sub('a', password: 'new'),
        'new',
      ).encode(),
    };
    final original = secretStore;
    overrideSecretStoreForTesting(
      _FailOnceStore(original, subscriptionPasswordSecretKey('a')),
    );
    await expectLater(
      scope.applyIfUnchanged(before, merged, () {}),
      throwsStateError,
    );
    expect(await secretStore.read(subscriptionPasswordSecretKey('a')), 'old');
    expect(await secretStore.read('cloud_subscription_journal_v1'), isNull);
    overrideSecretStoreForTesting(original);

    var checks = 0;
    await expectLater(
      scope.applyIfUnchanged(before, merged, () {
        if (++checks == 7) throw StateError('account changed');
      }),
      throwsStateError,
    );
    expect(await secretStore.read(subscriptionPasswordSecretKey('a')), 'old');
    expect(await scope.read(), before);
    expect(Hive.box('settings').values.join(), isNot(contains('old')));
  });

  test('refuses incomplete subscription records and recovery journals',
      () async {
    await storage.saveSubscription(sub('a'));
    final scope = LocalSubscriptionScope(storage);
    final before = await scope.read();
    final incomplete = Map<String, dynamic>.from(
      jsonDecode(before['a']!) as Map,
    )..remove('password');
    expect(() => scope.validate({'a': jsonEncode(incomplete)}),
        throwsFormatException);

    await Hive.box('settings')
        .put('cloud_subscription_journal_pending_v1', true);
    await secretStore.write(
      'cloud_subscription_journal_v1',
      jsonEncode({'version': 1, 'id': 'a'}),
    );
    await expectLater(scope.read(), throwsFormatException);
    expect(Hive.box('subscriptions').containsKey('a'), isTrue);
    expect(await secretStore.read(subscriptionPasswordSecretKey('a')), 'old');
  });
}
