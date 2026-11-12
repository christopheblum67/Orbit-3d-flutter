import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/xtream_replay_service.dart';

Channel channel(String id, {int days = 7}) => Channel(
      id: id,
      name: 'Channel $id',
      logoUrl: '',
      streamUrl: '',
      group: 'Group $id',
      supportsReplay: true,
      archiveDays: days,
      epgChannelId: 'epg-$id,other-$id',
    );

Map<String, dynamic> program(DateTime start, DateTime end, String title) => {
      'start_timestamp': start.millisecondsSinceEpoch ~/ 1000,
      'stop_timestamp': end.millisecondsSinceEpoch ~/ 1000,
      'title': base64.encode(utf8.encode(title)),
      'description': 'Synopsis',
    };

XtreamReplayService service({
  required Future<Response<dynamic>> Function(String) get,
  Future<List<Channel>> Function()? channels,
}) =>
    XtreamReplayService(
      activeSub: () async => {
        'type': 'xtream',
        'baseUrl': 'https://example.test',
        'username': 'u',
        'password': 'p',
      },
      get: get,
      buildApiUrl: (base, script, params) => Uri.parse('$base/$script')
          .replace(queryParameters: params)
          .toString(),
      fetchLiveChannels: channels ?? () async => [],
    );

void main() {
  test('channel EPG uses the shared transport and parses its short guide',
      () async {
    final requests = <Uri>[];
    final api = service(get: (url) async {
      requests.add(Uri.parse(url));
      return Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: {
          'epg_listings': [
            program(
                DateTime(2026, 1, 1, 10), DateTime(2026, 1, 1, 11), 'Journal'),
          ],
        },
      );
    });
    final programs = await api.fetchChannelEpgPrograms(channel('123'));
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['action'], 'get_short_epg');
    expect(requests.single.queryParameters['stream_id'], '123');
    expect(programs.single.channelId, 'epg-123');
    expect(programs.single.title, 'Journal');
  });

  test('full guide filters, sorts, deduplicates and builds timeshift URLs',
      () async {
    final now = DateTime.now();
    final past = now.subtract(const Duration(hours: 3));
    final entry = program(past, past.add(const Duration(hours: 1)), 'Journal');
    final actions = <String>[];
    final api = service(get: (url) async {
      actions.add(Uri.parse(url).queryParameters['action']!);
      return Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: {
          'epg_programmes': [
            entry,
            entry,
            program(now.add(const Duration(hours: 1)),
                now.add(const Duration(hours: 2)), 'Future'),
            program(now.subtract(const Duration(days: 8)),
                now.subtract(const Duration(days: 8, hours: -1)), 'Old'),
          ],
        },
      );
    });
    final result = await api.fetchChannelReplays(channel('123'));
    expect(actions, ['get_simple_data_table']);
    expect(result, hasLength(1));
    expect(result.single.title, 'Journal');
    expect(result.single.description, 'Synopsis');
    expect(result.single.streamUrl, contains('/timeshift/u/p/60/'));
  });

  for (final fullGuide in [true, false]) {
    test(
        'undeclared retention keeps all returned programs in '
        '${fullGuide ? "full" : "short"} guide', () async {
      final now = DateTime.now();
      final api = service(get: (url) async {
        final action = Uri.parse(url).queryParameters['action'];
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          data: action == 'get_simple_data_table' && !fullGuide
              ? <dynamic>[]
              : {
                  'epg_listings': [
                    program(
                        now.subtract(const Duration(days: 6)),
                        now.subtract(const Duration(days: 6, hours: -1)),
                        'Ancien programme'),
                    program(now.subtract(const Duration(hours: 3)),
                        now.subtract(const Duration(hours: 2)), 'Recent'),
                    program(now.add(const Duration(hours: 1)),
                        now.add(const Duration(hours: 2)), 'Future'),
                  ],
                },
        );
      });

      final unknown = await api.fetchChannelReplays(channel('1', days: 0));
      expect(unknown.map((item) => item.title),
          containsAll(['Ancien programme', 'Recent']));
      expect(unknown.map((item) => item.title), isNot(contains('Future')));
      final twoDays = await api.fetchChannelReplays(channel('1', days: 2));
      expect(twoDays.map((item) => item.title), ['Recent']);
      final sevenDays = await api.fetchChannelReplays(channel('1', days: 7));
      expect(sevenDays.map((item) => item.title),
          containsAll(['Ancien programme', 'Recent']));
    });
  }

  test('falls back to short guide when the full guide is empty', () async {
    final now = DateTime.now();
    final actions = <String>[];
    final past = program(
      now.subtract(const Duration(hours: 2)),
      now.subtract(const Duration(hours: 1)),
      'Past',
    )..['presenter'] = 'Presenter';
    final api = service(get: (url) async {
      final query = Uri.parse(url).queryParameters;
      actions.add(query['action']!);
      if (query['action'] == 'get_short_epg') {
        expect(query['limit'], '100');
      }
      return Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        data: query['action'] == 'get_short_epg'
            ? {
                'epg_listings': [
                  past,
                  past,
                ],
              }
            : <dynamic>[],
      );
    });
    final result = await api.fetchChannelReplays(channel('1'));
    expect(actions, ['get_simple_data_table', 'get_short_epg']);
    expect(result.map((item) => item.title), ['Past', 'Past']);
    expect(result.first.host, 'Presenter');
    expect(result.first.streamUrl, contains('/timeshift/u/p/60/'));
  });

  test('probe uses at most two workers and respects the 40-channel budget',
      () async {
    var active = 0;
    var maxActive = 0;
    var requests = 0;
    final all = List.generate(45, (i) => channel('$i'));
    final api = service(
      channels: () async => all,
      get: (url) async {
        active++;
        if (active > maxActive) maxActive = active;
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        active--;
        return Response<dynamic>(
          requestOptions: RequestOptions(path: url),
          data: <dynamic>[],
        );
      },
    );
    expect(await api.fetchReplays(), isEmpty);
    expect(requests, 40);
    expect(maxActive, 2);
  });
}
