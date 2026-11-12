import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  bool get isAnonymous => false;
}

class _Auth extends Fake implements FirebaseAuth {
  User? user = _User('account');
  final changes = StreamController<User?>.broadcast();
  @override
  User? get currentUser => user;
  @override
  Stream<User?> authStateChanges() => changes.stream;
}

class _UnusedDocumentStore implements EncryptedDocumentStore {
  @override
  Future<Map<String, dynamic>?> read(String uid, String documentId) =>
      throw UnimplementedError();
  @override
  Future<void> writeIfRevisionMatches(
    String uid,
    String documentId,
    int expectedRevision,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();
}

class _Sync extends EncryptedScopeSynchronizer {
  _Sync()
      : super(
          remote: EncryptedScopeStore(
            EncryptedCloudStore(store: _UnusedDocumentStore()),
          ),
          baselines: HiveScopeBaselineStore(),
        );
  final scopes = <String>[];
  Completer<void>? gate;
  final started = Completer<void>();

  @override
  Future<bool> synchronize({
    required String uid,
    required String profileId,
    required String scope,
    required String passphrase,
    required LocalSyncScope local,
    required void Function() checkSession,
    ScopeConflictChoice? conflictChoice,
  }) async {
    scopes.add(scope);
    if (!started.isCompleted) started.complete();
    if (gate != null) await gate!.future;
    checkSession();
    return false;
  }
}

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_cloud_notifier_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(SubscriptionAdapter().typeId)) {
      Hive.registerAdapter(SubscriptionAdapter());
      Hive.registerAdapter(SubscriptionTypeAdapter());
      Hive.registerAdapter(TestResultStatusAdapter());
    }
    SharedPreferences.setMockInitialValues({});
    for (final name in [
      'favorites',
      'recently_watched',
      'watched_episodes',
      'settings',
      'profiles',
      'subscriptions',
    ]) {
      await Hive.openBox(name);
    }
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  UserProfile profile(String id) => UserProfile(
        id: id,
        firstName: 'Alex',
        dateOfBirth: DateTime.utc(1990),
        gender: '',
        favoriteGenres: const [],
      );

  test('unlocks only published profile and locks when profile changes',
      () async {
    final sync = _Sync();
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    final notifier = container.read(encryptedActivitySyncProvider.notifier);
    await expectLater(
      notifier.unlock(
        auth: auth,
        uid: 'account',
        phrase: 'phrase',
        catalog: ProfileCatalogSnapshot(revision: 1, profiles: {}),
      ),
      throwsStateError,
    );
    await notifier.unlock(
      auth: auth,
      uid: 'account',
      phrase: 'phrase',
      catalog: ProfileCatalogSnapshot(
        revision: 1,
        profiles: {
          'p1': {'id': 'p1', 'firstName': 'Alex'}
        },
      ),
    );
    expect(sync.scopes.toSet(), {
      'favorites',
      'recents',
      'watched',
      'playback',
      'preferences',
      'profile',
      'subscriptions',
    });
    expect(container.read(encryptedActivitySyncProvider).unlocked, isTrue);
    container
        .read(currentProfileProvider.notifier)
        .setUserProfile(profile('p2'));
    expect(container.read(encryptedActivitySyncProvider).unlocked, isFalse);
  });

  test('account changes cancel an in-flight session', () async {
    final sync = _Sync()..gate = Completer<void>();
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    final operation =
        container.read(encryptedActivitySyncProvider.notifier).unlock(
              auth: auth,
              uid: 'account',
              phrase: 'phrase',
              catalog: ProfileCatalogSnapshot(
                revision: 1,
                profiles: {
                  'p1': {'id': 'p1', 'firstName': 'Alex'}
                },
              ),
            );
    await sync.started.future;
    auth.user = _User('different');
    auth.changes.add(auth.user);
    await Future<void>.delayed(Duration.zero);
    sync.gate!.complete();
    await operation;
    expect(container.read(encryptedActivitySyncProvider).unlocked, isFalse);
    expect(sync.scopes, hasLength(1));
  });
}
