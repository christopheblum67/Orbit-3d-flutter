import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/radio_favorites_provider.dart';
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
import 'package:orbit_3d_flutter/services/cloud_sync/local_radio_favorites_scope.dart';
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
  radioFavorites,
}

class EncryptedActivitySyncState {
  const EncryptedActivitySyncState({
    this.profileId,
    this.profileIds = const {},
    this.busy = false,
    this.error,
    this.conflictScope,
    this.conflictProfileId,
    this.lastSyncAt,
    this.currentScope,
    this.currentProfileId,
    this.completedScopes = 0,
    this.totalScopes = 0,
    this.realtimeError,
  });

  final String? profileId;
  final Set<String> profileIds;
  final bool busy;
  final String? error;
  final String? conflictScope;
  final String? conflictProfileId;
  final DateTime? lastSyncAt;
  final String? currentScope;
  final String? currentProfileId;
  final int completedScopes;
  final int totalScopes;
  final String? realtimeError;

  bool get unlocked => profileId != null;

  EncryptedActivitySyncState withRealtimeError(String? message) =>
      EncryptedActivitySyncState(
        profileId: profileId,
        profileIds: profileIds,
        busy: busy,
        error: error,
        conflictScope: conflictScope,
        conflictProfileId: conflictProfileId,
        lastSyncAt: lastSyncAt,
        currentScope: currentScope,
        currentProfileId: currentProfileId,
        completedScopes: completedScopes,
        totalScopes: totalScopes,
        realtimeError: message,
      );
}

