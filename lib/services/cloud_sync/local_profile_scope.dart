import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/core/utils/json_retyping.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_profile_recovery.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';

class LocalProfileScope implements LocalSyncScope {
  LocalProfileScope(this.profileId);

  final String profileId;

  Map<String, String> _readBox(Box<dynamic> box) {
    final value = box.get(profileId);
    if (value is! Map) {
      throw StateError('Le profil local est introuvable.');
    }
    final profile = validateCloudProfile(deepRetypeMap(value), profileId);
    return {profileId: jsonEncode(profile.toMap())};
  }

  @override
  Future<Map<String, String>> read() => HiveSync.read('profiles', _readBox);

  @override
  void validate(Map<String, String> entries) {
    if (entries.length != 1 || !entries.containsKey(profileId)) {
      throw const FormatException('Fiche de profil invalide.');
    }
    final value = jsonDecode(entries[profileId]!);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Fiche de profil invalide.');
    }
    validateCloudProfile(value, profileId);
  }

  @override
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) async {
    validate(merged);
    await HiveSync.writeAsync('profiles', (box) async {
      checkSession();
      if (!mapEquals(_readBox(box), expected)) {
        throw StateError('Le profil local a changé. Réessayez.');
      }
      if (!mapEquals(expected, merged)) {
        await box.put(profileId, jsonDecode(merged[profileId]!));
      }
    });
  }
}
