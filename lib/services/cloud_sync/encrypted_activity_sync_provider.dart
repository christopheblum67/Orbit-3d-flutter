import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_cloud_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_catalog.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_profile_activity_scope.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_preferences_scope.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_profile_scope.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_subscription_scope.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

enum _SyncKind {
  favorites,
  recents,
  watched,
  playback,
  preferences,
  profile,
  subscriptions,
}

class EncryptedActivitySyncState {
  const EncryptedActivitySyncState({
    this.profileId,
    this.busy = false,
    this.error,
    this.conflictScope,
    this.lastSyncAt,
  });

  final String? profileId;
  final bool busy;
  final String? error;
  final String? conflictScope;
  final DateTime? lastSyncAt;

  bool get unlocked => profileId != null;
}

final encryptedScopeSynchronizerProvider = Provider<EncryptedScopeSynchronizer>(
  (ref) => EncryptedScopeSynchronizer(
    remote: EncryptedScopeStore(
      EncryptedCloudStore(store: FirestoreEncryptedDocumentStore()),
    ),
    baselines: HiveScopeBaselineStore(),
  ),
);

final encryptedActivitySyncProvider =
    NotifierProvider<EncryptedActivitySyncNotifier, EncryptedActivitySyncState>(
        EncryptedActivitySyncNotifier.new);

