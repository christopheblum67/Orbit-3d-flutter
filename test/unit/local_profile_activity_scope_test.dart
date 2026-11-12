import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/local_profile_activity_scope.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_cloud_activity_');
    Hive.init(dir.path);
    await Hive.openBox('favorites');
    await Hive.openBox('playback_progress');
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  String favorite(String profile, String id) => jsonEncode(
        FavoriteEntry(
          id: id,
          title: 'Title',
          profileId: profile,
          type: ContentType.live,
        ).toJson(),
      );

  test('applies only the selected profile and rejects stale local state',
      () async {
    final box = Hive.box('favorites');
    final scope =
        LocalProfileActivityScope('p1', ProfileActivityKind.favorites);
    await box.putAll({
      'p1:live:1': favorite('p1', '1'),
      'p2:live:2': favorite('p2', '2'),
    });
    final original = await scope.read();
    await scope.applyIfUnchanged(
      original,
      {'p1:live:3': favorite('p1', '3')},
      () {},
    );
    expect(box.get('p2:live:2'), favorite('p2', '2'));
    expect(box.containsKey('p1:live:1'), isFalse);
    expect(box.containsKey('p1:live:3'), isTrue);
    await expectLater(
      scope.applyIfUnchanged(original, {}, () {}),
      throwsStateError,
    );
    expect(box.containsKey('p1:live:3'), isTrue);
  });

  test('refuses another profile or malformed progress before any write',
      () async {
    final scope =
        LocalProfileActivityScope('p1', ProfileActivityKind.favorites);
    final invalid = {'p1:live:1': favorite('p2', '1')};
    await expectLater(
      scope.applyIfUnchanged({}, invalid, () {}),
      throwsFormatException,
    );
    expect(Hive.box('favorites').isEmpty, isTrue);
    final playback =
        LocalProfileActivityScope('p1', ProfileActivityKind.playback);
    await expectLater(
      playback.applyIfUnchanged({}, {'movie-1': '12|invalid|1'}, () {}),
      throwsFormatException,
    );
  });

  test('detects an edit made while waiting for the box lock', () async {
    final scope =
        LocalProfileActivityScope('p1', ProfileActivityKind.favorites);
    final old = {'p1:live:1': favorite('p1', '1')};
    await Hive.box('favorites').putAll(old);
    await HiveSync.writeAsync(
      'favorites',
      (box) => box.put('p1:live:2', favorite('p1', '2')),
    );
    await expectLater(scope.applyIfUnchanged(old, {}, () {}), throwsStateError);
    expect((await scope.read()).length, 2);
  });
}
