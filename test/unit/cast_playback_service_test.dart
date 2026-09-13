import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/cast_playback_service.dart';

void main() {
  group('CastPlaybackService.guessContentType', () {
    test('detects HLS manifests', () {
      expect(
        CastPlaybackService.guessContentType(
          'https://cdn.example.com/live/bfmtv.m3u8',
        ),
        'application/x-mpegurl',
      );
      expect(
        CastPlaybackService.guessContentType('https://x.com/a/v.m3u'),
        'application/x-mpegurl',
      );
    });

    test('force live flag returns HLS ml', () {
      expect(
        CastPlaybackService.guessContentType(
          'https://cdn.example.com/stream?id=1',
          isLive: true,
        ),
        'application/x-mpegurl',
      );
    });

    test('detects dash manifests', () {
      expect(
        CastPlaybackService.guessContentType('https://x.com/manifest.mpd'),
        'application/dash+xml',
      );
      expect(
        CastPlaybackService.guessContentType('https://x.com/out.dash'),
        'application/dash+xml',
      );
    });

    test('detects common containers', () {
      expect(
        CastPlaybackService.guessContentType('https://x.com/movie.mp4'),
        'video/mp4',
      );
      expect(
        CastPlaybackService.guessContentType('https://x.com/movie.mkv'),
        'video/x-matroska',
      );
      expect(
        CastPlaybackService.guessContentType('https://x.com/movie.webm'),
        'video/webm',
      );
      expect(
        CastPlaybackService.guessContentType('https://x.com/seg.ts'),
        'video/mp2t',
      );
    });

    test('falls back to MP4 for unknown extensions', () {
      expect(
        CastPlaybackService.guessContentType('https://x.com/stream'),
        'video/mp4',
      );
    });
  });

  group('CastPlaybackService.buildLoadPayload', () {
    test('builds a minimal LOAD payload', () {
      final payload = CastPlaybackService.buildLoadPayload(
        contentId: 'https://x.com/movie.m3u8',
        contentType: 'application/x-mpegurl',
        sessionId: 'abc-123',
      );
      expect(payload['type'], 'LOAD');
      expect(payload['autoplay'], isTrue);
      expect(payload['currentTime'], 0.0);
      expect(payload['sessionId'], 'abc-123');
      final media = payload['media'] as Map<String, dynamic>;
      expect(media['contentId'], 'https://x.com/movie.m3u8');
      expect(media['contentType'], 'application/x-mpegurl');
      expect(media.containsKey('streamType'), isFalse);
      final metadata = media['metadata'] as Map<String, dynamic>;
      expect(metadata['metadataType'], 0);
    });

    test('adds streamType for live content', () {
      final payload = CastPlaybackService.buildLoadPayload(
        contentId: 'https://x.com/live.m3u8',
        contentType: 'application/x-mpegurl',
        sessionId: 's',
        streamType: 'live',
      );
      final media = payload['media'] as Map<String, dynamic>;
      expect(media['streamType'], 'live');
    });
  });
}