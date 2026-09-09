import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/watched_episode.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/services/watched_episodes_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('watched_episodes_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  final profile = UserProfile(
    id: 'test_profile',
    firstName: 'Test',
    dateOfBirth: DateTime(2000, 1, 1),
    gender: 'male',
    favoriteGenres: const [],
  );

  Episode episodeOf(int season, int number, {String id = ''}) => Episode(
        id: id,
        title: 'Épisode $number',
        season: season,
        episodeNumber: number,
        streamUrl: 'http://cdn/series/1/s$season/e$number.ts',
      );

  Series seriesOf(int id, {List<Episode> episodes = const []}) => Series(
        id: 'sr$id',
        title: 'Série $id',
        description: '',
        coverUrl: '',
        year: 2020,
        genre: '',
        director: '',
        rating: 0,
        pegi: '',
        episodes: episodes,
      );

  group('WatchedEpisodesService', () {
    late WatchedEpisodesService service;

    setUp(() async {
      service = WatchedEpisodesService();
      await service.init();
    });

    test('round-trip save / loadAll', () async {
      final entry = WatchedEpisodeEntry(
        profileId: 'test_profile',
        seriesId: 'sr1',
        seriesTitle: 'Série 1',
        episodeId: '1',
        episodeTitle: 'Épisode 1',
        season: 1,
        episodeNumber: 1,
        watchedAt: DateTime(2026, 1, 1),
      );
      await service.save(entry);

      final all = await service.loadAll();
      expect(all, [entry]);
    });

    test('isWatched par clé canonique "profile:series:S<E"', () async {
      expect(
        await service.isWatched('test_profile:sr1:S1E1'),
        isFalse,
      );

      await service.save(
        WatchedEpisodeEntry(
          profileId: 'test_profile',
          seriesId: 'sr1',
          seriesTitle: 'Série 1',
          episodeId: '',
          episodeTitle: 'Épisode 1',
          season: 1,
          episodeNumber: 1,
          watchedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(await service.isWatched('test_profile:sr1:S1E1'), isTrue);
      expect(await service.isWatched('test_profile:sr1:S1E2'), isFalse);
    });

    test('remove ne supprime que la clé visée', () async {
      await service.save(
        WatchedEpisodeEntry(
          profileId: 'test_profile',
          seriesId: 'sr1',
          seriesTitle: 'Série 1',
          episodeId: '',
          episodeTitle: 'E1',
          season: 1,
          episodeNumber: 1,
          watchedAt: DateTime(2026, 1, 1),
        ),
      );
      await service.save(
        WatchedEpisodeEntry(
          profileId: 'test_profile',
          seriesId: 'sr1',
          seriesTitle: 'Série 1',
          episodeId: '',
          episodeTitle: 'E2',
          season: 1,
          episodeNumber: 2,
          watchedAt: DateTime(2026, 1, 2),
        ),
      );

      await service.remove('test_profile:sr1:S1E1');

      expect(await service.isWatched('test_profile:sr1:S1E1'), isFalse);
      expect(await service.isWatched('test_profile:sr1:S1E2'), isTrue);
      expect((await service.loadAll()).length, 1);
    });

    test('ignore les entrées corrompues ou non-mapping', () async {
      final box = Hive.box<String>('watched_episodes');
      await box.put('test_profile:sr1:S1E1', 'pas du json');
      await box.put('test_profile:sr1:S1E2', '[1, 2, 3]');
      await box.put(
        'test_profile:sr1:S1E3',
        '{"profileId":"test_profile","seriesId":"sr1","seriesTitle":"Série 1",'
        '"episodeId":"","episodeTitle":"Bonus","season":1,"episodeNumber":3,'
        '"watchedAt":"2026-01-01T00:00:00.000"}',
      );

      final all = await service.loadAll();
      expect(all.length, 1);
      expect(all.single.episodeNumber, 3);
    });
  });

  group('WatchedEpisodesNotifier (réactivité)', () {
    test('toggle ajoute puis retire, et persiste en Hive', () async {
      final service = WatchedEpisodesService();
      await service.init();
      await service.save(
        WatchedEpisodeEntry(
          profileId: 'test_profile',
          seriesId: 'sr1',
          seriesTitle: 'Série 1',
          episodeId: '',
          episodeTitle: 'E1',
          season: 1,
          episodeNumber: 1,
          watchedAt: DateTime(2026, 1, 1),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          watchedEpisodesServiceProvider.overrideWithValue(service),
          currentProfileProvider.overrideWith((ref) => profile),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(watchedEpisodesProvider.notifier);

      // Attend la fin du chargement initial asynchrone.
      for (var i = 0;
          i < 100 && !notifier.isWatched('sr1', 1, 1);
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(notifier.isWatched('sr1', 1, 1), isTrue);
      expect(notifier.countForSeason('sr1', 1), 1);

      await notifier.toggle(seriesOf(1), episodeOf(1, 1));

      expect(notifier.isWatched('sr1', 1, 1), isFalse);
      expect(await service.isWatched('test_profile:sr1:S1E1'), isFalse);

      await notifier.toggle(seriesOf(1), episodeOf(1, 1));

      expect(notifier.isWatched('sr1', 1, 1), isTrue);
      expect(await service.isWatched('test_profile:sr1:S1E1'), isTrue);
    });

    test('countForSeries et forSeries sont sélectifs par série/saison', () async {
      final service = WatchedEpisodesService();
      await service.init();

      final container = ProviderContainer(
        overrides: [
          watchedEpisodesServiceProvider.overrideWithValue(service),
          currentProfileProvider.overrideWith((ref) => profile),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(watchedEpisodesProvider.notifier);
      for (var i = 0;
          i < 100 && notifier.countForSeries('sr1') != 0;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await notifier.record(seriesOf(1), episodeOf(1, 1));
      await notifier.record(seriesOf(1), episodeOf(1, 2));
      await notifier.record(seriesOf(1), episodeOf(2, 1));
      await notifier.record(seriesOf(2), episodeOf(1, 1));

      expect(notifier.countForSeries('sr1'), 3);
      expect(notifier.countForSeason('sr1', 1), 2);
      expect(notifier.countForSeason('sr1', 2), 1);
      expect(notifier.countForSeries('sr2'), 1);
      expect(notifier.forSeries('sr1').length, 3);
    });

    test('clearForSeries ne touche que la série (et le profil courant)', () async {
      final service = WatchedEpisodesService();
      await service.init();

      final container = ProviderContainer(
        overrides: [
          watchedEpisodesServiceProvider.overrideWithValue(service),
          currentProfileProvider.overrideWith((ref) => profile),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(watchedEpisodesProvider.notifier);
      for (var i = 0;
          i < 100 && notifier.countForSeries('sr1') != 0;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await notifier.record(seriesOf(1), episodeOf(1, 1));
      await notifier.record(seriesOf(1), episodeOf(1, 2));
      await notifier.record(seriesOf(2), episodeOf(1, 1));
      // Un autre profil : ne doit pas être affecté.
      await service.save(
        WatchedEpisodeEntry(
          profileId: 'autre',
          seriesId: 'sr1',
          seriesTitle: 'Série 1',
          episodeId: '',
          episodeTitle: 'E1',
          season: 1,
          episodeNumber: 1,
          watchedAt: DateTime(2026, 1, 1),
        ),
      );

      await notifier.clearForSeries('sr1');

      expect(notifier.countForSeries('sr1'), 0);
      expect(notifier.countForSeries('sr2'), 1);
      // Persistence : seule la clé du profil courant a été retirée.
      expect(await service.isWatched('test_profile:sr1:S1E1'), isFalse);
      expect(await service.isWatched('test_profile:sr2:S1E1'), isTrue);
      expect(await service.isWatched('autre:sr1:S1E1'), isTrue);
    });
  });
}