import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/channel_epg_resolver.dart';
import 'package:orbit_3d_flutter/services/epg_fallback_budget.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  EPGProgram program(String name, int hours) => EPGProgram(
        channelId: 'epg',
        title: name,
        description: '',
        start: now.add(Duration(hours: hours)),
        end: now.add(Duration(hours: hours + 1)),
      );
  final channel = Channel(
    id: '42',
    name: 'Channel',
    logoUrl: '',
    streamUrl: '',
    group: '',
    epgChannelId: 'num:42,epg',
  );
  const resolver = ChannelEpgResolver();
  late ShortEpgCache cache;
  late EpgFallbackBudget budget;
  late List<String> calls;
  late Map<String, List<EPGProgram>> global;
  late List<EPGProgram> short;

  setUp(() {
    cache = ShortEpgCache();
    budget = EpgFallbackBudget();
    calls = [];
    global = {};
    short = [];
  });

  ChannelEpgSources sources() {
    calls.add('prepare');
    return ChannelEpgSources(
      channels: [channel],
      budget: budget,
      loadFull: () async => calls.add('global'),
      programsForChannel: (id) {
        calls.add('lookup:$id');
        return global[id] ?? [];
      },
      fetchShort: (channel) async {
        calls.add('short:${channel.id}');
        return short;
      },
    );
  }

  Future<List<EPGProgram>> resolve({
    String id = 'num:42',
    bool includePast = false,
    bool fallback = true,
  }) =>
      resolver.resolve(
        channelId: id,
        includePast: includePast,
        allowNetworkFallback: fallback,
        cache: cache,
        prepareSources: sources,
        now: now,
      );

  test('prefixed cache hit is sorted without mutating immutable cache',
      () async {
    cache.put(
      '42',
      [program('later', 2), program('past', -2), program('now', 0)],
    );
    final result = await resolve(includePast: true);
    expect(result.map((p) => p.title), ['past', 'now', 'later']);
    expect(cache.get('42')!.map((p) => p.title), ['later', 'past', 'now']);
    expect(calls, isEmpty);
  });

  test('empty identifier does not prepare dependencies', () async {
    expect(await resolve(id: ''), isEmpty);
    expect(calls, isEmpty);
  });

  test('global guide precedes fallback, tries aliases and filters past',
      () async {
    global['epg'] = [
      program('later', 2),
      program('past', -2),
      program('now', 0),
    ];
    expect((await resolve()).map((p) => p.title), ['now', 'later']);
    expect(calls, ['prepare', 'global', 'lookup:num:42', 'lookup:epg']);
    expect(budget.consumed, 0);
  });

  test('grid never requests short EPG or consumes the shared budget', () async {
    short = [program('now', 0)];
    expect(await resolve(includePast: true, fallback: false), isEmpty);
    expect(
      calls,
      ['prepare', 'global', 'lookup:num:42', 'lookup:epg', 'lookup:42'],
    );
    expect(budget.consumed, 0);
  });

  test('fallback consumes budget, caches result and is reused', () async {
    short = [program('later', 2), program('now', 0)];
    expect((await resolve()).map((p) => p.title), ['now', 'later']);
    expect(calls.last, 'short:42');
    expect(budget.consumed, 1);
    calls.clear();
    expect((await resolve()).map((p) => p.title), ['now', 'later']);
    expect(calls, isEmpty);
    expect(budget.consumed, 1);
  });

  test('exhausted budget does not start fallback', () async {
    for (var i = 0; i < EpgFallbackBudget.maxRequests; i++) {
      budget.tryConsume();
    }
    expect(await resolve(), isEmpty);
    expect(calls.where((call) => call.startsWith('short:')), isEmpty);
    expect(budget.consumed, EpgFallbackBudget.maxRequests);
  });
}
