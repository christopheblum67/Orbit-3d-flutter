import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/player_preloader.dart';

void main() {
  test('retries failures and transfers only a usable player', () async {
    final preloader = PlayerPreloader<int>();
    final disposed = <int>[];
    final accepted = <int>[];
    final paused = <int>[];
    await preloader.start(
      index: 4,
      attempts: [1, 2, 3],
      isCurrent: () => true,
      create: (attempt) => attempt,
      initialize: (player) async => player != 1,
      isUsable: (player) => player == 3,
      pause: paused.add,
      canAccept: () => true,
      accept: (index, player) => accepted.add(player),
      dispose: disposed.add,
    );
    expect(disposed, [1, 2]);
    expect(paused, [3]);
    expect(accepted, [3]);
    expect(preloader.pendingIndex, isNull);
  });

  test('cancelled response cannot affect a new operation', () async {
    final preloader = PlayerPreloader<int>();
    final first = Completer<bool>();
    final second = Completer<bool>();
    final disposed = <int>[];
    final accepted = <int>[];
    Future<void> start(int index, Completer<bool> pending) => preloader.start(
          index: index,
          attempts: [index],
          isCurrent: () => true,
          create: (attempt) => attempt,
          initialize: (_) => pending.future,
          isUsable: (_) => true,
          pause: (_) {},
          canAccept: () => true,
          accept: (index, player) => accepted.add(player),
          dispose: disposed.add,
        );
    final stale = start(1, first);
    preloader.cancel();
    final current = start(2, second);
    first.complete(true);
    await stale;
    expect(preloader.pendingIndex, 2);
    expect(disposed, [1]);
    expect(accepted, isEmpty);
    second.complete(true);
    await current;
    expect(accepted, [2]);
    expect(preloader.pendingIndex, isNull);
  });

  test('duplicate requests and unavailable cache do not leak a player',
      () async {
    final preloader = PlayerPreloader<int>();
    final pending = Completer<bool>();
    final disposed = <int>[];
    var created = 0;
    Future<void> start() => preloader.start(
          index: 1,
          attempts: [1],
          isCurrent: () => true,
          create: (_) => ++created,
          initialize: (_) => pending.future,
          isUsable: (_) => true,
          pause: (_) => fail('should not pause'),
          canAccept: () => false,
          accept: (_, __) => fail('should not transfer'),
          dispose: disposed.add,
        );
    final initial = start();
    await start();
    expect(created, 1);
    pending.complete(true);
    await initial;
    expect(disposed, [1]);
    expect(preloader.pendingIndex, isNull);
  });

  test('initialization errors release ownership and remain visible', () async {
    final preloader = PlayerPreloader<int>();
    final disposed = <int>[];
    await expectLater(
      preloader.start(
        index: 1,
        attempts: [1],
        isCurrent: () => true,
        create: (attempt) => attempt,
        initialize: (_) async => throw StateError('failed'),
        isUsable: (_) => true,
        pause: (_) {},
        canAccept: () => true,
        accept: (_, __) {},
        dispose: disposed.add,
      ),
      throwsStateError,
    );
    expect(disposed, [1]);
    expect(preloader.pendingIndex, isNull);
  });

  test('a player whose generation expired is released', () async {
    final preloader = PlayerPreloader<int>();
    final pending = Completer<bool>();
    final disposed = <int>[];
    var current = true;
    final operation = preloader.start(
      index: 1,
      attempts: [1, 2],
      isCurrent: () => current,
      create: (attempt) => attempt,
      initialize: (_) => pending.future,
      isUsable: (_) => true,
      pause: (_) => fail('stale player must not be paused into cache'),
      canAccept: () => true,
      accept: (_, __) => fail('stale player must not be accepted'),
      dispose: disposed.add,
    );
    current = false;
    pending.complete(true);
    await operation;
    expect(disposed, [1]);
    expect(preloader.pendingIndex, isNull);
  });
}
