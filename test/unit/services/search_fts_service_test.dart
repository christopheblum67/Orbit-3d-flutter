import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/search_fts_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Movie movie(String id, String title, String poster) => Movie(
      id: id,
      title: title,
      description: '',
      posterUrl: poster,
      year: 2000,
      genre: '',
      director: '',
      rating: 0,
      pegi: '',
      streamId: id,
      containerExtension: 'mp4',
    );

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late SearchFtsService fts;
  const series = <Series>[];
  const channels = <Channel>[];

  setUp(() => fts = SearchFtsService.forTesting(inMemoryDatabasePath));
  tearDown(() => fts.close());

  test('refreshes posters and removes items when the catalogue changes',
      () async {
    final old = [movie('1', 'Matrix', 'old'), movie('2', 'Matrix Two', 'two')];
    final current = [movie('1', 'Matrix', 'new')];

    Future<List<SearchFtsHit>> search(List<Movie> movies) =>
        fts.searchCatalogue(
          subscriptionId: 'account-a',
          movies: movies,
          series: series,
          channels: channels,
          query: 'matrix',
        );

    expect((await search(old)).map((hit) => hit.posterUrl), contains('old'));
    final hits = await search(current);
    expect(hits, hasLength(1));
    expect(hits.single.posterUrl, 'new');
    expect(hits.single.toSearchItem().originalObject, same(current.single));
  });

  test('serializes overlapping searches across subscriptions', () async {
    final a = [movie('1', 'Matrix A', 'account-a')];
    final b = [movie('1', 'Matrix B', 'account-b')];
    Future<List<SearchFtsHit>> search(String account, List<Movie> movies) =>
        fts.searchCatalogue(
          subscriptionId: account,
          movies: movies,
          series: series,
          channels: channels,
          query: 'matrix',
        );

    final results = await Future.wait([
      search('a', a),
      search('b', b),
      search('a', a),
    ]);
    expect(
      results.map((hits) => hits.single.posterUrl),
      ['account-a', 'account-b', 'account-a'],
    );
    expect(results.last.single.originalObject, same(a.single));
  });

  test('indexes all entries across multiple insertion batches', () async {
    final movies = [
      for (var i = 0; i < 1001; i++) movie('$i', 'Movie $i', 'poster'),
    ];
    await fts.searchCatalogue(
      subscriptionId: 'account',
      movies: movies,
      series: series,
      channels: channels,
      query: 'movie',
    );
    expect(await fts.count, 1001);
  });

  test('quotes FTS punctuation rather than interpreting it as syntax',
      () async {
    final hits = await fts.searchCatalogue(
      subscriptionId: 'account',
      movies: [movie('1', 'Spider-Man', 'poster')],
      series: series,
      channels: channels,
      query: 'spider-man',
    );
    expect(hits.single.title, 'Spider-Man');
  });
}
