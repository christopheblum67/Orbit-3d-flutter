import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _FakeApi extends ApiService {
  int calls = 0;
  final first = Completer<List<EPGProgram>>();

  @override
  Future<String?> resolveSubscriptionCacheKey() async => null;

  @override
  Future<List<EPGProgram>> fetchEpg() {
    calls++;
    if (calls == 1) return first.future;
    return Future.value([_program('new')]);
  }
}

EPGProgram _program(String title) => EPGProgram(
      channelId: 'channel',
      title: title,
      description: '',
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(hours: 1)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('forced refresh waits for a pending fetch then replaces fresh data',
      () async {
    final api = _FakeApi();
    final cache = EPGDataCache();
    final initial = cache.loadFull(api);
    final forced = cache.loadFull(api, forceRefresh: true);
    api.first.complete([_program('old')]);
    expect((await initial).single.title, 'old');
    expect((await forced).single.title, 'new');
    expect((await cache.loadFull(api)).single.title, 'new');
    expect(api.calls, 2);
  });
}
