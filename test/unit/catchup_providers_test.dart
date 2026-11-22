import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/catchup_providers.dart' as split;
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Api extends ApiService {
  int calls = 0;
  final started = Completer<void>();
  final pending = Completer<List<EPGProgram>>();

  @override
  Future<List<EPGProgram>> fetchChannelCatchUpPrograms(Channel channel) {
    calls++;
    if (!started.isCompleted) started.complete();
    return pending.future;
  }
}

Channel _channel(String id, {int days = 0}) => Channel(
      id: id,
      name: id,
      logoUrl: '',
      streamUrl: '',
      group: '',
      archiveDays: days,
    );

EPGProgram _program(String title, Duration ago) {
  final end = DateTime.now().subtract(ago);
  return EPGProgram(
    channelId: '1',
    title: title,
    description: '',
    start: end.subtract(const Duration(hours: 1)),
    end: end,
  );
}

void main() {
  test('facade exports the same catch-up provider', () {
    expect(public.channelCatchUpProvider, same(split.channelCatchUpProvider));
    expect(public.catchUpEpgCacheProvider, same(split.catchUpEpgCacheProvider));
  });

  test('cached programs use channel window, sort and leave cache untouched',
      () async {
    final api = _Api();
    final channel = _channel('1', days: 2);
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWith((ref) => null),
        public.liveChannelsProvider.overrideWith((ref) async => [channel]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(public.liveChannelsProvider.future);
    final cache = container.read(public.catchUpEpgCacheProvider);
    final shortCache = container.read(public.shortEpgCacheProvider);
    shortCache.put('1', [_program('short only', const Duration(hours: 1))]);
    cache.put('1', [
      _program('older', const Duration(days: 1, hours: 23)),
      _program('future', const Duration(hours: -1)),
      _program('expired', const Duration(days: 3, hours: 1)),
      _program('recent', const Duration(hours: 1)),
    ]);
    final listener =
        container.listen(public.channelCatchUpProvider('1'), (_, __) {});
    addTearDown(listener.close);
    final result =
        await container.read(public.channelCatchUpProvider('1').future);
    expect(result.map((p) => p.title), ['recent', 'older']);
    expect(
      cache.get('1')!.map((p) => p.title),
      ['older', 'future', 'expired', 'recent'],
    );
    expect(shortCache.get('1')!.single.title, 'short only');
    expect(api.calls, 0);
  });

  test('default window is fourteen days; unknown channels make no request',
      () async {
    final api = _Api();
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWith((ref) => null),
        public.liveChannelsProvider
            .overrideWith((ref) async => [_channel('1')]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(public.liveChannelsProvider.future);
    container.read(public.catchUpEpgCacheProvider).put('1', [
      _program('inside', const Duration(days: 13, hours: 1)),
      _program('outside', const Duration(days: 14, hours: 1)),
    ]);
    final valid =
        container.listen(public.channelCatchUpProvider('1'), (_, __) {});
    final missing =
        container.listen(public.channelCatchUpProvider('missing'), (_, __) {});
    final empty =
        container.listen(public.channelCatchUpProvider(''), (_, __) {});
    addTearDown(valid.close);
    addTearDown(missing.close);
    addTearDown(empty.close);
    expect(
      (await container.read(public.channelCatchUpProvider('1').future))
          .map((p) => p.title),
      ['inside'],
    );
    expect(
      await container.read(public.channelCatchUpProvider('missing').future),
      isEmpty,
    );
    expect(
      await container.read(public.channelCatchUpProvider('').future),
      isEmpty,
    );
    expect(api.calls, 0);
  });

  test('full archive request waits for channels and caches its result',
      () async {
    final api = _Api();
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWith((ref) => null),
        public.liveChannelsProvider
            .overrideWith((ref) async => [_channel('1')]),
      ],
    );
    addTearDown(container.dispose);
    final listener =
        container.listen(public.channelCatchUpProvider('1'), (_, __) {});
    addTearDown(listener.close);
    final result = container.read(public.channelCatchUpProvider('1').future);
    await api.started.future;
    expect(api.calls, 1);
    api.pending.complete([_program('recorded', const Duration(hours: 1))]);
    expect((await result).single.title, 'recorded');
    expect(
      container.read(public.catchUpEpgCacheProvider).get('1')!.single.title,
      'recorded',
    );
    expect(container.read(public.shortEpgCacheProvider).get('1'), isNull);
  });

  test('a failed archive request leaves the dedicated cache empty', () async {
    final api = _Api();
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWith((ref) => null),
        public.liveChannelsProvider
            .overrideWith((ref) async => [_channel('1')]),
      ],
    );
    addTearDown(container.dispose);
    final listener =
        container.listen(public.channelCatchUpProvider('1'), (_, __) {});
    addTearDown(listener.close);
    final result = container.read(public.channelCatchUpProvider('1').future);
    await api.started.future;
    final failure = expectLater(result, throwsStateError);
    api.pending.completeError(StateError('archive unavailable'));

    await failure;
    expect(container.read(public.catchUpEpgCacheProvider).get('1'), isNull);
  });

  test('disposed request does not write into a replaced catch-up cache',
      () async {
    final api = _Api();
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.activeSubscriptionProvider.overrideWith((ref) => null),
        public.liveChannelsProvider
            .overrideWith((ref) async => [_channel('1')]),
      ],
    );
    addTearDown(container.dispose);
    final oldCache = container.read(public.catchUpEpgCacheProvider);
    final listener =
        container.listen(public.channelCatchUpProvider('1'), (_, __) {});
    final result = container.read(public.channelCatchUpProvider('1').future);
    await api.started.future;
    listener.close();
    await container.pump();
    container.invalidate(public.catchUpEpgCacheProvider);
    final newCache = container.read(public.catchUpEpgCacheProvider);
    expect(newCache, isNot(same(oldCache)));
    api.pending.complete([_program('recorded', const Duration(hours: 1))]);
    expect(await result, isEmpty);
    expect(oldCache.get('1'), isNull);
    expect(newCache.get('1'), isNull);
  });
}
