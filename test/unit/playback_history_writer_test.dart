import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/playback_history_writer.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';

void main() {
  final channel = Channel(
    id: 'channel',
    name: 'Live channel',
    logoUrl: 'logo',
    streamUrl: 'live-url',
    group: 'News',
  );
  const favorite = FavoriteEntry(
    type: ContentType.series,
    id: 'series',
    title: 'Series',
    posterUrl: 'poster',
    subtitle: 'Episode',
    streamUrl: 'favorite-url',
  );

  test('current channel takes precedence over favorite', () {
    final entry = playbackHistoryEntry(
      channel: channel,
      favorite: favorite,
      fallbackStreamUrl: 'fallback',
    )!;
    expect(entry.type, ContentType.live);
    expect(entry.id, 'channel');
    expect(entry.title, 'Live channel');
    expect(entry.posterUrl, 'logo');
    expect(entry.subtitle, 'News');
    expect(entry.streamUrl, 'live-url');
  });

  test('favorite retains metadata and chooses its own URL or fallback', () {
    final entry = playbackHistoryEntry(
      channel: null,
      favorite: favorite,
      fallbackStreamUrl: 'fallback',
    )!;
    expect(entry.type, ContentType.series);
    expect(entry.id, 'series');
    expect(entry.title, 'Series');
    expect(entry.posterUrl, 'poster');
    expect(entry.subtitle, 'Episode');
    expect(entry.streamUrl, 'favorite-url');
    const emptyUrl = FavoriteEntry(
      type: ContentType.vod,
      id: 'movie',
      title: 'Film',
    );
    expect(
      playbackHistoryEntry(
        channel: null,
        favorite: emptyUrl,
        fallbackStreamUrl: 'fallback',
      )!
          .streamUrl,
      'fallback',
    );
    expect(
      playbackHistoryEntry(
        channel: null,
        favorite: null,
        fallbackStreamUrl: 'fallback',
      ),
      isNull,
    );
  });

  test('starts both writes independently and awaits both', () async {
    final entry = playbackHistoryEntry(
      channel: channel,
      favorite: null,
      fallbackStreamUrl: '',
    )!;
    final recent = Completer<void>();
    final history = Completer<void>();
    final calls = <String>[];
    var finished = false;
    final result = writePlaybackHistory(
      entry: entry,
      writeRecent: (value) {
        expect(value, same(entry));
        calls.add('recent');
        return recent.future;
      },
      writeHistory: (value) {
        expect(value, same(entry));
        calls.add('history');
        return history.future;
      },
    )..then((_) => finished = true);
    expect(calls, ['recent', 'history']);
    recent.complete();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    history.complete();
    await result;
    expect(finished, isTrue);
  });

  test('reports each failure without preventing the other write', () async {
    final entry = playbackHistoryEntry(
      channel: channel,
      favorite: null,
      fallbackStreamUrl: '',
    )!;
    final original = FlutterError.presentError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.presentError = errors.add;
    addTearDown(() => FlutterError.presentError = original);
    final calls = <String>[];
    await writePlaybackHistory(
      entry: entry,
      writeRecent: (_) async {
        calls.add('recent');
        throw StateError('recent failed');
      },
      writeHistory: (_) async {
        calls.add('history');
        throw StateError('history failed');
      },
    );
    expect(calls, ['recent', 'history']);
    expect(errors.map((error) => error.library), [
      'playbackHistory.recent',
      'playbackHistory.history',
    ]);
  });
}
