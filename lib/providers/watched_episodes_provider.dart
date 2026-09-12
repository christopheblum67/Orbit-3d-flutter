import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';

/// Ã‰tat rÃ©actif Â« Ã©pisodes dÃ©jÃ  vus Â» : clÃ© canonique
/// `"<profileId>:<seriesId>:S<saison>E<Ã©pisode>"` -> entrÃ©e.
///
/// Toute Ã©criture (marquer vu, toggle) met Ã  jour l'Ã©tat ET persiste en Hive
/// via [WatchedEpisodesService]. Les widgets Ã©coutent [watchedEpisodesProvider]
/// pour reflÃ©ter le statut immÃ©diatement (dÃ©tail sÃ©rie, listes d'Ã©pisodes).
final watchedEpisodesProvider =
    NotifierProvider<WatchedEpisodesNotifier, Map<String, WatchedEpisodeEntry>>(
  WatchedEpisodesNotifier.new,
);

class WatchedEpisodesNotifier
    extends Notifier<Map<String, WatchedEpisodeEntry>> {
  /// Jeton incrÃ©mentÃ© Ã  chaque chargement : un chargement ne s'applique que
  /// s'il est le plus rÃ©cent (Ã©vite qu'un profil A lointain Ã©crase B).
  int _loadCallGen = 0;

  /// Jeton incrÃ©mentÃ© Ã  chaque Ã©criture : un chargement en cours est ignorÃ©
  /// s'il a Ã©tÃ© prÃ©cÃ©dÃ© d'une Ã©criture (course load vs record/toggle).
  int _writeGen = 0;

  @override
  Map<String, WatchedEpisodeEntry> build() {
    ref.listen(currentProfileProvider, (_, __) => _load());
    _load();
    return const {};
  }

  void _load() {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      state = const {};
      return;
    }
    _loadForProfile(profile.id);
  }

  Future<void> _loadForProfile(String profileId) async {
    final call = ++_loadCallGen;
    final writeGen = _writeGen;
    final service = ref.read(watchedEpisodesServiceProvider);
    final entries = await service.loadForProfile(profileId);
    if (call != _loadCallGen) return; // surclassÃ© par un chargement plus rÃ©cent
    if (writeGen != _writeGen) return; // Ã©criture intervenue pendant le chargement
    if (!ref.mounted) return;
    state = {for (final e in entries) e.key: e};
  }

  bool isWatched(String seriesId, int season, int episodeNumber) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return false;
    final key = WatchedEpisodeEntry.keyFor(
      profileId: profile.id,
      seriesId: seriesId,
      season: season,
      episodeNumber: episodeNumber,
    );
    return state.containsKey(key);
  }

  /// Nombre d'Ã©pisodes vus pour une sÃ©rie (profil courant).
  int countForSeries(String seriesId) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return 0;
    return state.values
        .where((e) => e.profileId == profile.id && e.seriesId == seriesId)
        .length;
  }

  /// Nombre d'Ã©pisodes vus d'une saison donnÃ©e (profil courant).
  int countForSeason(String seriesId, int season) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return 0;
    return state.values.where(
      (e) =>
          e.profileId == profile.id &&
          e.seriesId == seriesId &&
          e.season == season,
    ).length;
  }

  /// Ã‰pisodes vus d'une sÃ©rie (profil courant), sans ordre garanti.
  List<WatchedEpisodeEntry> forSeries(String seriesId) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return const [];
    return state.values
        .where((e) => e.profileId == profile.id && e.seriesId == seriesId)
        .toList();
  }

  /// Marque l'Ã©pisode Â« vu Â» (appelÃ© Ã  la lecture : DÃ©marrer/Reprendre).
  Future<void> record(Series series, Episode episode) async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    if (episode.episodeNumber <= 0 && episode.id.isEmpty) return;
    _writeGen++;
    final entry = _entryFor(series, episode, profile.id);
    final next = Map<String, WatchedEpisodeEntry>.from(state)..[entry.key] = entry;
    state = next;
    final service = ref.read(watchedEpisodesServiceProvider);
    await service.save(entry);
  }

  /// Bascule vu / non-vu (toggle manuel depuis la liste d'Ã©pisodes).
  Future<void> toggle(Series series, Episode episode) async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    if (episode.episodeNumber <= 0 && episode.id.isEmpty) return;
    _writeGen++;
    final entry = _entryFor(series, episode, profile.id);
    final service = ref.read(watchedEpisodesServiceProvider);
    if (state.containsKey(entry.key)) {
      final next = Map<String, WatchedEpisodeEntry>.from(state)..remove(entry.key);
      state = next;
      await service.remove(entry.key);
    } else {
      final next = Map<String, WatchedEpisodeEntry>.from(state)..[entry.key] = entry;
      state = next;
      await service.save(entry);
    }
  }

  /// RÃ©initialise la sÃ©rie (retire tous les Â« vu Â» du profil courant).
  Future<void> clearForSeries(String seriesId) async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    _writeGen++;
    final service = ref.read(watchedEpisodesServiceProvider);
    for (final entry in forSeries(seriesId)) {
      await service.remove(entry.key);
    }
    final next = Map<String, WatchedEpisodeEntry>.from(state)
      ..removeWhere((_, e) => e.seriesId == seriesId && e.profileId == profile.id);
    state = next;
  }

  WatchedEpisodeEntry _entryFor(
    Series series,
    Episode episode,
    String profileId,
  ) {
    return WatchedEpisodeEntry(
      profileId: profileId,
      seriesId: series.id,
      seriesTitle: series.title,
      episodeId: episode.id,
      episodeTitle: episode.title,
      season: episode.season,
      episodeNumber: episode.episodeNumber,
      watchedAt: DateTime.now(),
    );
  }
}