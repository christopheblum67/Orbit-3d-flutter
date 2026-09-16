import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_gateway.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_mirror_store.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_service.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/firestore_cloud_sync_gateway.dart';

/// État global de la synchronisation cloud (S2).
class CloudSyncState {
  const CloudSyncState({
    this.enabled = false,
    this.busy = false,
    this.signedIn = false,
    this.lastSyncAt,
    this.lastError,
  });

  final bool enabled;
  final bool busy;
  final bool signedIn;
  final DateTime? lastSyncAt;
  final String? lastError;

  CloudSyncState copyWith({
    bool? enabled,
    bool? busy,
    bool? signedIn,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return CloudSyncState(
      enabled: enabled ?? this.enabled,
      busy: busy ?? this.busy,
      signedIn: signedIn ?? this.signedIn,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final cloudSyncGatewayProvider = Provider<CloudSyncGateway>(
  (ref) => FirestoreCloudSyncGateway(),
);
final cloudSyncMirrorStoreProvider =
    Provider<CloudSyncMirrorStore>((ref) => CloudSyncMirrorStore());
final cloudSyncServiceProvider = Provider<CloudSyncService>(
  (ref) => CloudSyncService(),
);

final cloudSyncProvider =
    NotifierProvider<CloudSyncNotifier, CloudSyncState>(CloudSyncNotifier.new);

class CloudSyncNotifier extends Notifier<CloudSyncState> {
  static const String _prefKey = 'cloud_sync_enabled';
  static const Duration _pushDebounce = Duration(seconds: 3);

  Timer? _debounce;
  bool _applyingRemote = false;

  @override
  CloudSyncState build() {
    final storage = ref.read(storageServiceProvider);
    final enabled = storage.getSetting(_prefKey) == 'true';

    ref.listen(favoritesProvider, (_, __) => _schedulePush());
    ref.listen(recentlyWatchedProvider, (_, __) => _schedulePush());
    ref.listen(watchedEpisodesProvider, (_, __) => _schedulePush());

    ref.onDispose(() => _debounce?.cancel());

    state = CloudSyncState(enabled: enabled);
    if (enabled) Future.microtask(syncNow);
    return state;
  }

  Future<void> setEnabled(bool value) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting(_prefKey, '$value');
    state = CloudSyncState(
      enabled: value,
      signedIn: state.signedIn,
      lastSyncAt: state.lastSyncAt,
    );
    if (value) {
      await syncNow();
    }
  }

  /// Synchronise tous les scopes du profil actif.
  Future<void> syncNow() async {
    if (state.busy) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      state = state.copyWith(lastError: 'Aucun profil actif');
      return;
    }

    state = state.copyWith(busy: true, clearError: true);
    try {
      await _ensureSignedIn();
      for (final scope in CloudSyncScope.values) {
        await _syncScope(scope, profile.id);
      }
      state = state.copyWith(
        busy: false,
        signedIn: true,
        lastSyncAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(busy: false, lastError: '$e');
    }
  }

  Future<void> _ensureSignedIn() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      throw StateError('Connexion cloud impossible : $e');
    }
  }

  void _schedulePush() {
    if (_applyingRemote || !state.enabled) return;
    _debounce?.cancel();
    _debounce = Timer(_pushDebounce, () {
      _debounce = null;
      final profile = ref.read(currentProfileProvider);
      if (profile == null || !state.enabled) return;
      syncNow();
    });
  }

  Future<void> _syncScope(CloudSyncScope scope, String profileId) async {
    final gateway = ref.read(cloudSyncGatewayProvider);
    final store = ref.read(cloudSyncMirrorStoreProvider);
    final service = ref.read(cloudSyncServiceProvider);

    final local = await _readLocalScope(scope, profileId);
    final mirror = await store.getMirror(scope, profileId);
    final remote = await gateway.fetchSnapshot(scope, profileId);

    final result = service.merge(
      scope: scope,
      profileId: profileId,
      local: local,
      remote: remote,
      mirror: mirror,
    );

    if (result.remoteWins) {
      await _applyRemote(scope, result, profileId);
    }

    await store.saveMirror(result.merged);
    if (result.pushRequired) {
      await gateway.pushSnapshot(result.merged);
    }
  }

  /// Lit l'état local du scope (source de vérité : Hive via les services).
  Future<Map<String, String>> _readLocalScope(
    CloudSyncScope scope,
    String profileId,
  ) async {
    switch (scope) {
      case CloudSyncScope.favorites:
        final entries =
            await ref.read(favoritesServiceProvider).loadForProfile(profileId);
        return {
          for (final e in entries) e.key: jsonEncode(e.toJson()),
        };
      case CloudSyncScope.watched:
        final entries = await ref
            .read(watchedEpisodesServiceProvider)
            .loadForProfile(profileId);
        return {
          for (final e in entries) e.key: jsonEncode(e.toJson()),
        };
      case CloudSyncScope.recents:
        final entries = await ref
            .read(recentlyWatchedServiceProvider)
            .loadForProfile(profileId);
        return {
          for (final e in entries) e.key: jsonEncode(e.toJson()),
        };
    }
  }

  /// Applique localement les changements imposés par le cloud.
  Future<void> _applyRemote(
    CloudSyncScope scope,
    CloudSyncMergeResult result,
    String profileId,
  ) async {
    _applyingRemote = true;
    try {
      switch (scope) {
        case CloudSyncScope.favorites:
          final entries = <FavoriteEntry>[];
          for (final raw in result.localWrites.values) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                entries.add(FavoriteEntry.fromJson(decoded));
              }
            } catch (_) {}
          }
          await ref
              .read(favoritesProvider.notifier)
              .applySyncedProfile(entries, removes: result.localRemoves);
        case CloudSyncScope.watched:
          final entries = <WatchedEpisodeEntry>[];
          for (final raw in result.localWrites.values) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                entries.add(WatchedEpisodeEntry.fromJson(decoded));
              }
            } catch (_) {}
          }
          await ref
              .read(watchedEpisodesProvider.notifier)
              .applySyncedProfile(entries, removes: result.localRemoves);
        case CloudSyncScope.recents:
          final entries = <RecentEntry>[];
          for (final raw in result.localWrites.values) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                entries.add(RecentEntry.fromJson(decoded));
              }
            } catch (_) {}
          }
          await ref
              .read(recentlyWatchedProvider.notifier)
              .applySyncedProfile(entries, removes: result.localRemoves);
      }
    } finally {
      _applyingRemote = false;
    }
  }
}