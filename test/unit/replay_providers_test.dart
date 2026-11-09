import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/providers/replay_providers.dart' as replay;
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Api extends ApiService {
  int probeCalls = 0;
  final requests = <Completer<List<ReplayItem>>>[];
  final firstStarted = Completer<void>();
  final secondStarted = Completer<void>();

  @override
  Future<List<ReplayItem>> fetchChannelReplays(Channel channel) {
    final request = Completer<List<ReplayItem>>();
    requests.add(request);
    if (requests.length == 1) firstStarted.complete();
    if (requests.length == 2) secondStarted.complete();
    return request.future;
  }

  @override
  Future<List<ReplayItem>> fetchReplays() async {
    probeCalls++;
    return [_item('probe')];
  }

  @override
  Future<List<ReplayItem>> buildReplaysFromGlobalEpg({
    required List<EPGProgram> programs,
    required List<Channel> channels,
  }) async =>
      [_item('global')];
}

class _Epg extends public.EPGProgramsNotifier {
  @override
  Future<List<EPGProgram>> build() async => [];
}

ReplayItem _item(String id) => ReplayItem(
      id: id,
      title: id,
      streamUrl: id,
      startTime: '',
      endTime: '',
      channelId: id,
    );

final _channel = Channel(
  id: '42',
  name: 'Channel',
  logoUrl: '',
  streamUrl: '',
  group: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    public.replaysCache.invalidate();
    public.channelReplaysCache.invalidate();
  });
  tearDown(() {
    public.replaysCache.invalidate();
    public.channelReplaysCache.invalidate();
  });

  ProviderContainer containerFor(
    _Api api, {
    Future<List<Channel>> Function()? loadChannels,
  }) =>
      ProviderContainer(
        overrides: [
          public.apiServiceProvider.overrideWithValue(api),
          public.activeSubscriptionProvider.overrideWithValue(null),
          public.liveChannelsProvider.overrideWith(
            (ref) => loadChannels?.call() ?? Future.value([_channel]),
          ),
          public.epgProgramsProvider.overrideWith(_Epg.new),
        ],
      );

  test('public exports retain the same providers and caches', () {
    expect(public.replaysProvider, same(replay.replaysProvider));
    expect(public.replaysProbeProvider, same(replay.replaysProbeProvider));
    expect(public.channelReplaysProvider, same(replay.channelReplaysProvider));
    expect(public.replaysCache, same(replay.replaysCache));
    expect(public.channelReplaysCache, same(replay.channelReplaysCache));
  });

  test('fast replay list does not start the probe', () async {
    final api = _Api();
    final container = containerFor(api);
    addTearDown(container.dispose);
    final result = await container.read(public.replaysProvider.future);
    expect(result.map((item) => item.id), ['global']);
    expect(api.probeCalls, 0);
    await container.read(public.replaysProbeProvider.future);
    expect(api.probeCalls, 1);
    container.invalidate(public.replaysProvider);
    final merged = await container.read(public.replaysProvider.future);
    expect(merged.map((item) => item.id), containsAll(['global', 'probe']));
    expect(api.probeCalls, 1);
  });

  test('channel replays use cache without probing other channels', () async {
    final api = _Api();
    final container = containerFor(api);
    addTearDown(container.dispose);
    final listener =
        container.listen(public.channelReplaysProvider('42'), (_, __) {});
    await api.firstStarted.future;
    expect(api.requests, hasLength(1));
    api.requests.single.complete([_item('first')]);
    expect(
      (await container.read(public.channelReplaysProvider('42').future))
          .single
          .id,
      'first',
    );
    listener.close();
    await container.pump();
    final next =
        container.listen(public.channelReplaysProvider('42'), (_, __) {});
    addTearDown(next.close);
    expect(
      (await container.read(public.channelReplaysProvider('42').future))
          .single
          .id,
      'first',
    );
    expect(api.requests, hasLength(1));
    expect(api.probeCalls, 0);
  });

  test('old channel response cannot refill cache after invalidation', () async {
    final api = _Api();
    final container = containerFor(api);
    addTearDown(container.dispose);
    final listener =
        container.listen(public.channelReplaysProvider('42'), (_, __) {});
    final oldFuture =
        container.read(public.channelReplaysProvider('42').future);
    await api.firstStarted.future;
    public.channelReplaysCache.invalidate();
    container.invalidate(public.channelReplaysProvider('42'));
    await container.pump();
    await api.secondStarted.future;
    expect(api.requests, hasLength(2));
    api.requests[1].complete([_item('new')]);
    expect(
      (await container.read(public.channelReplaysProvider('42').future))
          .single
          .id,
      'new',
    );
    api.requests[0].complete([_item('old')]);
    await oldFuture;
    expect(public.channelReplaysCache.peek('42')!.single.id, 'new');
    listener.close();
  });

  test('invalidation before channels load prevents an obsolete request',
      () async {
    final api = _Api();
    final channels = Completer<List<Channel>>();
    final container = containerFor(api, loadChannels: () => channels.future);
    addTearDown(container.dispose);
    final listener =
        container.listen(public.channelReplaysProvider('42'), (_, __) {});
    final result = container.read(public.channelReplaysProvider('42').future);
    public.channelReplaysCache.invalidate();
    channels.complete([_channel]);
    expect(await result, isEmpty);
    expect(api.requests, isEmpty);
    listener.close();
  });
}
