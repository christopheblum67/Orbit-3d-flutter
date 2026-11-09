import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Api extends ApiService {
  int shortCalls = 0;
  final List<EPGProgram> shortPrograms = [];

  @override
  Future<List<EPGProgram>> fetchChannelEpgPrograms(Channel channel) async {
    shortCalls++;
    return shortPrograms;
  }
}

class _GlobalCache extends EPGDataCache {
  int calls = 0;
  final loaded = Completer<List<EPGProgram>>();
  final Map<String, List<EPGProgram>> byChannel = {};

  @override
  Future<List<EPGProgram>> loadFull(
    ApiService api, {
    bool forceRefresh = false,
  }) {
    calls++;
    return loaded.future;
  }

  @override
  List<EPGProgram> programsForChannel(String channelId) =>
      byChannel[channelId] ?? [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final channel = Channel(
    id: '42',
    name: 'Channel',
    logoUrl: '',
    streamUrl: '',
    group: '',
    epgChannelId: 'num:42,epg',
  );
  EPGProgram program(String name) {
    final now = DateTime.now();
    return EPGProgram(
      channelId: 'epg',
      title: name,
      description: '',
      start: now,
      end: now.add(const Duration(hours: 1)),
    );
  }

  test('grid and player providers share the global guide without fallback',
      () async {
    final api = _Api();
    final global = _GlobalCache();
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(api),
        epgDataCacheProvider.overrideWithValue(global),
        liveChannelsProvider.overrideWith((ref) async => [channel]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(liveChannelsProvider.future);
    final grid =
        container.listen(channelEpgWindowProvider('num:42'), (_, __) {});
    final player = container.listen(channelEpgProvider('num:42'), (_, __) {});
    final gridFuture =
        container.read(channelEpgWindowProvider('num:42').future);
    final playerFuture = container.read(channelEpgProvider('num:42').future);
    global.byChannel['epg'] = [program('Global')];
    global.loaded.complete([]);
    expect((await gridFuture).single.title, 'Global');
    expect((await playerFuture).single.title, 'Global');
    expect(api.shortCalls, 0);
    expect(container.read(epgFallbackBudgetProvider).consumed, 0);
    grid.close();
    player.close();
  });

  test('disposed provider completes pending fallback without using its ref',
      () async {
    final api = _Api()..shortPrograms.add(program('Short'));
    final global = _GlobalCache();
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(api),
        epgDataCacheProvider.overrideWithValue(global),
        liveChannelsProvider.overrideWith((ref) async => [channel]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(liveChannelsProvider.future);
    final listener = container.listen(channelEpgProvider('num:42'), (_, __) {});
    final result = container.read(channelEpgProvider('num:42').future);
    expect(global.calls, 1);
    listener.close();
    await container.pump();
    global.loaded.complete([]);
    expect((await result).single.title, 'Short');
    expect(api.shortCalls, 1);
    expect(
      container.read(shortEpgCacheProvider).get('42')!.single.title,
      'Short',
    );
  });

  test('grid provider sorts cached programs without modifying the cache',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final early = program('Early');
    final late = EPGProgram(
      channelId: 'epg',
      title: 'Late',
      description: '',
      start: early.start.add(const Duration(hours: 1)),
      end: early.end.add(const Duration(hours: 1)),
    );
    container.read(shortEpgCacheProvider).put('42', [late, early]);
    final listener =
        container.listen(channelEpgWindowProvider('num:42'), (_, __) {});
    final programs =
        await container.read(channelEpgWindowProvider('num:42').future);
    expect(programs.map((p) => p.title), ['Early', 'Late']);
    expect(container.read(shortEpgCacheProvider).get('42')!.first.title, 'Late');
    listener.close();
  });
}
