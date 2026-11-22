import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  test('M3U episode channels apply the profile filter individually', () async {
    final show = Series(
      id: 'show',
      title: 'Family show',
      description: '',
      coverUrl: '',
      year: 0,
      genre: 'Series',
      director: '',
      rating: 0,
      pegi: '',
      episodes: [
        Episode(id: 'safe', title: 'Welcome', season: 1, episodeNumber: 1),
        Episode(id: 'adult', title: 'Adult', season: 1, episodeNumber: 2),
        Episode(id: 'hidden', title: 'Hidden', season: 1, episodeNumber: 3),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        contentFilterProvider.overrideWithValue(
          ContentFilter(
            hiddenContentIds: {'hidden'},
            hideAdultContent: true,
            hideViolentContent: false,
          ),
        ),
        activeSubscriptionProvider.overrideWith(
          (ref) => Subscription(
            id: 'm3u',
            name: 'Playlist',
            type: SubscriptionType.m3u,
            createdAt: DateTime(2026),
          ),
        ),
        seriesProvider.overrideWith((ref) async => [show]),
      ],
    );
    addTearDown(container.dispose);

    final channels = await container.read(seriesChannelsProvider.future);
    expect(channels.map((channel) => channel.id), ['safe']);
    final shows = await container.read(m3uSeriesProvider.future);
    expect(shows.single.episodes.map((episode) => episode.id), ['safe']);
  });

  test('catch-up retains a programme that crosses the archive boundary',
      () async {
    final now = DateTime.now();
    EPGProgram program(String title, Duration startAgo, Duration endAgo) =>
        EPGProgram(
          channelId: '1',
          title: title,
          description: '',
          start: now.subtract(startAgo),
          end: now.subtract(endAgo),
        );
    final channel = Channel(
      id: '1',
      name: 'Channel',
      logoUrl: '',
      streamUrl: '',
      group: '',
      archiveDays: 2,
    );
    final container = ProviderContainer(
      overrides: [
        activeSubscriptionProvider.overrideWith((ref) => null),
        liveChannelsProvider.overrideWith((ref) async => [channel]),
      ],
    );
    addTearDown(container.dispose);
    container.read(catchUpEpgCacheProvider).put('1', [
      program(
        'crossing',
        const Duration(days: 2, hours: 1),
        const Duration(days: 1, hours: 23),
      ),
      program(
        'expired',
        const Duration(days: 2, hours: 2),
        const Duration(days: 2, hours: 1),
      ),
      program('future', const Duration(hours: 1), const Duration(hours: -1)),
    ]);
    final listener = container.listen(channelCatchUpProvider('1'), (_, __) {});
    addTearDown(listener.close);

    final programs = await container.read(channelCatchUpProvider('1').future);
    expect(programs.map((program) => program.title), ['crossing']);
  });
}
