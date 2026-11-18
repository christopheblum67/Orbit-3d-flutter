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

class _NoCloudChanges implements EncryptedCloudChangeSource {
  @override
  Stream<String> watch(String uid) => Stream<String>.multi((_) {});
}

class _CloudChanges implements EncryptedCloudChangeSource {
  final controller = StreamController<String>.broadcast(sync: true);
  @override
  Stream<String> watch(String uid) => controller.stream;
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
  final calls = <(String, String, ScopeConflictChoice?)>[];
  (String, String)? conflict;
  (String, String)? revisionConflict;
  int revisionFailures = 0;
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
    calls.add((profileId, scope, conflictChoice));
    if (!started.isCompleted) started.complete();
    if (gate != null) await gate!.future;
    checkSession();
    if (revisionConflict == (profileId, scope) && revisionFailures > 0) {
      revisionFailures--;
      throw const CloudSyncConflict();
    }
    if (conflict == (profileId, scope) && conflictChoice == null) {
      throw ScopeMergeConflict({'conflict'});
    }
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
    await Hive.box('profiles').putAll({'p1': {}, 'p2': {}});
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
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
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
      'radioFavorites',
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
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
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
    final running = container.read(encryptedActivitySyncProvider);
    expect(running.busy, isTrue);
    expect(running.currentScope, 'favorites');
    expect(running.currentProfileId, 'p1');
    expect(running.completedScopes, 0);
    expect(running.totalScopes, 8);
    auth.user = _User('different');
    auth.changes.add(auth.user);
    await Future<void>.delayed(Duration.zero);
    sync.gate!.complete();
    await operation;
    expect(container.read(encryptedActivitySyncProvider).unlocked, isFalse);
    expect(sync.scopes, hasLength(1));
  });

  test('removing a selected profile stops its in-flight synchronization',
      () async {
    final sync = _Sync()..gate = Completer<void>();
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
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
      catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
        'p1': {'id': 'p1', 'firstName': 'Alex'},
      }),
      profileIds: {'p1'},
    );
    await sync.started.future;
    await Hive.box('profiles').delete('p1');
    sync.gate!.complete();
    await operation;
    expect(container.read(encryptedActivitySyncProvider).error, isNotNull);
    expect(sync.calls, hasLength(1));
  });

  testWidgets('periodic polling does not restart a slow sync', (tester) async {
    final sync = _Sync()..gate = Completer<void>();
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
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
    await tester.pump();
    expect(sync.scopes, ['favorites']);
    await tester.pump(const Duration(minutes: 5));
    sync.gate!.complete();
    await tester.pump();
    await operation;
    expect(sync.scopes, hasLength(8));
    expect(container.read(encryptedActivitySyncProvider).busy, isFalse);
    expect(container.read(encryptedActivitySyncProvider).lastSyncAt, isNotNull);
    container.read(encryptedActivitySyncProvider.notifier).lock();
  });

  testWidgets('remote changes synchronize only the selected scope promptly',
      (tester) async {
    final sync = _Sync();
    final auth = _Auth();
    final changes = _CloudChanges();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(changes),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await changes.controller.close();
      await auth.changes.close();
    });
    final notifier = container.read(encryptedActivitySyncProvider.notifier);
    await notifier.unlock(
      auth: auth,
      uid: 'account',
      phrase: 'phrase',
      catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
        'p1': {'id': 'p1', 'firstName': 'Alex'},
      }),
    );
    sync.calls.clear();
    changes.controller.add(EncryptedScopeStore.documentId('p2', 'favorites'));
    await tester.pump(const Duration(seconds: 2));
    expect(sync.calls, isEmpty);
    changes.controller.add(EncryptedScopeStore.documentId('p1', 'favorites'));
    changes.controller.add(EncryptedScopeStore.documentId('p1', 'favorites'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(sync.calls.map((call) => (call.$1, call.$2)), [('p1', 'favorites')]);
    notifier.lock();
    changes.controller.add(EncryptedScopeStore.documentId('p1', 'favorites'));
    await tester.pump(const Duration(seconds: 2));
    expect(sync.calls, hasLength(1));
  });

  test('startup conflict source is applied to the initial synchronization',
      () async {
    final sync = _Sync()..conflict = ('p1', 'favorites');
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });

    await container.read(encryptedActivitySyncProvider.notifier).unlock(
          auth: auth,
          uid: 'account',
          phrase: 'phrase',
          catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
            'p1': {'id': 'p1', 'firstName': 'Alex'},
          }),
          initialConflictChoice: ScopeConflictChoice.cloud,
        );

    expect(sync.calls.first, ('p1', 'favorites', ScopeConflictChoice.cloud));
    expect(
      container.read(encryptedActivitySyncProvider).error,
      isNull,
    );
    expect(container.read(encryptedActivitySyncProvider).unlocked, isTrue);
  });

  test('remote control changes pause the active synchronization session',
      () async {
    final sync = _Sync();
    final auth = _Auth();
    final changes = _CloudChanges();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(changes),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await changes.controller.close();
      await auth.changes.close();
    });
    final notifier = container.read(encryptedActivitySyncProvider.notifier);
    await notifier.unlock(
      auth: auth,
      uid: 'account',
      phrase: 'phrase',
      catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
        'p1': {'id': 'p1', 'firstName': 'Alex'},
      }),
    );

    changes.controller.add(EncryptedCloudStore.controlDocumentId);

    final state = container.read(encryptedActivitySyncProvider);
    expect(state.unlocked, isFalse);
    expect(state.error, contains('Le partage Cloud a changé'));
  });

  testWidgets('remote changes during an active sync are not lost',
      (tester) async {
    final sync = _Sync()..gate = Completer<void>();
    final auth = _Auth();
    final changes = _CloudChanges();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(changes),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await changes.controller.close();
      await auth.changes.close();
    });
    final operation =
        container.read(encryptedActivitySyncProvider.notifier).unlock(
              auth: auth,
              uid: 'account',
              phrase: 'phrase',
              catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
                'p1': {'id': 'p1', 'firstName': 'Alex'},
              }),
            );
    await tester.pump();
    changes.controller.add(EncryptedScopeStore.documentId('p1', 'favorites'));
    await tester.pump(const Duration(seconds: 1));
    sync.gate!.complete();
    await tester.pump();
    await operation;
    expect(sync.calls.where((call) => call.$2 == 'favorites'), hasLength(2));
    container.read(encryptedActivitySyncProvider.notifier).lock();
  });

  testWidgets(
      'listener errors are visible and periodic fallback remains active',
      (tester) async {
    final sync = _Sync();
    final auth = _Auth();
    final changes = _CloudChanges();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(changes),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await changes.controller.close();
      await auth.changes.close();
    });
    final notifier = container.read(encryptedActivitySyncProvider.notifier);
    await notifier.unlock(
      auth: auth,
      uid: 'account',
      phrase: 'phrase',
      catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
        'p1': {'id': 'p1', 'firstName': 'Alex'},
      }),
    );
    sync.calls.clear();
    changes.controller.addError(StateError('network'));
    expect(container.read(encryptedActivitySyncProvider).realtimeError,
        contains('vérification périodique'));
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();
    expect(sync.calls, hasLength(8));
    expect(
        container.read(encryptedActivitySyncProvider).realtimeError, isNotNull);
    notifier.lock();
  });

  test('concurrent cloud revisions are retried', () async {
    final sync = _Sync()
      ..revisionConflict = ('p1', 'favorites')
      ..revisionFailures = 2;
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    await container.read(encryptedActivitySyncProvider.notifier).unlock(
          auth: auth,
          uid: 'account',
          phrase: 'phrase',
          catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
            'p1': {'id': 'p1', 'firstName': 'Alex'},
          }),
        );
    expect(sync.calls.where((call) => call.$2 == 'favorites'), hasLength(3));
    expect(container.read(encryptedActivitySyncProvider).error, isNull);
  });

  test('synchronizes each selected profile and global scopes once', () async {
    final sync = _Sync();
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    final progress = <(int, int)>[];
    final subscription =
        container.listen(encryptedActivitySyncProvider, (previous, next) {
      if (next.busy && next.totalScopes > 0) {
        progress.add((next.completedScopes, next.totalScopes));
      }
    });
    addTearDown(subscription.close);
    final notifier = container.read(encryptedActivitySyncProvider.notifier);
    await notifier.unlock(
      auth: auth,
      uid: 'account',
      phrase: 'phrase',
      catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
        'p1': {'id': 'p1', 'firstName': 'Alex'},
        'p2': {'id': 'p2', 'firstName': 'Alex'},
      }),
      profileIds: {'p1', 'p2'},
    );
    final calls = sync.calls.map((call) => (call.$1, call.$2)).toSet();
    expect(calls.where((call) => call.$1 == 'p1'), hasLength(6));
    expect(calls.where((call) => call.$1 == 'p2'), hasLength(6));
    expect(calls.where((call) => call.$1 == '__global__'), hasLength(2));
    expect(progress, [for (var i = 0; i < 14; i++) (i, 14)]);
    expect(container.read(encryptedActivitySyncProvider).lastSyncAt, isNotNull);
    container
        .read(currentProfileProvider.notifier)
        .setUserProfile(profile('p2'));
    expect(container.read(encryptedActivitySyncProvider).unlocked, isTrue);
  });

  test('conflicts are resolved only for the affected profile', () async {
    final sync = _Sync()..conflict = ('p2', 'favorites');
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      encryptedCloudChangesProvider.overrideWithValue(_NoCloudChanges()),
      encryptedScopeSynchronizerProvider.overrideWithValue(sync),
      currentProfileProvider
          .overrideWithBuild((ref, notifier) => profile('p1')),
    ]);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    final notifier = container.read(encryptedActivitySyncProvider.notifier);
    await notifier.unlock(
      auth: auth,
      uid: 'account',
      phrase: 'phrase',
      catalog: ProfileCatalogSnapshot(revision: 1, profiles: {
        'p1': {'id': 'p1', 'firstName': 'Alex'},
        'p2': {'id': 'p2', 'firstName': 'Alex'},
      }),
      profileIds: {'p1', 'p2'},
    );
    expect(
        container.read(encryptedActivitySyncProvider).conflictProfileId, 'p2');
    await notifier.resolveConflict(ScopeConflictChoice.local);
    expect(
        sync.calls, contains(('p2', 'favorites', ScopeConflictChoice.local)));
    expect(sync.calls,
        isNot(contains(('p1', 'favorites', ScopeConflictChoice.local))));
    expect(container.read(encryptedActivitySyncProvider).error, isNull);
  });
}
