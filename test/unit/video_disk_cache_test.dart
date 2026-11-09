import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/video_disk_cache.dart';

void main() {
  late Directory dir;
  late VideoDiskCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_video_cache_test');
    cache = VideoDiskCache(dir, maxBytes: 5);
    await cache.initialize();
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<String?> read(String key) =>
      cache.withEntry(key, (file) => file.readAsString());
  Stream<List<int>> data(String s) => Stream.value(s.codeUnits);

  test('publie seulement les réponses complètes et respecte le quota',
      () async {
    expect(await cache.store('a', data('abc'), contentLength: 3), isTrue);
    expect(await read('a'), 'abc');
    await expectLater(
      cache.store('b', data('12'), contentLength: 3),
      throwsFormatException,
    );
    expect(await read('b'), isNull);
    expect(await cache.store('b', data('1234'), contentLength: 4), isTrue);
    expect(await read('a'), isNull);
    expect(await read('b'), '1234');
    expect(await cache.store('c', data('123456'), contentLength: 6), isFalse);
    expect(await read('b'), '1234');
    expect((await dir.list().toList()).whereType<File>().length, 1);
  });

  test('protège une lecture en cours contre l’éviction et purge', () async {
    await cache.store('a', data('abc'), contentLength: 3);
    final opened = Completer<void>();
    final release = Completer<void>();
    final reading = cache.withEntry('a', (file) async {
      opened.complete();
      await release.future;
      return file.readAsString();
    });
    await opened.future;
    final write = cache.store('b', data('1234'), contentLength: 4);
    release.complete();
    expect(await reading, 'abc');
    expect(await write, isTrue);
    await cache.clear();
    expect(await read('b'), isNull);
  });

  test(
      'récupère les téléchargements interrompus sans effacer les autres fichiers',
      () async {
    final incomplete =
        File('${dir.path}${Platform.pathSeparator}${'a' * 64}.partial');
    final unrelated = File('${dir.path}${Platform.pathSeparator}autre.partial');
    await incomplete.writeAsString('x');
    await unrelated.writeAsString('x');
    await cache.initialize();
    expect(await incomplete.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
  });

  test('une purge empêche une capture antérieure de repeupler le cache',
      () async {
    final oldGeneration = cache.generation;
    await cache.clear();
    expect(
        await cache.store('a', data('abc'),
            contentLength: 3, expectedGeneration: oldGeneration),
        isFalse);
    expect(await read('a'), isNull);
  });

  test('supprime uniquement les clés indiquées et attend les écritures',
      () async {
    final writing = Completer<void>();
    final release = Completer<void>();
    final stream = Stream<List<int>>.fromFuture(() async {
      writing.complete();
      await release.future;
      return 'abc'.codeUnits;
    }());
    await cache.store('b', data('z'), contentLength: 1);
    final store = cache.store('a', stream, contentLength: 3);
    await writing.future;
    final remove = cache.removeEntries(['a']);
    release.complete();
    expect(await store, isTrue);
    await remove;
    expect(await read('a'), isNull);
    expect(await read('b'), 'z');
  });

  test('supprime les anciennes entrées lorsque demandé au démarrage', () async {
    await cache.store('a', data('abc'), contentLength: 3);
    final unrelated = File('${dir.path}${Platform.pathSeparator}autre.cache');
    await unrelated.writeAsString('x');
    await cache.initialize(discardExisting: true);
    expect(await read('a'), isNull);
    expect(await unrelated.exists(), isTrue);
  });
}
