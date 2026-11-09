import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/profile_snapshot_capture.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

void main() {
  final profile = UserProfile(
    id: 'p1',
    firstName: 'Alex',
    dateOfBirth: DateTime.utc(1990),
    gender: '',
    favoriteGenres: [],
  );

  test('captures profile data without removing sensitive URLs', () async {
    final capture = ProfileSnapshotCapture(
      loadPreferences: () async => const UserPreferences(),
      loadFavorites: (id) async => [
        FavoriteEntry(
          id: '1',
          profileId: id,
          type: ContentType.live,
          title: 'Channel',
          streamUrl: 'https://example.test/secret',
        ),
      ],
      loadRecents: (_) async => [],
      loadWatchedEpisodes: (_) async => [],
      loadPlayback: (_) async => {
        'movie-1': const PlaybackProgress(
          positionMs: 100,
          durationMs: 500,
          updatedAt: 1,
        ),
      },
    );
    final result = await capture.capture(profile, revision: 3);
    expect(result.revision, 3);
    expect(result.profile['id'], 'p1');
    expect(result.favorites.single['streamUrl'], 'https://example.test/secret');
    expect(result.playback['movie-1']!['positionMs'], 100);
  });

  test('does not silently replace a failed data read with an empty list', () async {
    final capture = ProfileSnapshotCapture(
      loadPreferences: () async => const UserPreferences(),
      loadFavorites: (_) async => throw StateError('read failed'),
      loadRecents: (_) async => [],
      loadWatchedEpisodes: (_) async => [],
      loadPlayback: (_) async => {},
    );
    await expectLater(capture.capture(profile, revision: 0), throwsStateError);
  });
}
