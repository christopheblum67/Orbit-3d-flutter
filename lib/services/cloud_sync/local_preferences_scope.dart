import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/core/utils/json_retyping.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';

/// Preferences are device-global, not properties of the current profile.
class LocalPreferencesScope implements LocalSyncScope {
  static const _box = 'settings';
  static const _key = 'user_preferences';

  Map<String, String> _readBox(Box<dynamic> box) {
    final raw = box.get(_key);
    if (raw != null && raw is! Map) {
      throw const FormatException('Préférences locales invalides.');
    }
    final value = raw == null
        ? const UserPreferences().toMap()
        : UserPreferences.fromMap(deepRetypeMap(raw as Map)).toMap();
    final result = {_key: jsonEncode(value)};
    validate(result);
    return result;
  }

  @override
  Future<Map<String, String>> read() => HiveSync.read(_box, _readBox);

  @override
  void validate(Map<String, String> entries) {
    if (entries.length != 1 || !entries.containsKey(_key)) {
      throw const FormatException('Préférences cloud invalides.');
    }
    final value = jsonDecode(entries[_key]!);
    if (value is! Map<String, dynamic> ||
        value['parentalControlEnabled'] is! bool ||
        value['ageRestriction'] is! int ||
        value['language'] is! String ||
        value['theme'] is! String ||
        value['profileVisible'] is! bool ||
        value['allowRecording'] is! bool ||
        value['fontScale'] is! num ||
        !(value['fontScale'] as num).isFinite) {
      throw const FormatException('Préférences cloud invalides.');
    }
  }

  @override
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) async {
    validate(merged);
    await HiveSync.writeAsync(_box, (box) async {
      checkSession();
      if (!mapEquals(_readBox(box), expected)) {
        throw StateError('Les préférences locales ont changé. Réessayez.');
      }
      if (!mapEquals(expected, merged)) {
        await box.put(_key, jsonDecode(merged[_key]!));
      }
    });
  }
}
