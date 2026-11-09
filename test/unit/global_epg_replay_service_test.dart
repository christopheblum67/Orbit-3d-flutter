import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/global_epg_replay_service.dart';

void main() {
  test('builds eligible programs with aliases, retention and deduplication',
      () {
    final now = DateTime.now();
    final channel = Channel(
      id: '42',
      name: 'France',
      group: 'TV',
      logoUrl: '',
      streamUrl: 'https://example.test/live',
      epgChannelId: 'fr, 1:42',
      supportsReplay: true,
      archiveDays: 7,
    );
    final unsupported = Channel(
      id: '50',
      name: 'Other',
      group: 'TV',
      logoUrl: '',
      streamUrl: 'https://example.test/other',
    );
    EPGProgram program(
      String id,
      DateTime start,
      DateTime end, {
      String title = ' Journal ',
    }) =>
        EPGProgram(
          channelId: id,
          title: title,
          description: ' Résumé ',
          start: start,
          end: end,
        );
    final start = now.subtract(const Duration(days: 3));
    final end = start.add(const Duration(hours: 1));
    final results = const GlobalEpgReplayService().build(
      programs: [
        program('fr', start, end),
        program('1:42', start, end),
        program('42', now.subtract(const Duration(days: 8)), end),
        program('50', start, end),
        program('fr', now.subtract(const Duration(minutes: 5)),
            now.add(const Duration(minutes: 5))),
        program('fr', start.add(const Duration(hours: 2)),
            end.add(const Duration(hours: 2)),
            title: '  '),
      ],
      channels: [channel, unsupported],
      now: now,
      archiveWindow: (channel) => Duration(days: channel.archiveDays),
      formatTime: (date, _) => date.toIso8601String(),
      buildUrl: (channel, startEpoch, endEpoch) =>
          '${channel.id}/$startEpoch/$endEpoch',
    );
    expect(results, hasLength(1));
    final item = results.single;
    expect(item.channelId, '42');
    expect(item.title, 'Journal');
    expect(item.description, 'Résumé');
    expect(item.startAt, start);
    expect(item.endAt, end);
    expect(item.categoryId, 'TV');
    expect(item.streamUrl,
        '42/${start.millisecondsSinceEpoch ~/ 1000}/${end.millisecondsSinceEpoch ~/ 1000}');
  });

  test('returns an empty list when there are no replayable channels', () {
    final result = const GlobalEpgReplayService().build(
      programs: [],
      channels: [],
      now: DateTime.now(),
      archiveWindow: (_) => const Duration(days: 2),
      formatTime: (_, __) => '',
      buildUrl: (_, __, ___) => '',
    );
    expect(result, isEmpty);
  });
}
