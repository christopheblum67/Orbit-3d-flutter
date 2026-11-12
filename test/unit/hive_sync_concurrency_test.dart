import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

void main() {
  test('serializes multiple waiters and releases the lock after an error',
      () async {
    final dir = await Directory.systemTemp.createTemp('orbit_hive_sync_');
    Hive.init(dir.path);
    await Hive.openBox('sync_test');
    try {
      final gate = Completer<void>();
      final started = Completer<void>();
      final events = <String>[];
      final first = HiveSync.writeAsync('sync_test', (box) async {
        events.add('first');
        started.complete();
        await gate.future;
        throw StateError('expected');
      });
      final firstResult = expectLater(first, throwsStateError);
      await started.future;
      final second = HiveSync.writeAsync('sync_test', (box) async {
        events.add('second');
        await Future<void>.delayed(Duration.zero);
        events.add('second done');
      });
      final third = HiveSync.writeAsync('sync_test', (box) async {
        events.add('third');
      });
      gate.complete();
      await Future.wait([firstResult, second, third]);
      expect(events, ['first', 'second', 'second done', 'third']);
    } finally {
      await Hive.close();
      await dir.delete(recursive: true);
    }
  });
}
