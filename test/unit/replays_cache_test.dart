import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

ReplayItem _replay(String id) => ReplayItem(
      id: id,
      title: 'Replay $id',
      streamUrl: 'http://cdn/replay/$id.ts',
      startTime: '',
      endTime: '',
    );

void main() {
  test('le cache renvoie la valeur chargée sans rappeler le loader', () async {
    final cache = ReplaysCache();
    var calls = 0;

    final first = await cache.fetch(() async {
      calls++;
      return [_replay('a')];
    });
    expect(first.length, 1);
    expect(calls, 1);

    // Deuxième appel dans la fenêtre TTL : pas de nouveau chargement.
    final second = await cache.fetch(() async {
      calls++;
      return [_replay('b')];
    });
    expect(second.single.id, 'a');
    expect(calls, 1);
  });

  test("un échec n'est pas mis en cache, le loader est rappelé", () async {
    final cache = ReplaysCache();
    var calls = 0;
    Future<List<ReplayItem>> loader() async {
      calls++;
      if (calls == 1) throw StateError('panne panel');
      return [_replay('ok')];
    }

    await expectLater(cache.fetch(loader), throwsA(isA<StateError>()));
    final retry = await cache.fetch(loader);
    expect(retry.single.id, 'ok');
    expect(calls, 2);
  });

  test('invalidate force un rechargement', () async {
    final cache = ReplaysCache();
    var calls = 0;
    Future<List<ReplayItem>> loader() async {
      calls++;
      return [_replay('r$calls')];
    }

    await cache.fetch(loader);
    cache.invalidate();
    final fresh = await cache.fetch(loader);
    expect(fresh.single.id, 'r2');
    expect(calls, 2);
  });
}