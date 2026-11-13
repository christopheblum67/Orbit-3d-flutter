import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/strict_profile_data_reader.dart';

void main() {
  late Directory directory;
  const reader = StrictProfileDataReader();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('orbit_cloud_reader_');
    Hive.init(directory.path);
    await Hive.openBox('favorites');
    await Hive.openBox('recently_watched');
    await Hive.openBox('watched_episodes');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('reads the selected profile without hiding its corrupt entries',
      () async {
    final favorites = Hive.box('favorites');
    await favorites.put(
      'p1:live:1',
      jsonEncode({
        'profileId': 'p1',
        'type': 'live',
        'id': '1',
        'title': 'Chaîne',
        'streamUrl': 'https://example.test/secret',
      }),
    );
    await favorites.put('p2:live:2', '{corrupt');
    final entries = await reader.favorites('p1');
    expect(entries.single.streamUrl, 'https://example.test/secret');
    await favorites.put('p1:live:3', '{corrupt');
    await expectLater(reader.favorites('p1'), throwsFormatException);
  });

  test('rejects mismatched identities and malformed dates', () async {
    await Hive.box('recently_watched').put(
      'p1:live:1',
      jsonEncode({
        'profileId': 'p1',
        'type': 'live',
        'id': '1',
        'title': 'Chaîne',
        'watchedAt': 'invalid',
      }),
    );
    await expectLater(reader.recents('p1'), throwsFormatException);
    await Hive.box('watched_episodes').put(
      'p1:series:S1E1',
      jsonEncode({
        'profileId': 'other',
        'seriesId': 'series',
        'season': 1,
        'episodeNumber': 1,
        'watchedAt': DateTime.utc(2025).toIso8601String(),
      }),
    );
    await expectLater(reader.watchedEpisodes('p1'), throwsFormatException);
  });

  test('reads favorites with subscription-scoped keys', () async {
    const favorite = FavoriteEntry(
      profileId: 'p1',
      subscriptionId: 'sub:a',
      type: ContentType.vod,
      id: '1',
      title: 'Film',
    );
    await Hive.box('favorites')
        .put(favorite.key, jsonEncode(favorite.toJson()));
    expect(await reader.favorites('p1'), [favorite]);
  });
}
