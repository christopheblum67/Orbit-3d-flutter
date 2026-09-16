import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';

Channel channelOf(String id) => Channel(
      id: id,
      name: 'Chaîne $id',
      logoUrl: '',
      streamUrl: 'http://stream/$id',
      epgChannelId: 'epg_$id',
      group: 'Test',
    );

EPGProgram programOf(Channel c) => EPGProgram(
      channelId: c.epgChannelId,
      title: 'Programme ${c.id}',
      description: '',
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(minutes: 30)),
    );

void main() {
  group('ShortEpgCache', () {
    var now = DateTime(2025, 1, 1, 12);
    late ShortEpgCache cache;

    setUp(() {
      now = DateTime(2025, 1, 1, 12);
      cache = ShortEpgCache(now: () => now);
    });

    test('programsFor renvoie null tant que rien n\'est mis', () {
      expect(cache.programsFor('epg_1'), isNull);
      expect(cache.isFresh('epg_1'), isFalse);
    });

    test('put puis programsFor retourne les programmes frais', () {
      final c = channelOf('1');
      cache.put('epg_1', [programOf(c)]);
      expect(cache.programsFor('epg_1'), hasLength(1));
      expect(cache.isFresh('epg_1'), isTrue);
    });

    test('TTL : l\'entrée devient périmée après 30 minutes', () {
      final c = channelOf('1');
      cache.put('epg_1', [programOf(c)]);
      now = now.add(ShortEpgCache.ttl);
      expect(cache.programsFor('epg_1'), isNull);
      expect(cache.isFresh('epg_1'), isFalse);
    });

    test('invalidate retire l\'entrée', () {
      final c = channelOf('1');
      cache.put('epg_1', [programOf(c)]);
      cache.invalidate('epg_1');
      expect(cache.programsFor('epg_1'), isNull);
    });

    test('cap : au-delà de maxChannels, les plus anciennes sont évincées', () {
      for (var i = 0; i < ShortEpgCache.maxChannels + 5; i++) {
        cache.put('epg_$i', [programOf(channelOf('$i'))]);
        now = now.add(const Duration(seconds: 1));
      }
      expect(cache.size, lessThanOrEqualTo(ShortEpgCache.maxChannels));
      expect(cache.programsFor('epg_0'), isNull);
      expect(cache.programsFor('epg_${ShortEpgCache.maxChannels + 4}'), isNotNull);
    });
  });

  group('EpgPreloadService', () {
    test('précharge avec parallélisme borné et saute les SANS epgChannelId', () async {
      final channels = List.generate(9, (i) => channelOf('$i'));
      final calls = <String>[];
      final service = EpgPreloadService(concurrency: 3);
      final loaded = await service.preload(channels, (c) async {
        calls.add(c.id);
        return [programOf(c)];
      });
      expect(loaded, 9);
      expect(calls, hasLength(9));
      for (final ch in channels) {
        expect(service.cache.isFresh(ch.epgChannelId), isTrue);
      }
    });

    test('ne refait pas les chaînes déjà fraîches', () async {
      final channels = List.generate(4, (i) => channelOf('$i'));
      final calls = <String>[];
      final service = EpgPreloadService(concurrency: 2);
      await service.preload(channels, (c) async {
        calls.add(c.id);
        return [programOf(c)];
      });
      final callsAfterFirst = calls.length;
      await service.preload(channels, (c) async {
        calls.add(c.id);
        return [programOf(c)];
      });
      expect(calls.length, callsAfterFirst);
    });

    test('pas de chargement si loader échoue (aucune entrée en cache)', () async {
      final channels = [channelOf('1')];
      final service = EpgPreloadService();
      final loaded = await service.preload(channels, (c) async {
        throw Exception('panel injoignable');
      });
      expect(loaded, 0);
      expect(service.cache.size, 0);
    });

    test('loader retournant une liste vide → non mis en cache', () async {
      final service = EpgPreloadService();
      final loaded = await service.preload([channelOf('1')], (c) async {
        return const <EPGProgram>[];
      });
      expect(loaded, 0);
      expect(service.cache.size, 0);
    });
  });
}