import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_profile_scope.dart';

void main() {
  test('updates only the selected profile and rejects invalid identities',
      () async {
    final dir = await Directory.systemTemp.createTemp('orbit_cloud_profile_');
    Hive.init(dir.path);
    final box = await Hive.openBox('profiles');
    try {
      UserProfile profile(String id, String name) => UserProfile(
            id: id,
            firstName: name,
            dateOfBirth: DateTime.utc(1990),
            gender: '',
            favoriteGenres: const [],
          );
      await box.putAll({
        'p1': profile('p1', 'Alice').toMap(),
        'p2': profile('p2', 'Bob').toMap(),
      });
      final scope = LocalProfileScope('p1');
      final before = await scope.read();
      await scope.applyIfUnchanged(
        before,
        {'p1': jsonEncode(profile('p1', 'Alicia').toMap())},
        () {},
      );
      expect((box.get('p1') as Map)['firstName'], 'Alicia');
      expect((box.get('p2') as Map)['firstName'], 'Bob');
      await expectLater(
        scope.applyIfUnchanged(
          before,
          {'p1': jsonEncode(profile('p1', 'New').toMap())},
          () {},
        ),
        throwsStateError,
      );
      await expectLater(
        scope.applyIfUnchanged(
          await scope.read(),
          {'p1': jsonEncode(profile('p2', 'Wrong').toMap())},
          () {},
        ),
        throwsFormatException,
      );
    } finally {
      await Hive.close();
      await dir.delete(recursive: true);
    }
  });
}
