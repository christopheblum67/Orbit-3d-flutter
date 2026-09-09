import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';

/// État réactif « épisodes déjà vus » : clé canonique
/// `"<profileId>:<seriesId>:S<saison>E<épisode>"` -> entrée.
///
/// Toute écriture (marquer vu, toggle) met à jour l'état ET persiste en Hive
/// via [WatchedEpisodesService]. Les widgets écoutent [watchedEpisodesProvider]
/// pour refléter le statut immédiatement (détail série, listes d'épisodes).
final watchedEpisodesProvider = StateNotifierProvider<
    WatchedEpisodesNotifier, Map<String, WatchedEpisodeEntry>>(
  (ref) => WatchedEpisodesNotifier(ref),
);

class WatchedEpisodesNotifier
    extends StateNotifier<Map<String, WatchedEpisodeEntry>> {
  final Ref _ref;

  /// Jeton incrémenté à chaque chargement : un chargement ne s'applique que
  /// s'il est le plus récent (évite qu'un profil A lointain écrase B).
  int _loadCallGen = 0;

  /// Jeton incrémenté à chaque écriture : un chargement en cours est ignoré
  /// s'il a été précédé d'une écriture (course load vs record/toggle).
  int _writeGen = 0;

  WatchedEpisodesNotifier(this._ref) : super(const {}) {
    _ref.listen(currentProfileProvider, (_, __) => _load());
    _load();
  }

  void _load() {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) {
      state = const {};
      return;
    }
    _loadForProfile(profile.id);
  }

  Future<void> _loadForProfile(String profileId) async {
    final call = ++_loadCallGen;
    final writeGen = _writeGen;
    final service = _ref.read(watchedEpisodesServiceProvider);
    final entries = await service.loadForProfile(profileId);
    if (call != _loadCallGen) return; // surclassé par un chargement plus récent
    if (writeGen != _writeGen) return; // écriture intervenue pendant le chargement
    state = {for (final e in entries) e.key: e};
  }

  bool isWatched(String seriesId, int season, int episodeNumber) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return false;
    final key = WatchedEpisodeEntry.keyFor(
      profileId: profile.id,
      seriesId: seriesId,
      season: season,
      episodeNumber: episodeNumber,
    );
    return state.containsKey(key);
  }

  /// Nombre d'épisodes vus pour une série (profil courant).
  int countForSeries(String seriesId) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return 0;
    return state.values
        .where((e) => e.profileId == profile.id && e.seriesId == seriesId)
        .length;
  }

  /// Nombre d'épisodes vus d'une saison donnée (profil courant).
  int countForSeason(String seriesId, int season) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return 0;
    return state.values.where(
      (e) =>
          e.profileId == profile.id &&
          e.seriesId == seriesId &&
          e.season == season,
    ).length;
  }

  /// Épisodes vus d'une série (profil courant), sans ordre garanti.
  List<WatchedEpisodeEntry> forSeries(String seriesId) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return const [];
    return state.values
        .where((e) => e.profileId == profile.id && e.seriesId == seriesId)
        .toList();
  }

  /// Marque l'épisode « vu » (appelé à la lecture : Démarrer/Reprendre).
  Future<void> record(Series series, Episode episode) async {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return;
    if (episode.episodeNumber <= 0 && episode.id.isEmpty) return;
    _writeGen++;
    final entry = _entryFor(series, episode, profile.id);
    final next = Map<String, WatchedEpisodeEntry>.from(state)..[entry.key] = entry;
    state = next;
    final service = _ref.read(watchedEpisodesServiceProvider);
    await service.save(entry);
  }

  /// Bascule vu / non-vu (toggle manuel depuis la liste d'épisodes).
  Future<void> toggle(Series series, Episode episode) async {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return;
    if (episode.episodeNumber <= 0 && episode.id.isEmpty) return;
    _writeGen++;
    final entry = _entryFor(series, episode, profile.id);
    final service = _ref.read(watchedEpisodesServiceProvider);
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

  /// Réinitialise la série (retire tous les « vu » du profil courant).
  Future<void> clearForSeries(String seriesId) async {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return;
    _writeGen++;
    final service = _ref.read(watchedEpisodesServiceProvider);
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