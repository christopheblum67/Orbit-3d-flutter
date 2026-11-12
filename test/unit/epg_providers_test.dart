import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/epg_providers.dart' as split;
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Api extends ApiService {
  final calls = <String>[];
  final requests = <String, Completer<List<EPGProgram>>>{};

  @override
  Future<List<EPGProgram>> fetchChannelEpgPrograms(Channel channel) {
    calls.add(channel.id);
    return requests.putIfAbsent(channel.id, Completer.new).future;
  }
}

class _Cache extends public.EPGDataCache {
  final pending = Completer<List<EPGProgram>>();

  @override
  Future<List<EPGProgram>> loadFull(
    ApiService api, {
    bool forceRefresh = false,
  }) =>
      pending.future;
}

Channel _channel(String id) => Channel(
      id: id,
      name: id,
      logoUrl: '',
      streamUrl: '',
      group: '',
    );

void main() {
  test('facade exports the same EPG providers', () {
    expect(public.epgProgramsProvider, same(split.epgProgramsProvider));
    expect(public.epgDataCacheProvider, same(split.epgDataCacheProvider));
    expect(public.shortEpgCacheProvider, same(split.shortEpgCacheProvider));
    expect(public.epgPreloadServiceProvider, same(split.epgPreloadServiceProvider));
    expect(public.channelEpgProvider, same(split.channelEpgProvider));
    expect(public.channelEpgWindowProvider, same(split.channelEpgWindowProvider));
    expect(public.channelPreviewEpgProvider, same(split.channelPreviewEpgProvider));
  });

  testWidgets('preview requests share the gate and cancelled requests use no budget',
      (tester) async {
    final api = _Api();
    final cache = _Cache();
    final first = _channel('first');
    final second = _channel('second');
    final third = _channel('third');
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.epgDataCacheProvider.overrideWithValue(cache),
        public.activeSubscriptionProvider.overrideWithValue(
          Subscription(
            id: 'xtream',
            name: 'Xtream',
            type: SubscriptionType.xtream,
            createdAt: DateTime(2020),
          ),
        ),
      ],
    );
    var disposed = false;
    void disposeContainer() {
      if (disposed) return;
      disposed = true;
      container.dispose();
    }

    addTearDown(disposeContainer);
    final firstListener =
        container.listen(public.channelPreviewEpgProvider(first), (_, __) {});
    await tester.pump(const Duration(milliseconds: 900));
    expect(api.calls, ['first']);
    expect(container.read(public.epgFallbackBudgetProvider).consumed, 1);
    final secondListener =
        container.listen(public.channelPreviewEpgProvider(second), (_, __) {});
    await tester.pump(const Duration(milliseconds: 900));
    expect(api.calls, ['first']);
    secondListener.close();
    await tester.pump();
    final thirdListener =
        container.listen(public.channelPreviewEpgProvider(third), (_, __) {});
    await tester.pump(const Duration(milliseconds: 900));
    expect(api.calls, ['first']);
    api.requests['first']!.complete([]);
    await tester.pump();
    expect(api.calls, ['first', 'third']);
    expect(container.read(public.epgFallbackBudgetProvider).consumed, 2);
    api.requests['third']!.complete([]);
    cache.pending.complete([]);
    await tester.pump();
    firstListener.close();
    thirdListener.close();
    await tester.pump();
    disposeContainer();
    await tester.pump();
  });

  testWidgets('M3U preview never requests the Xtream short guide',
      (tester) async {
    final api = _Api();
    final cache = _Cache();
    final container = ProviderContainer(
      overrides: [
        public.apiServiceProvider.overrideWithValue(api),
        public.epgDataCacheProvider.overrideWithValue(cache),
        public.activeSubscriptionProvider.overrideWithValue(
          Subscription(
            id: 'm3u',
            name: 'M3U',
            type: SubscriptionType.m3u,
            createdAt: DateTime(2020),
          ),
        ),
      ],
    );
    var disposed = false;
    void disposeContainer() {
      if (disposed) return;
      disposed = true;
      container.dispose();
    }

    addTearDown(disposeContainer);
    final listener = container.listen(
      public.channelPreviewEpgProvider(_channel('m3u')),
      (_, __) {},
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(api.calls, isEmpty);
    expect(container.read(public.epgFallbackBudgetProvider).consumed, 0);
    cache.pending.complete([]);
    await tester.pump();
    listener.close();
    await tester.pump();
    disposeContainer();
    await tester.pump();
  });
}