/// The passphrase lives only in memory and is cleared on account/profile change.
class EncryptedActivitySyncNotifier
    extends Notifier<EncryptedActivitySyncState> {
  String? _uid;
  String? _phrase;
  String? _profileId;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authChanges;
  Timer? _debounce;
  Timer? _poll;
  final _listeners = <ProviderSubscription<dynamic>>[];
  final _dirty = <_SyncKind>{};
  final _choices = <_SyncKind, ScopeConflictChoice>{};
  var _generation = 0;
  var _busy = false;

  @override
  EncryptedActivitySyncState build() {
    ref.onDispose(() {
      _generation++;
      _phrase = null;
      _debounce?.cancel();
      _poll?.cancel();
      _authChanges?.cancel();
      for (final listener in _listeners) {
        listener.close();
      }
      _listeners.clear();
    });
    return const EncryptedActivitySyncState();
  }

  Future<void> unlock({
    required FirebaseAuth auth,
    required String uid,
    required String phrase,
    required ProfileCatalogSnapshot catalog,
  }) async {
    if (_busy) throw StateError('Une synchronisation est déjà en cours.');
    final profileId = ref.read(currentProfileProvider)?.id;
    final user = auth.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Le compte cloud a changé.');
    }
    if (phrase.isEmpty ||
        profileId == null ||
        !catalog.profiles.containsKey(profileId)) {
      throw StateError(
        'Sélectionnez un profil actif déjà sauvegardé dans ce compte.',
      );
    }
    lock();
    _uid = uid;
    _phrase = phrase;
    _profileId = profileId;
    _auth = auth;
    final generation = _generation;
    _listeners.addAll([
      ref.listen(favoritesProvider, (_, __) => _changed(_SyncKind.favorites)),
      ref.listen(
          recentlyWatchedProvider, (_, __) => _changed(_SyncKind.recents)),
      ref.listen(
          watchedEpisodesProvider, (_, __) => _changed(_SyncKind.watched)),
      ref.listen(playbackProgressServiceProvider,
          (_, __) => _changed(_SyncKind.playback)),
      ref.listen(
          preferencesProvider, (_, __) => _changed(_SyncKind.preferences)),
      ref.listen(currentProfileProvider, (_, profile) {
        if (_profileId != null && profile?.id != _profileId) lock();
        if (_profileId != null && profile?.id == _profileId) {
          _changed(_SyncKind.profile);
        }
      }),
      ref.listen(profilesProvider, (_, __) => _changed(_SyncKind.profile)),
      ref.listen(
          subscriptionsProvider, (_, __) => _changed(_SyncKind.subscriptions)),
    ]);
    _authChanges = auth.authStateChanges().listen((user) {
      if (user == null || user.isAnonymous || user.uid != uid) lock();
    });
    _dirty.addAll(_SyncKind.values);
    state = EncryptedActivitySyncState(profileId: profileId);
    _poll = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_generation != generation) return;
      _dirty.addAll(_SyncKind.values);
      unawaited(syncNow());
    });
    await syncNow();
  }

  void lock() {
    _generation++;
    _phrase = null;
    _uid = null;
    _profileId = null;
    _auth = null;
    _debounce?.cancel();
    _poll?.cancel();
    _authChanges?.cancel();
    _authChanges = null;
    for (final listener in _listeners) {
      listener.close();
    }
    _listeners.clear();
    _dirty.clear();
    _choices.clear();
    if (ref.mounted) state = const EncryptedActivitySyncState();
  }

  void _changed(_SyncKind kind) {
    if (_phrase == null) return;
    _dirty.add(kind);
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 30), () => unawaited(syncNow()));
  }

  Future<void> syncAll() {
    if (_phrase == null) return Future.value();
    _dirty.addAll(_SyncKind.values);
    return syncNow();
  }

  Future<void> resolveConflict(ScopeConflictChoice choice) {
    final name = state.conflictScope;
    if (_phrase == null || _busy || name == null) return Future.value();
    final kind = _SyncKind.values.byName(name);
    _choices[kind] = choice;
    _dirty.add(kind);
    return syncNow();
  }

  Future<void> syncNow() async {
    if (_busy || _phrase == null || _profileId == null || _uid == null) return;
    _debounce?.cancel();
    final uid = _uid!;
    final phrase = _phrase!;
    final profileId = _profileId!;
    final generation = _generation;
    void checkSession() {
      final user = _auth?.currentUser;
      if (!ref.mounted ||
          generation != _generation ||
          user == null ||
          user.isAnonymous ||
          user.uid != uid ||
          ref.read(currentProfileProvider)?.id != profileId) {
        throw StateError('La session cloud a changé.');
      }
    }

    _busy = true;
    state = EncryptedActivitySyncState(
      profileId: profileId,
      busy: true,
      lastSyncAt: state.lastSyncAt,
    );
    _SyncKind? currentKind;
    try {
      final synchronizer = ref.read(encryptedScopeSynchronizerProvider);
      while (_dirty.isNotEmpty) {
        checkSession();
        final kind = _dirty.first;
        currentKind = kind;
        _dirty.remove(kind);
        try {
          final changed = await synchronizer.synchronize(
            uid: uid,
            profileId:
                kind == _SyncKind.preferences || kind == _SyncKind.subscriptions
                    ? '__global__'
                    : profileId,
            scope: kind.name,
            passphrase: phrase,
            local: switch (kind) {
              _SyncKind.preferences => LocalPreferencesScope(),
              _SyncKind.profile => LocalProfileScope(profileId),
              _SyncKind.subscriptions =>
                LocalSubscriptionScope(ref.read(storageServiceProvider)),
              _ => LocalProfileActivityScope(
                  profileId,
                  ProfileActivityKind.values.byName(kind.name),
                ),
            },
            checkSession: checkSession,
            conflictChoice: _choices.remove(kind),
          );
          checkSession();
          if (changed) {
            switch (kind) {
              case _SyncKind.favorites:
                ref.invalidate(favoritesProvider);
              case _SyncKind.recents:
                ref.invalidate(recentlyWatchedProvider);
              case _SyncKind.watched:
                ref.invalidate(watchedEpisodesProvider);
              case _SyncKind.playback:
                ref.read(playbackProgressServiceProvider).notifySyncApplied();
              case _SyncKind.preferences:
                ref.invalidate(preferencesProvider);
              case _SyncKind.profile:
                final profiles =
                    await ref.read(storageServiceProvider).getProfiles();
                checkSession();
                final profile =
                    profiles.where((p) => p.id == profileId).firstOrNull;
                if (profile == null) throw StateError('Profil introuvable.');
                ref
                    .read(currentProfileProvider.notifier)
                    .setUserProfile(profile);
                ref.invalidate(profilesProvider);
              case _SyncKind.subscriptions:
                await ref
                    .read(subscriptionsProvider.notifier)
                    .reloadAfterCloudSync();
                checkSession();
                ref.invalidate(activeSubscriptionProvider);
            }
          }
        } catch (_) {
          _dirty.add(kind);
          rethrow;
        }
      }
      if (ref.mounted && generation == _generation) {
        state = EncryptedActivitySyncState(
          profileId: profileId,
          lastSyncAt: DateTime.now(),
        );
      }
    } on ActiveSubscriptionSyncRemoval {
      _showError(
        generation,
        'Un abonnement supprimé dans le cloud est actif ici. '
        'Changez d’abonnement actif ou supprimez-le manuellement, puis réessayez.',
      );
    } on ScopeMergeConflict {
      _showError(generation,
          'Modifications concurrentes : choisissez quelle version conserver.',
          conflictScope: currentKind?.name);
    } on CloudSyncConflict {
      _showError(generation, 'Le cloud a changé ailleurs. Réessayez.');
    } on SecretBoxAuthenticationError {
      _showError(generation, 'Phrase secrète incorrecte ou données altérées.');
    } on FirebaseException {
      _showError(generation,
          'Accès cloud impossible. Vérifiez le réseau et Firebase.');
    } on FormatException {
      _showError(generation, 'Données invalides : synchronisation arrêtée.');
    } on StateError {
      _showError(generation,
          'La session ou les données locales ont changé. Réessayez.');
    } catch (_) {
      _showError(generation, 'Synchronisation impossible. Réessayez.');
    } finally {
      _busy = false;
    }
  }

  void _showError(int generation, String message, {String? conflictScope}) {
    if (!ref.mounted || generation != _generation) return;
    state = EncryptedActivitySyncState(
      profileId: _profileId,
      lastSyncAt: state.lastSyncAt,
      error: message,
      conflictScope: conflictScope,
    );
  }
}
