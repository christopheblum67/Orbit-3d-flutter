import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';

void main() {
  group('Channel EPG linkage', () {
    // Xtream ne renvoie pas de champ `epg_channel_id` : la liaison avec le
    // dump XMLTV passe par le `stream_id`. Sans cette déduction,
    // `epgChannelId` restait vide et la recherche de programme renvoyait
    // systématiquement « aucun programme en cours ».
    test('deduces EPG ids from stream_id and num', () {
      final channel = Channel.fromMap({
        'stream_id': 117,
        'num': 1,
        'name': 'TF1',
        'url': 'http://example/stream',
        'category_id': '5',
      });

      expect(channel.id, '117');
      expect(channel.epgChannelId, isNotEmpty);
      expect(channel.epgChannelIds, contains('117'));
      expect(channel.epgChannelIds, contains('1:117'));
      expect(channel.primaryEpgChannelId, '117');
    });

    test('without num, only the bare stream_id is used', () {
      final channel = Channel.fromMap({
        'stream_id': 42,
        'name': 'Canal+',
        'url': 'http://example/stream',
      });

      expect(channel.epgChannelIds, ['42']);
      expect(channel.primaryEpgChannelId, '42');
    });

    test('an explicit epg_channel_id is preserved', () {
      final channel = Channel.fromMap({
        'stream_id': 42,
        'num': 3,
        'epg_channel_id': 'custom.id',
        'name': 'M6',
        'url': 'http://example/stream',
      });

      expect(channel.epgChannelIds, contains('custom.id'));
      expect(channel.epgChannelIds, contains('3:42'));
    });

    test('replay support comes from tv_archive / timeshift / dvr', () {
      final dvr = Channel.fromMap({
        'stream_id': 1,
        'name': 'A',
        'url': 'u',
        'radio_tv': 'dvr',
      });
      final archive = Channel.fromMap({
        'stream_id': 2,
        'name': 'B',
        'url': 'u',
        'tv_archive': '1',
      });
      final timeshift = Channel.fromMap({
        'stream_id': 3,
        'name': 'C',
        'url': 'u',
        'timeshift_seconds': 7200,
      });
      final plain = Channel.fromMap({'stream_id': 4, 'name': 'D', 'url': 'u'});

      expect(dvr.supportsReplay, isTrue);
      expect(archive.supportsReplay, isTrue);
      expect(timeshift.supportsReplay, isTrue);
      expect(plain.supportsReplay, isFalse);
    });
  });
}
