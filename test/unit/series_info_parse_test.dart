import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/series.dart';

void main() {
  test('parses get_series_info payload for a series (real server fixture)', () {
    final raw = File('test/fixtures/series2.json').readAsStringSync();
    final data = jsonDecode(raw);
    Map<String, dynamic> root;
    if (data is List) {
      root = Map<String, dynamic>.from(data.first as Map);
    } else {
      root = Map<String, dynamic>.from(data as Map);
    }
    final info = root['info'];
    final stitched = Map<String, dynamic>.from(
      info is Map ? Map<String, dynamic>.from(info) : const <String, dynamic>{},
    );
    stitched['series_id'] = '2';
    final episodeMaps = <Map<String, dynamic>>[];
    final rawEpisodes = root['episodes'];
    if (rawEpisodes is Map) {
      for (final seasonEntry in rawEpisodes.entries) {
        final season = int.tryParse(seasonEntry.key.toString()) ?? 0;
        final list =
            seasonEntry.value is List ? seasonEntry.value as List : const [];
        for (final raw in list) {
          final em = Map<String, dynamic>.from(raw as Map);
          em['season'] = season;
          final id = em['id']?.toString() ?? '';
          em['url'] = id.isEmpty
              ? ''
              : 'https://draap.online/169503400638842/1593574628/$id';
          episodeMaps.add(em);
        }
      }
    }
    stitched['episodes'] = episodeMaps;

    final series = Series.fromMap(stitched);

    expect(series.id, '2');
    expect(series.title, 'The Rain');
    expect(series.episodes, isNotEmpty);
    expect(
      series.episodes.every((e) => e.streamUrl.isNotEmpty),
      isTrue,
    );
    final s1 = series.episodes.where((e) => e.season == 1).toList()
      ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    expect(s1, isNotEmpty);
    expect(s1.first.episodeNumber, 1);
  });
}
