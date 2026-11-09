import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recent_entry.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_profile_snapshot.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

/// Captures a local profile without changing it or uploading anything.
class ProfileSnapshotCapture {
  const ProfileSnapshotCapture({
    required this.loadPreferences,
    required this.loadFavorites,
    required this.loadRecents,
    required this.loadWatchedEpisodes,
    required this.loadPlayback,
  });

  final Future<UserPreferences> Function() loadPreferences;
  final Future<List<FavoriteEntry>> Function(String profileId) loadFavorites;
  final Future<List<RecentEntry>> Function(String profileId) loadRecents;
  final Future<List<WatchedEpisodeEntry>> Function(String profileId)
      loadWatchedEpisodes;
  final Future<Map<String, PlaybackProgress>> Function(String profileId)
      loadPlayback;

  Future<ProfileDataSnapshot> capture(
    UserProfile profile, {
    required int revision,
  }) async {
    final preferences = await loadPreferences();
    final favorites = await loadFavorites(profile.id);
    final recents = await loadRecents(profile.id);
    final watched = await loadWatchedEpisodes(profile.id);
    final playback = await loadPlayback(profile.id);
    return ProfileDataSnapshot(
      profileId: profile.id,
      revision: revision,
      profile: profile.toMap(),
      preferences: preferences.toMap(),
      favorites: favorites.map((entry) => entry.toJson()).toList(),
      recents: recents.map((entry) => entry.toJson()).toList(),
      watchedEpisodes: watched.map((entry) => entry.toJson()).toList(),
      playback: {
        for (final entry in playback.entries) entry.key: entry.value.toJson(),
      },
    );
  }
}
