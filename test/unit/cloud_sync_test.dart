import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_gateway.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_models.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_service.dart';

void main() {
  final baseTime = DateTime.utc(2025, 10, 1, 12);

  group('InMemoryCloudSyncGateway', () {
    late InMemoryCloudSyncGateway gw;

    setUp(() {
      gw = InMemoryCloudSyncGateway();
    });

    test('fetch renvoie null quand le store est vide', () async {
      final snap = await gw.fetchSnapshot(
        CloudSyncScope.favorites,
        'p1',
      );
      expect(snap, isNull);
    });

    test('push puis fetch retourne le snapshot stocké', () async {
      final snap = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1"}',
            updatedAt: DateTime.utc(2025, 9, 1),
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      await gw.pushSnapshot(snap);
      final fetched = await gw.fetchSnapshot(CloudSyncScope.favorites, 'p1');
      expect(fetched, isNotNull);
      expect(fetched!.entries.length, 1);
      expect(fetched.version, 1);
    });
  });

  group('CloudSyncService.merge', () {
    late CloudSyncService svc;

    setUp(() {
      svc = CloudSyncService(now: () => baseTime);
    });

    test('premier sync : local non vide → push complet', () {
      final local = {
        'p1:live:1': '{"type":"live","id":"1","title":"TF1"}',
        'p1:vod:2': '{"type":"vod","id":"2","title":"Film"}',
      };
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: null,
        mirror: null,
      );
      expect(result.pushRequired, isTrue);
      expect(result.localWrites, isEmpty);
      expect(result.localRemoves, isEmpty);
      expect(result.merged.entries.length, 2);
      expect(result.merged.version, 1);
    });

    test('premier sync : local et remote identiques → pas de push', () {
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1"}',
            updatedAt: baseTime,
          ),
        },
        updatedAt: baseTime,
        version: 2,
      );
      final local = {'p1:live:1': '{"type":"live","id":"1"}'};
      final mirror = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1"}',
            updatedAt: baseTime,
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: mirror,
      );
      expect(result.pushRequired, isFalse);
    });

    test('remote gagne : entrée non modifiée locale remplacée par remote', () {
      final local = {
        'p1:live:1': '{"type":"live","id":"1","title":"ancien"}',
      };
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1","title":"nouveau"}',
            updatedAt: baseTime.add(const Duration(hours: 1)),
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final mirror = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1","title":"ancien"}',
            updatedAt: baseTime.subtract(const Duration(days: 1)),
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: mirror,
      );
      expect(result.remoteWins, isTrue);
      expect(result.localWrites, containsPair('p1:live:1', isA<String>()));
      expect(
        result.localWrites['p1:live:1'],
        contains('"title":"nouveau"'),
      );
    });

    test('local gagne : entrée modifiée localement plus récente que remote', () {
      final local = {
        'p1:live:1': '{"type":"live","id":"1","title":"localiste"}',
      };
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1","title":"cloud old"}',
            updatedAt: baseTime.subtract(const Duration(days: 5)),
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final mirror = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1","title":"cloud old"}',
            updatedAt: baseTime.subtract(const Duration(days: 5)),
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: mirror,
      );
      expect(result.remoteWins, isFalse);
      expect(result.localWrites, isEmpty);
      expect(
        result.merged.entries['p1:live:1']!.json,
        contains('"title":"localiste"'),
      );
    });

    test('remote supprime une entrée non modifiée localement', () {
      final local = {
        'p1:live:1': '{"type":"live","id":"1"}',
      };
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {},
        updatedAt: baseTime,
        version: 2,
      );
      final mirror = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1"}',
            updatedAt: baseTime.subtract(const Duration(days: 1)),
          ),
        },
        updatedAt: baseTime.subtract(const Duration(days: 1)),
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: mirror,
      );
      expect(result.remoteWins, isTrue);
      expect(result.localRemoves, contains('p1:live:1'));
      expect(result.merged.entries, isEmpty);
    });

    test('remote supprime une entrée MODIFIÉE localement → local gagne', () {
      final local = {
        'p1:live:1': '{"type":"live","id":"1","title":"modifié"}',
      };
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {},
        updatedAt: baseTime,
        version: 2,
      );
      final mirror = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:live:1': CloudSyncEntry(
            json: '{"type":"live","id":"1","title":"ancien"}',
            updatedAt: baseTime.subtract(const Duration(days: 5)),
          ),
        },
        updatedAt: baseTime.subtract(const Duration(days: 5)),
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: mirror,
      );
      expect(result.remoteWins, isFalse);
      expect(result.localRemoves, isEmpty);
      expect(
        result.merged.entries['p1:live:1']!.json,
        contains('"title":"modifié"'),
      );
    });

    test('remote ajoute une entrée inexistante localement → téléchargée', () {
      final local = <String, String>{};
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:vod:9': CloudSyncEntry(
            json: '{"type":"vod","id":"9","title":"Nouveau film"}',
            updatedAt: baseTime,
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: null,
      );
      expect(result.remoteWins, isTrue);
      expect(result.localWrites, containsPair('p1:vod:9', isA<String>()));
      expect(result.merged.entries.length, 1);
    });

    test('ensemble : ajout local + ajout remote sur clés différentes', () {
      final local = {
        'p1:live:1': '{"type":"live","id":"1"}',
      };
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        entries: {
          'p1:vod:2': CloudSyncEntry(
            json: '{"type":"vod","id":"2"}',
            updatedAt: baseTime,
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final result = svc.merge(
        scope: CloudSyncScope.favorites,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: null,
      );
      expect(result.merged.entries.keys, containsAll(['p1:live:1', 'p1:vod:2']));
      expect(result.localWrites, containsPair('p1:vod:2', isA<String>()));
    });

    test('scope watched : même algorithme, clés de watchers', () {
      final local = {
        'p1:sr101:S1E1': '{"season":1,"episodeNumber":1}',
      };
      final remote = CloudSyncSnapshot(
        scope: CloudSyncScope.watched,
        profileId: 'p1',
        entries: {
          'p1:sr101:S1E1': CloudSyncEntry(
            json: '{"season":1,"episodeNumber":1}',
            updatedAt: baseTime,
          ),
        },
        updatedAt: baseTime,
        version: 1,
      );
      final mirror = remote;
      final result = svc.merge(
        scope: CloudSyncScope.watched,
        profileId: 'p1',
        local: local,
        remote: remote,
        mirror: mirror,
      );
      expect(result.pushRequired, isFalse);
      expect(result.localWrites, isEmpty);
    });
  });
}
