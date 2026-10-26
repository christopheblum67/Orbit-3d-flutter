import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';

void main() {
  late HistoryService service;
  late Box<dynamic> box;

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('orbit_history_');
    Hive.init(directory.path);
  });

  setUp(() async {
    service = HistoryService();
    await service.init();
    box = Hive.box('history');
    await box.clear();
  });

  tearDown(() async {
    await box.clear();
  });

  test('enregistre et relit type, titre et URL de lecture', () async {
    await service.addEntry('vod', 'Film | spécial', 'https://media.test/a|b');

    final entries = await service.getHistory();

    expect(entries, hasLength(1));
    expect(entries.single.type, 'vod');
    expect(entries.single.title, 'Film | spécial');
    expect(entries.single.streamUrl, 'https://media.test/a|b');
    expect(entries.single.timestamp, isA<DateTime>());
  });

  test('lit les entrées créées par les anciennes versions', () async {
    await box.put(
      'series-1760000000000',
      'Série | https://media.test/episode.m3u8',
    );

    final entry = (await service.getHistory()).single;

    expect(entry.type, 'series');
    expect(entry.title, 'Série');
    expect(entry.streamUrl, 'https://media.test/episode.m3u8');
    expect(entry.timestamp, DateTime.fromMillisecondsSinceEpoch(1760000000000));
  });

  test('borne la croissance de l’historique à 100 entrées', () async {
    for (var index = 0; index < HistoryService.maxEntries + 2; index++) {
      await service.addEntry(
        'live',
        'Chaîne $index',
        'https://media.test/$index',
      );
    }

    expect(await service.getHistory(), hasLength(HistoryService.maxEntries));
  });
}
