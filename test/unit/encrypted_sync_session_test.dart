import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'account';
  @override
  bool get isAnonymous => false;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
  @override
  Stream<User?> authStateChanges() => const Stream.empty();
}

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

void main() {
  test('unlocked session uploads all requested categories as encrypted data',
      () async {
    final dir = await Directory.systemTemp.createTemp('orbit_cloud_session_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(SubscriptionAdapter().typeId)) {
      Hive.registerAdapter(SubscriptionAdapter());
      Hive.registerAdapter(SubscriptionTypeAdapter());
      Hive.registerAdapter(TestResultStatusAdapter());
    }
    SharedPreferences.setMockInitialValues({});
    overrideSecretStoreForTesting(InMemorySecretStore());
    final storage = StorageService();
    await storage.init();
    for (final name in [
      'favorites',
      'recently_watched',
      'watched_episodes',
      'playback_progress',
    ]) {
      await Hive.openBox(name);
    }
    final profile = UserProfile(
      id: 'profile',
      firstName: 'Alex',
      dateOfBirth: DateTime.utc(1990),
      gender: '',
      favoriteGenres: const [],
    );
    await storage.saveProfile(profile);
    await storage.saveSubscription(Subscription(
      id: 'source',
      name: 'Source',
      type: SubscriptionType.xtream,
      baseUrl: 'https://private.example.test',
      username: 'secret-user',
      password: 'secret-password',
      createdAt: DateTime.utc(2025),
    ));
    await FavoritesService().save(const FavoriteEntry(
      type: ContentType.live,
      id: 'channel',
      title: 'Channel',
      profileId: 'profile',
      streamUrl: 'https://private.example.test/stream',
    ));
    final documents = _Documents();
    final container = ProviderContainer(overrides: [
      storageServiceProvider.overrideWithValue(storage),
      currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
      encryptedScopeSynchronizerProvider.overrideWithValue(
        EncryptedScopeSynchronizer(
          remote: EncryptedScopeStore(EncryptedCloudStore(store: documents)),
          baselines: HiveScopeBaselineStore(),
        ),
      ),
    ]);
    try {
      await container.read(encryptedActivitySyncProvider.notifier).unlock(
            auth: _Auth(),
            uid: 'account',
            phrase: 'phrase secrète suffisamment longue',
            catalog: ProfileCatalogSnapshot(
              revision: 1,
              profiles: {'profile': profile.toMap()},
            ),
          );
      final state = container.read(encryptedActivitySyncProvider);
      expect(state.error, isNull);
      expect(state.lastSyncAt, isNotNull);
      expect(documents.documents, hasLength(7));
      final stored = jsonEncode(documents.documents);
      expect(stored, isNot(contains('secret-password')));
      expect(stored, isNot(contains('private.example.test')));
      expect(stored, isNot(contains('Alex')));
      expect((Hive.box('subscriptions').get('source') as Subscription).password,
          isEmpty);
    } finally {
      container.dispose();
      await Hive.close();
      await dir.delete(recursive: true);
      restoreSecretStoreForTesting();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
