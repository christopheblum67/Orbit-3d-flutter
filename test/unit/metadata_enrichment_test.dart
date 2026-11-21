import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/omdb_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';
import 'package:orbit_3d_flutter/services/tvmaze_service.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/movie_detail.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/series_detail.dart';
import 'package:orbit_3d_flutter/services/metadata_enrichment_service.dart';

class _MetadataTestApi extends ApiService {
  @override
  Future<Movie> fetchMovieDetail(Movie movie) async => movie;

  @override
  Future<MovieCredits?> fetchMovieCredits(String movieId) async => null;
}

class _MetadataTestTmdb extends TmdbService {
  _MetadataTestTmdb(this.detail);

  final MovieDetail detail;

  @override
  bool get hasApiKey => true;

  @override
  Future<int?> searchMovieId(
    String title, {
    int? year,
    String? language,
  }) async =>
      detail.tmdbId;

  @override
  Future<MovieDetail?> getMovieDetail(
    int tmdbId, {
    String? language,
  }) async =>
      detail;
}

class _SeriesTestTmdb extends TmdbService {
  _SeriesTestTmdb(this.detail);

  final SeriesDetail detail;
  final calls = <String>[];

  @override
  bool get hasApiKey => true;

  @override
  Future<int?> searchTvId(String title, {int? year, String? language}) async {
    calls.add('search');
    return 42;
  }

  @override
  Future<SeriesDetail?> getTvDetail(int tmdbId, {String? language}) async {
    calls.add('detail');
    return detail;
  }

  @override
  Future<Map<int, List<Actor>>?> getSeasonGuestStars(
    int tmdbId,
    List<int> seasonNumbers,
  ) async {
    calls.add('guests');
    return {};
  }
}

class _SeriesTestTvmaze extends TvmazeService {
  _SeriesTestTvmaze(this.detail, {this.fail = false});

  final SeriesDetail? detail;
  final bool fail;
  int searches = 0;

  @override
  Future<int?> searchShowId(String title) async {
    searches++;
    if (fail) throw StateError('TVmaze unavailable');
    return detail == null ? null : 12;
  }

  @override
  Future<SeriesDetail?> getShowDetail(int tvmazeId) async => detail;
}

class _SeriesTestOmdb extends OmdbService {
  int calls = 0;