final encryptedCloudChangesProvider = Provider<EncryptedCloudChangeSource>(
  (ref) => FirestoreEncryptedCloudChangeSource(),
);

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
  Set<String> _profileIds = const {};
  bool _lockOnProfileChange = true;
  ScopeConflictChoice? _initialConflictChoice;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authChanges;
  StreamSubscription<String>? _cloudChanges;
  Timer? _debounce;
  Timer? _poll;
  final _listeners = <ProviderSubscription<dynamic>>[];
  final _dirty = <(String?, _SyncKind)>{};
  final _choices = <(String?, _SyncKind), ScopeConflictChoice>{};
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
      _cloudChanges?.cancel();
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
    Set<String>? profileIds,
    ScopeConflictChoice? initialConflictChoice,
  }) async {
    if (_busy) throw StateError('Une synchronisation est déjà en cours.');
    final profileId = ref.read(currentProfileProvider)?.id;
    final selected =
        profileIds ?? (profileId == null ? <String>{} : {profileId});
    final user = auth.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Le compte cloud a changé.');
    }
    if (phrase.isEmpty ||
        selected.isEmpty ||
        selected.any((id) => !catalog.profiles.containsKey(id))) {
      throw StateError(
        'Sélectionnez un profil actif déjà sauvegardé dans ce compte.',
      );
    }
    lock();
    _uid = uid;
    _phrase = phrase;
    _initialConflictChoice = initialConflictChoice;
    _profileIds = Set.unmodifiable(selected);
    _profileId = profileId != null && selected.contains(profileId)
        ? profileId
        : selected.first;
    _lockOnProfileChange = profileIds == null;
    _auth = auth;
    final generation = _generation;
    _listeners.addAll([
      ref.listen(favoritesProvider, (_, __) => _changed(_SyncKind.favorites)),
      ref.listen(radioFavoritesProvider,
          (_, __) => _changed(_SyncKind.radioFavorites)),
      ref.listen(
          recentlyWatchedProvider, (_, __) => _changed(_SyncKind.recents)),
      ref.listen(
          watchedEpisodesProvider, (_, __) => _changed(_SyncKind.watched)),
      ref.listen(playbackProgressServiceProvider,
          (_, __) => _changed(_SyncKind.playback)),
      ref.listen(
          preferencesProvider, (_, __) => _changed(_SyncKind.preferences)),
      ref.listen(currentProfileProvider, (_, profile) {
        if (_lockOnProfileChange &&
            _profileId != null &&
            profile?.id != _profileId) {
          lock();
        }
        if (profile != null && _profileIds.contains(profile.id)) {
          _changed(_SyncKind.profile);
        }
      }),
      ref.listen(profilesProvider, (_, __) {
        for (final id in _profileIds) {
          _changed(_SyncKind.profile, profileId: id);
        }
      }),
      ref.listen(
          subscriptionsProvider, (_, __) => _changed(_SyncKind.subscriptions)),
    ]);
    _authChanges = auth.authStateChanges().listen((user) {
      if (user == null || user.isAnonymous || user.uid != uid) lock();
    });
    _markAllDirty();
    state = EncryptedActivitySyncState(
        profileId: _profileId, profileIds: _profileIds);
    final documents = <String, (String?, _SyncKind)>{};
    for (final kind in _SyncKind.values) {
      if (_isGlobal(kind)) {
        documents[EncryptedScopeStore.documentId('__global__', kind.name)] =
            (null, kind);
      } else {
        for (final id in _profileIds) {
          documents[EncryptedScopeStore.documentId(id, kind.name)] = (id, kind);
        }
      }
    }
    void watchFailed() {
      if (!ref.mounted || _generation != generation) return;
      state = state.withRealtimeError(
        'Écoute cloud indisponible : vérification périodique maintenue.',
      );
    }

    try {
      _cloudChanges = ref.read(encryptedCloudChangesProvider).watch(uid).listen(
        (documentId) {
          if (!ref.mounted || _generation != generation) return;
          if (documentId == EncryptedCloudStore.controlDocumentId) {
            lock(
              message: 'Le partage Cloud a changé. La synchronisation est '
                  'en pause : actualisez la liste des profils avant de reprendre.',
            );
            return;
          }
          final task = documents[documentId];
          if (task == null) return;
          _dirty.add(task);
          _scheduleSync();
        },
        onError: (Object error, StackTrace stack) => watchFailed(),
        onDone: watchFailed,
      );
    } catch (_) {
      watchFailed();
    }
    _poll = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_generation != generation || _busy || state.conflictScope != null)
        return;
      _markAllDirty();
      unawaited(syncNow());
    });
    await syncNow();
  }

  void lock({String? message}) {
    _generation++;
    _phrase = null;
    _uid = null;
    _profileId = null;
    _profileIds = const {};
    _initialConflictChoice = null;
    _auth = null;
    _debounce?.cancel();
    _debounce = null;
    _poll?.cancel();
    _authChanges?.cancel();
    _authChanges = null;
    _cloudChanges?.cancel();
    _cloudChanges = null;
    for (final listener in _listeners) {
      listener.close();
    }
    _listeners.clear();
    _dirty.clear();
    _choices.clear();
    if (ref.mounted) {
      state = EncryptedActivitySyncState(error: message);
    }
  }

  bool _isGlobal(_SyncKind kind) =>
      kind == _SyncKind.preferences || kind == _SyncKind.subscriptions;

  void _markAllDirty() {
    for (final kind in _SyncKind.values) {
      if (_isGlobal(kind)) {
        _dirty.add((null, kind));
      } else {
        for (final id in _profileIds) {
          _dirty.add((id, kind));
        }
      }
    }
  }

  void _changed(_SyncKind kind, {String? profileId}) {
    if (_phrase == null) return;
    final id = _isGlobal(kind)
        ? null
        : (profileId ?? ref.read(currentProfileProvider)?.id);
    if (!_isGlobal(kind) && !_profileIds.contains(id)) return;
    _dirty.add((id, kind));
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_debounce != null) return;
    _debounce = Timer(const Duration(seconds: 1), () {
      _debounce = null;
      if (state.conflictScope == null) unawaited(syncNow());
    });
  }

  Future<void> syncAll() {
    if (_phrase == null) return Future.value();
    _markAllDirty();
    return syncNow();
  }

  Future<void> resolveConflict(ScopeConflictChoice choice) {
    final name = state.conflictScope;
    if (_phrase == null || _busy || name == null) return Future.value();
    final kind = _SyncKind.values.byName(name);
    final task = (state.conflictProfileId, kind);
    _choices[task] = choice;
    _dirty.remove(task);
    final pending = _dirty.toList();
    _dirty
      ..clear()
      ..add(task)
      ..addAll(pending);
    return syncNow();
  }

  Future<void> syncNow() async {
    if (_busy || _phrase == null || _profileId == null || _uid == null) return;
    _debounce?.cancel();
    _debounce = null;
    final uid = _uid!;
    final phrase = _phrase!;
    final profileId = _profileId!;
    final generation = _generation;
    String? currentProfileId;
    void checkSession() {
      final user = _auth?.currentUser;
      if (!ref.mounted ||
          generation != _generation ||
          user == null ||
          user.isAnonymous ||
          user.uid != uid ||
          (_lockOnProfileChange &&
              ref.read(currentProfileProvider)?.id != profileId)) {
        throw StateError('La session cloud a changé.');
      }
      if (currentProfileId != null &&
          !Hive.box<dynamic>('profiles').containsKey(currentProfileId)) {
        throw StateError('Le profil local est introuvable.');
      }
    }

    _busy = true;
    state = EncryptedActivitySyncState(
      profileId: profileId,
      profileIds: _profileIds,
      busy: true,
      lastSyncAt: state.lastSyncAt,
      realtimeError: state.realtimeError,
    );
    _SyncKind? currentKind;
    var completedScopes = 0;
    try {
      final synchronizer = ref.read(encryptedScopeSynchronizerProvider);
      while (_dirty.isNotEmpty) {
        checkSession();
        final task = _dirty.first;
        final (taskProfileId, kind) = task;
        currentKind = kind;
        currentProfileId = taskProfileId;
        _dirty.remove(task);
        state = EncryptedActivitySyncState(
          profileId: profileId,
          profileIds: _profileIds,
          busy: true,
          lastSyncAt: state.lastSyncAt,
          currentScope: kind.name,
          currentProfileId: taskProfileId,
          completedScopes: completedScopes,
          totalScopes: completedScopes + _dirty.length + 1,
          realtimeError: state.realtimeError,
        );
        try {
          final choice = _choices.remove(task) ?? _initialConflictChoice;
          var retries = 0;
          late bool changed;
          while (true) {
            try {
              changed = await synchronizer.synchronize(
                uid: uid,
                profileId: taskProfileId ?? '__global__',
                scope: kind.name,
                passphrase: phrase,
                local: switch (kind) {
                  _SyncKind.preferences => LocalPreferencesScope(),
                  _SyncKind.profile => LocalProfileScope(taskProfileId!),
                  _SyncKind.subscriptions =>
                    LocalSubscriptionScope(ref.read(storageServiceProvider)),
                  _SyncKind.radioFavorites =>
                    LocalRadioFavoritesScope(taskProfileId!),
                  _ => LocalProfileActivityScope(
                      taskProfileId!,
                      ProfileActivityKind.values.byName(kind.name),
                    ),
                },
                checkSession: checkSession,
                conflictChoice: choice,
              );
              break;
            } on CloudSyncConflict {
              checkSession();
              if (++retries > 2) rethrow;
            }
          }
          checkSession();
          if (changed) {
            switch (kind) {
              case _SyncKind.favorites:
                if (ref.read(currentProfileProvider)?.id == taskProfileId) {
                  ref.invalidate(favoritesProvider);
                }
              case _SyncKind.recents:
                if (ref.read(currentProfileProvider)?.id == taskProfileId) {
                  ref.invalidate(recentlyWatchedProvider);
                }
              case _SyncKind.watched:
                if (ref.read(currentProfileProvider)?.id == taskProfileId) {
                  ref.invalidate(watchedEpisodesProvider);
                }
              case _SyncKind.playback:
                if (ref.read(currentProfileProvider)?.id == taskProfileId) {
                  ref.read(playbackProgressServiceProvider).notifySyncApplied();
                }
              case _SyncKind.preferences:
                ref.invalidate(preferencesProvider);
              case _SyncKind.profile:
                final profiles =
                    await ref.read(storageServiceProvider).getProfiles();
                checkSession();
                final profile =
                    profiles.where((p) => p.id == taskProfileId).firstOrNull;
                if (profile == null) throw StateError('Profil introuvable.');
                if (ref.read(currentProfileProvider)?.id == taskProfileId) {
                  ref
                      .read(currentProfileProvider.notifier)
                      .setUserProfile(profile);
                }
                ref.invalidate(profilesProvider);
              case _SyncKind.subscriptions:
                await ref
                    .read(subscriptionsProvider.notifier)
                    .reloadAfterCloudSync();
                checkSession();
                ref.invalidate(activeSubscriptionProvider);
              case _SyncKind.radioFavorites:
                if (ref.read(currentProfileProvider)?.id == taskProfileId) {
                  ref.invalidate(radioFavoritesProvider);
                }
            }
          }
          completedScopes++;
        } catch (_) {
          if (generation == _generation) _dirty.add(task);
          rethrow;
        }
      }
      if (ref.mounted && generation == _generation) {
        _initialConflictChoice = null;
        state = EncryptedActivitySyncState(
          profileId: profileId,
          profileIds: _profileIds,
          lastSyncAt: DateTime.now(),
          realtimeError: state.realtimeError,
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
          conflictScope: currentKind?.name,
          conflictProfileId: currentProfileId);
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

  void _showError(int generation, String message,
      {String? conflictScope, String? conflictProfileId}) {
    if (!ref.mounted || generation != _generation) return;
    state = EncryptedActivitySyncState(
      profileId: _profileId,
      profileIds: _profileIds,
      lastSyncAt: state.lastSyncAt,
      error: message,
      conflictScope: conflictScope,
      conflictProfileId: conflictProfileId,
      realtimeError: state.realtimeError,
    );
  }
}
