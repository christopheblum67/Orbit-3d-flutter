import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/services/xtream_replay_mapper.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  final channel = Channel(
    id: '42',
    name: 'Channel',
    logoUrl: '',
    streamUrl: '',
    group: 'News',
  );
  Map<String, dynamic> entry(DateTime start, DateTime end, String title) => {
        'start_timestamp': start.millisecondsSinceEpoch ~/ 1000,
        'stop_timestamp': end.millisecondsSinceEpoch ~/ 1000,
        'title': title,
      };
  final older = entry(
    now.subtract(const Duration(hours: 5)),
    now.subtract(const Duration(hours: 4)),
    'Older',
  );
  final recent = entry(
    now.subtract(const Duration(hours: 2)),
    now.subtract(const Duration(hours: 1)),
    base64.encode(utf8.encode('Journal du soir')),
  )..addAll({
      'description': '  ',
      'plot': 'C&apos;est &lt;b&gt;important&lt;/b&gt;<br>suite',
      'presenter': 'Alex &amp; Kim',
    });

  List<ReplayItem> build(List<Map> entries, {required bool full}) =>
      const XtreamReplayMapper().build(
        entries: entries,
        channel: channel,
        now: now,
        window: const Duration(days: 2),
        fullGuide: full,
        buildUrl: (start, end) => '$start/$end',
        formatTime: (date, _) => date.toIso8601String(),
      );

  test('full guide filters boundaries, sorts, deduplicates and maps fields',
      () {
    final boundary = entry(
      now.subtract(const Duration(days: 2)),
      now.subtract(const Duration(days: 1, hours: 23)),
      'Boundary',
    );
    final old = entry(
      now.subtract(const Duration(days: 2, seconds: 1)),
      now.subtract(const Duration(days: 1)),
      'Old',
    );
    final unfinished =
        entry(now.subtract(const Duration(hours: 1)), now, 'Now');
    final future = entry(
      now.add(const Duration(hours: 1)),
      now.add(const Duration(hours: 2)),
      'Future',
    );
    final items = build(
      [older, recent, recent, old, unfinished, future, boundary],
      full: true,
    );
    expect(
      items.map((item) => item.title),
      ['Journal du soir', 'Older', 'Boundary'],
    );
    final item = items.first;
    expect(item.id, '42_${recent['start_timestamp']}');
    expect(
      item.streamUrl,
      '${recent['start_timestamp']}/${recent['stop_timestamp']}',
    );
    expect(item.description, "C'est important\nsuite");
    expect(item.host, 'Alex & Kim');
    expect(item.channelId, '42');
    expect(item.channelName, 'Channel');
    expect(item.categoryId, 'News');
    expect(item.startAt, now.subtract(const Duration(hours: 2)));
    expect(item.endAt, now.subtract(const Duration(hours: 1)));
    expect(item.startTime, item.startAt!.toIso8601String());
    expect(item.endTime, item.endAt!.toIso8601String());
  });

  test('short guide keeps input order and duplicates', () {
    final items = build([older, recent, recent], full: false);
    expect(
      items.map((item) => item.title),
      ['Older', 'Journal du soir', 'Journal du soir'],
    );
  });

  test('full guide accepts stop alias, unlike short guide', () {
    final alias = Map<String, dynamic>.from(older)
      ..['stop'] = older['stop_timestamp']
      ..remove('stop_timestamp');
    expect(build([alias], full: true), hasLength(1));
    expect(build([alias], full: false), isEmpty);
  });

  test('date aliases and field priorities differ only for stop', () {
    final withAliases = {
      'start': older['start_timestamp'],
      'stop': older['stop_timestamp'],
      'end': recent['stop_timestamp'],
      'title': 'Alias',
      'description': 'First',
      'plot': 'Second',
      'name': 'Host',
      'presenter': 'Other',
    };
    final full = build([withAliases], full: true).single;
    final short = build([withAliases], full: false).single;
    expect(full.endAt, now.subtract(const Duration(hours: 4)));
    expect(short.endAt, now.subtract(const Duration(hours: 1)));
    expect(full.description, 'First');
    expect(full.host, 'Host');
    final preferred = {
      ...withAliases,
      'start_timestamp': recent['start_timestamp'],
      'stop_timestamp': older['stop_timestamp'],
    };
    expect(
      build([preferred], full: true).single.startAt,
      now.subtract(const Duration(hours: 2)),
    );
    expect(build([preferred], full: false).single.endAt, full.endAt);
  });
}
