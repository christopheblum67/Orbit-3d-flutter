import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_preferences_scope.dart';

void main() {
  test('checks for local changes and validates before applying', () async {
    final dir = await Directory.systemTemp.createTemp('orbit_cloud_prefs_');
    Hive.init(dir.path);
    final box = await Hive.openBox('settings');
    try {
      final scope = LocalPreferencesScope();
      final before = await scope.read();
      final updated = {
        'user_preferences':
            jsonEncode(const UserPreferences(language: 'en').toMap()),
      };
      await scope.applyIfUnchanged(before, updated, () {});
      expect((box.get('user_preferences') as Map)['language'], 'en');
      await expectLater(
        scope.applyIfUnchanged(before, updated, () {}),
        throwsStateError,
      );
      await expectLater(
        scope.applyIfUnchanged(updated, {'user_preferences': '{}'}, () {}),
        throwsFormatException,
      );
      expect((box.get('user_preferences') as Map)['language'], 'en');
    } finally {
      await Hive.close();
      await dir.delete(recursive: true);
    }
  });
}
