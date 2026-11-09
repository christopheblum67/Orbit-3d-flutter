import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/services/replay_selection.dart';

Channel channel(String id, String group) => Channel(
      id: id,
      name: id,
      logoUrl: '',
      streamUrl: 'https://example.test/$id',
      group: group,
    );

ReplayItem replay(String id, String channelId, DateTime start,
        {bool useStartDate = false}) =>
    ReplayItem(
      id: id,
      title: id,
      streamUrl: 'https://example.test/$id',
      startTime: '',
      endTime: '',
      channelId: channelId,
      startAt: useStartDate ? null : start,
      startDate: useStartDate ? start : null,
    );

void main() {
  test('merge prefers global EPG and keeps other channels and times', () {
    final start = DateTime.utc(2026, 11, 9);
    final global = replay('global', 'a', start);
    final duplicate = replay('short', 'a', start, useStartDate: true);
    final otherChannel = replay('other', 'b', start);
    final later = replay('later', 'a', start.add(const Duration(hours: 1)));
    expect(
      ReplaySelection.merge([global], [duplicate, otherChannel, later]),
      [global, otherChannel, later],
    );
  });

  test('probe selection shares group limits across priority and fallback', () {
    final flagged = [channel('1', 'A'), channel('2', 'B')];
    final all = [
      ...flagged,
      channel('3', 'A'),
      channel('4', 'A'),
      channel('5', 'A'),
      channel('6', 'B'),
      channel('7', 'B'),
    ];
    expect(
      ReplaySelection.probeSet(all, flagged).map((c) => c.id).toList(),
      ['1', '2', '3', '6', '4', '7'],
    );
    expect(ReplaySelection.probeSet([], []), isEmpty);
  });
}
