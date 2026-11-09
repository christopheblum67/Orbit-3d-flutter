import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/preload_candidate.dart';
import 'package:orbit_3d_flutter/models/channel.dart';

void main() {
  Channel channel(String id, String url) => Channel(
        id: id,
        name: id,
        logoUrl: '',
        streamUrl: url,
        group: '',
      );
  final channels = [
    channel('1', 'https://example.test/1'),
    channel('2', 'https://example.test/2'),
    channel('3', 'https://example.test/3'),
  ];

  ({int index, String url})? choose({
    List<Channel>? source,
    int currentIndex = 0,
    bool cached = false,
    int? pending,
    bool initialized = true,
    bool playing = true,
  }) =>
      preloadCandidate(
        channels: source ?? channels,
        currentIndex: currentIndex,
        hasCachedNext: cached,
        pendingIndex: pending,
        currentInitialized: initialized,
        currentPlaying: playing,
      );

  test('selects only the immediately following channel', () {
    expect(choose(), (index: 1, url: 'https://example.test/2'));
    expect(choose(currentIndex: 1), (index: 2, url: 'https://example.test/3'));
    expect(choose(currentIndex: 2), isNull);
    expect(choose(source: []), isNull);
  });

  test('does not duplicate cached or in-flight preload', () {
    expect(choose(cached: true), isNull);
    expect(choose(pending: 1), isNull);
    expect(choose(pending: 2), (index: 1, url: 'https://example.test/2'));
  });

  test('requires an initialized player actively playing', () {
    expect(choose(initialized: false), isNull);
    expect(choose(playing: false), isNull);
    expect(choose(initialized: false, playing: false), isNull);
  });

  test('requires a valid HTTP or HTTPS target URL', () {
    for (final url in [
      '',
      'not a url',
      'rtsp://example.test/live',
      'https://',
    ]) {
      expect(
        choose(source: [channels.first, channel('bad', url)]),
        isNull,
        reason: url,
      );
    }
    expect(
      choose(
        source: [channels.first, channel('ok', 'http://example.test/live')],
      ),
      (index: 1, url: 'http://example.test/live'),
    );
  });
}
