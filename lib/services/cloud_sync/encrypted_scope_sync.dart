import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_store.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

/// Keyed fingerprints avoid copying or exposing password hashes in Hive.
class ScopeBaseline {
  ScopeBaseline(Map<String, String> fingerprints, List<int> key)
      : fingerprints = Map.unmodifiable(fingerprints),
        _key = List.unmodifiable(key);

  factory ScopeBaseline.fromEntries(
      Map<String, String> entries, List<int> key) {
    final hmac = Hmac(sha256, key);
    String fingerprint(String value) =>
        hmac.convert(utf8.encode(value)).toString();
    return ScopeBaseline({
      for (final entry in entries.entries)
        fingerprint(entry.key): fingerprint(entry.value),
    }, key);
  }

  final Map<String, String> fingerprints;
  final List<int> _key;

  String fingerprint(String value) =>
      Hmac(sha256, _key).convert(utf8.encode(value)).toString();
}

abstract interface class ScopeBaselineStore {
  Future<ScopeBaseline?> read(String uid, String profileId, String scope);
  Future<void> write(
    String uid,
    String profileId,
    String scope,
    Map<String, String> entries,
  );
}

class HiveScopeBaselineStore implements ScopeBaselineStore {
  static const _box = 'settings';
  static const _secretKey = 'cloud_sync_baseline_key_v1';
  static const _keyMarker = 'cloud_sync_baseline_key_created_v1';

  String _key(String uid, String profileId, String scope) =>
      'cloud_sync_v2_${_digest(jsonEncode([uid, profileId, scope]))}';

  @override
  Future<ScopeBaseline?> read(String uid, String profileId, String scope) =>
      HiveSync.writeAsync(_box, (box) async {
        final value = box.get(_key(uid, profileId, scope));
        if (value == null) return null;
        if (value is! String) {
          throw const FormatException('Miroir de synchronisation invalide.');
        }
        final decoded = jsonDecode(value);
        final fingerprint = RegExp(r'^[0-9a-f]{64}$');
        if (decoded is! Map ||
            decoded.entries.any(
              (e) =>
                  e.key is! String ||
                  e.value is! String ||
                  !fingerprint.hasMatch(e.key as String) ||
                  !fingerprint.hasMatch(e.value as String),
            )) {
          throw const FormatException('Miroir de synchronisation invalide.');
        }
        final secret = await readSecretStrict(_secretKey);
        if (secret == null) {
          throw StateError('La clé locale du miroir cloud est introuvable.');
        }
        final key = base64Decode(secret);
        if (key.length != 32) {
          throw const FormatException('Clé du miroir cloud invalide.');
        }
        return ScopeBaseline(Map<String, String>.from(decoded), key);
      });

  @override
  Future<void> write(
    String uid,
    String profileId,
    String scope,
    Map<String, String> entries,
  ) =>
      HiveSync.writeAsync(
        _box,
        (box) async {
          var secret = await readSecretStrict(_secretKey);
          if (secret == null) {
            if (box.get(_keyMarker) == true ||
                box.get(_key(uid, profileId, scope)) != null) {
              throw StateError(
                  'La clé locale du miroir cloud est introuvable.');
            }
            final random = Random.secure();
            secret =
                base64Encode(List.generate(32, (_) => random.nextInt(256)));
            await writeSecretStrict(_secretKey, secret);
          }
          final key = base64Decode(secret);
          if (key.length != 32) {
            throw const FormatException('Clé du miroir cloud invalide.');
          }
          await box.put(_keyMarker, true);
          await box.put(
            _key(uid, profileId, scope),
            jsonEncode(ScopeBaseline.fromEntries(entries, key).fingerprints),
          );
        },
      );
}

enum ScopeConflictChoice { local, cloud }

Map<String, String> mergeScopeWithBaseline({
  required Map<String, String> local,
  required Map<String, String> remote,
  required ScopeBaseline? baseline,
  ScopeConflictChoice? conflictChoice,
}) {
  final merged = <String, String>{};
  final conflicts = <String>{};
  for (final key in {...local.keys, ...remote.keys}) {
    final localValue = local[key];
    final remoteValue = remote[key];
    final previous = baseline?.fingerprints[baseline.fingerprint(key)];
    final localHash =
        localValue == null ? null : baseline?.fingerprint(localValue);
    final remoteHash =
        remoteValue == null ? null : baseline?.fingerprint(remoteValue);
    String? value;
    if (localValue == remoteValue) {
      value = localValue;
    } else if (baseline == null &&
        (localValue == null || remoteValue == null)) {
      value = localValue ?? remoteValue;
    } else if (baseline != null && localHash == previous) {
      value = remoteValue;
    } else if (baseline != null && remoteHash == previous) {
      value = localValue;
    } else if (conflictChoice != null) {
      value = conflictChoice == ScopeConflictChoice.local
          ? localValue
          : remoteValue;
    } else {
      conflicts.add(key);
      continue;
    }
    if (value != null) merged[key] = value;
  }
  if (conflicts.isNotEmpty) throw ScopeMergeConflict(conflicts);
  return Map.unmodifiable(merged);
}

abstract interface class LocalSyncScope {
  Future<Map<String, String>> read();

  void validate(Map<String, String> entries);

  /// Apply only if the local state still matches [expected].
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  );
}

/// Coordinates a scope without advancing its mirror after a failed operation.
class EncryptedScopeSynchronizer {
  EncryptedScopeSynchronizer({
    required this.remote,
    required this.baselines,
  });

  final EncryptedScopeStore remote;
  final ScopeBaselineStore baselines;

  Future<bool> synchronize({
    required String uid,
    required String profileId,
    required String scope,
    required String passphrase,
    required LocalSyncScope local,
    required void Function() checkSession,
    ScopeConflictChoice? conflictChoice,
  }) async {
    checkSession();
    final localEntries = await local.read();
    checkSession();
    final baseline = await baselines.read(uid, profileId, scope);
    checkSession();
    final cloud = await remote.read(
      uid: uid,
      profileId: profileId,
      scope: scope,
      passphrase: passphrase,
    );
    checkSession();
    if (cloud == null && baseline != null) {
      throw StateError('Le document cloud est introuvable ; aucune suppression '
          'locale n’a été effectuée.');
    }
    final remoteEntries = cloud?.entries ?? <String, String>{};
    if (cloud != null) local.validate(remoteEntries);
    final merged = mergeScopeWithBaseline(
      local: localEntries,
      remote: remoteEntries,
      baseline: baseline,
      conflictChoice: conflictChoice,
    );
    local.validate(merged);
    if (cloud == null || !mapEquals(merged, remoteEntries)) {
      await remote.write(
        uid: uid,
        profileId: profileId,
        scope: scope,
        passphrase: passphrase,
        snapshot: EncryptedScopeSnapshot(
            revision: cloud?.revision ?? 0, entries: merged),
        checkSession: checkSession,
      );
    }
    checkSession();
    await local.applyIfUnchanged(localEntries, merged, checkSession);
    checkSession();
    await baselines.write(
      uid,
      profileId,
      scope,
      merged,
    );
    return !mapEquals(localEntries, merged);
  }
}
