import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/progressive_epg.dart';

void main() {
  final now = DateTime.now();
  EPGProgram program(String title) => EPGProgram(
        channelId: '1',
        title: title,
        description: '',
        start: now,
        end: now.add(const Duration(hours: 1)),
      );
  final short = [program('short')];
  final full = [program('full')];
  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

  test('emits the short guide then the complete guide', () async {
    final fullResult = Completer<List<EPGProgram>>();
    final shortResult = Completer<List<EPGProgram>>();
    final values = <List<EPGProgram>>[];
    final done = Completer<void>();
    progressiveEpg(
      loadFull: () => fullResult.future,
      startShort: (_) => shortResult.future,
      debounce: Duration.zero,
    ).listen(values.add, onDone: done.complete);
    await tick();
    shortResult.complete(short);
    await tick();
    expect(values, [short]);
    fullResult.complete(full);
    await done.future;
    expect(values, [short, full]);
  });

  test('a late short response cannot replace a complete guide', () async {
    final fullResult = Completer<List<EPGProgram>>();
    final shortResult = Completer<List<EPGProgram>>();
    final values = <List<EPGProgram>>[];
    final done = Completer<void>();
    progressiveEpg(
      loadFull: () => fullResult.future,
      startShort: (_) => shortResult.future,
      debounce: Duration.zero,
    ).listen(values.add, onDone: done.complete);
    await tick();
    fullResult.complete(full);
    await done.future;
    shortResult.complete(short);
    await tick();
    expect(values, [full]);
  });

  test('uses the cached short guide without a request', () async {
    final fullResult = Completer<List<EPGProgram>>();
    var requests = 0;
    final values = <List<EPGProgram>>[];
    final done = Completer<void>();
    progressiveEpg(
      loadFull: () => fullResult.future,
      startShort: (_) {
        requests++;
        return Future.value(short);
      },
      cachedShort: short,
    ).listen(values.add, onDone: done.complete);
    await tick();
    fullResult.complete(full);
    await done.future;
    expect(values, [short, full]);
    expect(requests, 0);
  });

  test('falls back to short when full is empty', () async {
    final values = await progressiveEpg(
      loadFull: () async => <EPGProgram>[],
      startShort: (_) async => short,
      debounce: Duration.zero,
    ).toList();
    expect(values, [short]);
  });

  test('continues loading the complete guide when short fails', () async {
    final fullResult = Completer<List<EPGProgram>>();
    final values = <List<EPGProgram>>[];
    final done = Completer<void>();
    progressiveEpg(
      loadFull: () => fullResult.future,
      startShort: (_) => Future.error(StateError('short failed')),
      debounce: Duration.zero,
    ).listen(values.add, onDone: done.complete);
    await tick();
    fullResult.complete(full);
    await done.future;
    expect(values, [full]);
  });

  test('reports a full-load failure when no short guide is available',
      () async {
    final values = progressiveEpg(
      loadFull: () => Future.error(StateError('full failed')),
      startShort: (_) async => <EPGProgram>[],
      debounce: Duration.zero,
    );
    await expectLater(values, emitsError(isA<StateError>()));
  });

  test('does not request short data when full is immediately available',
      () async {
    var requests = 0;
    final values = await progressiveEpg(
      loadFull: () async => full,
      startShort: (_) {
        requests++;
        return Future.value(short);
      },
    ).toList();
    expect(values, [full]);
    expect(requests, 0);
  });

  test('cancelling during debounce avoids the short request', () async {
    var requests = 0;
    final fullResult = Completer<List<EPGProgram>>();
    final subscription = progressiveEpg(
      loadFull: () => fullResult.future,
      startShort: (_) {
        requests++;
        return Future.value(short);
      },
      debounce: const Duration(milliseconds: 10),
    ).listen((_) {});
    await subscription.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    fullResult.complete(full);
    await tick();
    expect(requests, 0);
  });

  test('gate skips a cancelled request waiting behind another', () async {
    final gate = ShortEpgRequestGate();
    final first = Completer<List<EPGProgram>>();
    var secondStarted = false;
    var valid = true;
    final firstResult = gate.start(() => first.future, () => true);
    final secondResult = gate.start(() async {
      secondStarted = true;
      return short;
    }, () => valid);
    valid = false;
    first.complete(short);
    await firstResult;
    expect(await secondResult, isEmpty);
    expect(secondStarted, isFalse);
  });

  test('gate starts the current request once the previous request completes',
      () async {
    final gate = ShortEpgRequestGate();
    final first = Completer<List<EPGProgram>>();
    var secondStarted = false;
    final firstResult = gate.start(() => first.future, () => true);
    final secondResult = gate.start(() async {
      secondStarted = true;
      return full;
    }, () => true);
    expect(secondStarted, isFalse);
    first.complete(short);
    expect(await firstResult, short);
    expect(await secondResult, full);
    expect(secondStarted, isTrue);
  });
}