  @override
  Future<SeriesDetail> fillMissingSeries(SeriesDetail detail) async {
    calls++;
    return detail;
  }
}

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory =
        await Directory.systemTemp.createTemp('metadata_enrichment_test');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  group('MovieDetail', () {
    final baseMovie = Movie(
      id: '123',
      title: 'Test Movie',
      description: 'A test movie',
      posterUrl: 'https://example.com/poster.jpg',
      year: 2023,
      genre: 'Action',
      director: 'John Director',
      rating: 7.5,
      pegi: '16',
      streamId: 'https://example.com/stream.mp4',
    );

    test('fromMovie creates MovieDetail with Xtream data', () {
      final detail = MovieDetail.fromMovie(baseMovie);

      expect(detail.id, '123');
      expect(detail.title, 'Test Movie');
      expect(detail.year, 2023);
      expect(detail.dataSource, 'xtream');
      expect(detail.aiGenerated, false);
    });

    test('copyWith preserves unchanged fields', () {
      final detail = MovieDetail.fromMovie(baseMovie);
      final updated = detail.copyWith(year: 2024, tmdbId: 550);

      expect(updated.year, 2024);
      expect(updated.tmdbId, 550);
      expect(updated.title, 'Test Movie');
      expect(updated.dataSource, 'xtream');
    });

    test('pegiLabel returns formatted label', () {
      final detail = MovieDetail.fromMovie(baseMovie);
      expect(detail.pegiLabel, isNotNull);
    });

    test('needsEnrichment detects missing critical fields', () {
      final minimalMovie = Movie(
        id: '1',
        title: 'Minimal',
        description: '',
        posterUrl: '',
        year: 0,
        genre: '',
        director: '',
        rating: 0,
        pegi: '',
        streamId: 'https://example.com/stream.mp4',
      );
      final detail = MovieDetail.fromMovie(minimalMovie);
      expect(detail.needsEnrichment, true);
    });

    test('TMDB localized synopsis replaces Xtream synopsis on the detail page',
        () async {
      final tmdbDetail = MovieDetail(
        id: '550',
        title: 'Test Movie',
        description: 'Synopsis français fourni par TMDB.',
        posterUrl: '',
        year: 2023,
        genre: 'Action',
        director: 'John Director',
        rating: 7.5,
        pegi: '',
        streamId: '',
        tmdbId: 550,
        imdbId: 'tt0000550',
        runtime: 120,
        cast: [
          Actor(
            id: '1',
            name: 'Test Actor',
            character: 'Hero',
            profilePath: '',
          ),
        ],
        originalLanguage: 'en',
        dataSource: 'tmdb',
      );
      final service = MetadataEnrichmentService(
        api: _MetadataTestApi(),
        tmdb: _MetadataTestTmdb(tmdbDetail),
        tvmaze: TvmazeService(),
        omdb: OmdbService(),
      );

      final result = await service.enrichMovie(baseMovie);

      expect(result.description, tmdbDetail.description);
      expect(result.dataSource, 'tmdb');
      expect(result.streamUrl, baseMovie.streamUrl);
      expect(result.cast.map((actor) => actor.name), ['Test Actor']);
    });
  });

  group('SeriesDetail', () {
    final baseSeries = Series(
      id: '456',
      title: 'Test Series',
      description: 'A test series',
      coverUrl: 'https://example.com/cover.jpg',
      year: 2022,
      genre: 'Drama',
      director: '',
      rating: 8.0,
      pegi: '16',
      episodes: [
        Episode(
          id: '1',
          title: 'Ep 1',
          season: 1,
          episodeNumber: 1,
          streamId: 'url1',
        ),
        Episode(
          id: '2',
          title: 'Ep 2',
          season: 1,
          episodeNumber: 2,
          streamId: 'url2',
        ),
        Episode(
          id: '3',
          title: 'Ep 3',
          season: 2,
          episodeNumber: 1,
          streamId: 'url3',
        ),
      ],
    );

    test('enriches M3U series with TVmaze and TMDB without changing episodes',
        () async {
      final tvmaze = _SeriesTestTvmaze(
        SeriesDetail.fromSeries(baseSeries).copyWith(
          description: 'The original English synopsis.',
          tvmazeId: 12,
          dataSource: 'tvmaze',
          cast: [Actor(id: '1', name: 'Actor', character: '', profilePath: '')],
        ),
      );
      final tmdb = _SeriesTestTmdb(
        SeriesDetail.fromSeries(baseSeries).copyWith(
          description: 'Le synopsis localisé de la série.',
          tmdbId: 42,
          genre: 'Mystery',
          runtime: 45,
          dataSource: 'tmdb',
        ),
      );
      final omdb = _SeriesTestOmdb();
      final service = MetadataEnrichmentService(
        api: _MetadataTestApi(),
        tmdb: tmdb,
        tvmaze: tvmaze,
        omdb: omdb,
      );

      final result = await service.enrichSeries(baseSeries);
      expect(tvmaze.searches, 1);
      expect(tmdb.calls, ['search', 'detail', 'guests']);
      expect(result.description, 'Le synopsis localisé de la série.');
      expect(result.tmdbId, 42);
      expect(result.tvmazeId, 12);
      expect(result.runtime, 45);
      expect(result.cast.single.name, 'Actor');
      expect(result.episodes, same(baseSeries.episodes));
      expect(result.id, baseSeries.id);
    });

    test('continues to TMDB when TVmaze fails', () async {
      final tvmaze = _SeriesTestTvmaze(null, fail: true);
      final tmdb = _SeriesTestTmdb(
        SeriesDetail.fromSeries(baseSeries).copyWith(
          description: 'Un synopsis TMDB.',
          tmdbId: 42,
          dataSource: 'tmdb',
        ),
      );
      final service = MetadataEnrichmentService(
        api: _MetadataTestApi(),
        tmdb: tmdb,
        tvmaze: tvmaze,
        omdb: _SeriesTestOmdb(),
      );

      final result = await service.enrichSeries(baseSeries);
      expect(result.description, 'Un synopsis TMDB.');
      expect(result.episodes, same(baseSeries.episodes));
      expect(tmdb.calls, contains('detail'));
    });

    test('fromSeries creates SeriesDetail with Xtream data', () {
      final detail = SeriesDetail.fromSeries(baseSeries);

      expect(detail.id, '456');
      expect(detail.title, 'Test Series');
      expect(detail.year, 2022);
      expect(detail.numberOfSeasons, 2);
      expect(detail.numberOfEpisodes, 3);
      expect(detail.dataSource, 'xtream');
    });

    test('copyWith preserves unchanged fields', () {
      final detail = SeriesDetail.fromSeries(baseSeries);
      final updated = detail.copyWith(tvmazeId: 12345, status: 'Ended');

      expect(updated.tvmazeId, 12345);
      expect(updated.status, 'Ended');
      expect(updated.title, 'Test Series');
    });

    test('getGuestStarsForSeason returns empty list for unknown season', () {
      final detail = SeriesDetail.fromSeries(baseSeries);
      expect(detail.getGuestStarsForSeason(99), isEmpty);
    });

    test('pegiLabel returns formatted label', () {
      final detail = SeriesDetail.fromSeries(baseSeries);
      expect(detail.pegiLabel, isNotNull);
    });
  });

  group('Avatar IA', () {
    test('avatarUrlFor est déterministe pour un même nom', () {
      final url1 = MetadataEnrichmentService.avatarUrlFor('Emma Stone');
      final url2 = MetadataEnrichmentService.avatarUrlFor('Emma Stone');
      expect(url1, url2);
      expect(url1, startsWith('https://i.pravatar.cc/300?img='));
    });

    test(
        'avatarUrlFor produit des portraits différents pour des noms différents',
        () {
      final a = MetadataEnrichmentService.avatarUrlFor('Emma Stone');
      final b = MetadataEnrichmentService.avatarUrlFor('Tom Cruise');
      expect(a, isNot(equals(b)));
    });

    test('avatarUrlFor normalise la casse (stable quel que soit l\'écriture)',
        () {
      expect(
        MetadataEnrichmentService.avatarUrlFor('Emma Stone'),
        MetadataEnrichmentService.avatarUrlFor('emma stone'),
      );
    });

    test('avatarUrlFor renvoie une URL vide pour un nom vide', () {
      expect(MetadataEnrichmentService.avatarUrlFor('   '), '');
    });

    test('avatarUrlFor reste dans la plage d\'images valides (1..70)', () {
      final url = MetadataEnrichmentService.avatarUrlFor('Helene Roldan');
      final imgArg = RegExp(r'img=(\d+)$').firstMatch(url);
      expect(imgArg, isNotNull);
      final img = int.parse(imgArg!.group(1)!);
      expect(img, inInclusiveRange(1, 70));
    });
  });

  group('Actor', () {
    test('fromMap parses TMDB format', () {
      final map = {
        'id': 123,
        'name': 'Test Actor',
        'character': 'Hero',
        'profile_path': '/abc123.jpg',
        'order': 1,
      };
      final actor = Actor.fromMap(map);

      expect(actor.id, '123');
      expect(actor.name, 'Test Actor');
      expect(actor.character, 'Hero');
      expect(actor.profilePath, '/abc123.jpg');
      expect(actor.order, 1);
      expect(actor.source, ActorSource.xtream); // default
    });

    test('fromMap detects guest star', () {
      final map = {
        'id': 456,
        'name': 'Guest Actor',
        'character': 'Cameo',
        'profile_path': '',
        'guest_star': true,
      };
      final actor = Actor.fromMap(map);
      expect(actor.isGuestStar, true);
    });

    test('profileUrl builds TMDB URL for relative paths', () {
      final actor = Actor(
        id: '1',
        name: 'Test',
        character: 'Role',
        profilePath: '/xyz.jpg',
      );
      expect(actor.profileUrl, 'https://image.tmdb.org/t/p/w185/xyz.jpg');
    });

    test('copyWith creates modified copy', () {
      final actor = Actor(
        id: '1',
        name: 'Original',
        character: 'Role',
        profilePath: '/path.jpg',
      );
      final updated = actor.copyWith(name: 'Updated', isGuestStar: true);

      expect(updated.name, 'Updated');
      expect(updated.isGuestStar, true);
      expect(updated.id, '1');
    });
  });
}
