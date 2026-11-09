import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/xtream_epg_parser.dart';

void main() {
  final channel = Channel(
    id: '42',
    name: 'Channel',
    logoUrl: '',
    streamUrl: '',
    group: '',
    epgChannelId: ' guide-42,alternate ',
  );
  const parser = XtreamEpgParser();

  test('parses timestamps, plain dates and panel text', () {
    final title = base64.encode(utf8.encode('Journal du soir'));
    final programs = parser.parseShortGuide({
      'epg_listings': [
        {
          'start_timestamp': '1700000000',
          'stop_timestamp': 1700003600,
          'title': title,
          'plot': 'Synopsis',
        },
        {
          'start': '2024-01-01 10:00:00',
          'end': '2024-01-01 11:00:00',
          'title': 'Emission',
        },
      ],
    }, channel);
    expect(programs, hasLength(2));
    expect(programs.first.channelId, 'guide-42');
    expect(programs.first.title, 'Journal du soir');
    expect(programs.first.description, 'Synopsis');
    expect(programs.first.start.millisecondsSinceEpoch, 1700000000000);
    expect(programs.last.start, DateTime(2024, 1, 1, 10));
  });

  test('accepts a list and rejects empty titles and invalid intervals', () {
    final bare = Channel(
      id: '42',
      name: '',
      logoUrl: '',
      streamUrl: '',
      group: '',
    );
    final result = parser.parseShortGuide([
      {'start_timestamp': 10, 'stop_timestamp': 20, 'title': 'News'},
      {'start_timestamp': 10, 'stop_timestamp': 10, 'title': 'Invalid'},
      {'start': 'not a date', 'end': '2024-01-01', 'title': 'Invalid'},
      {'start_timestamp': 10, 'stop_timestamp': 20, 'title': ''},
    ], bare);
    expect(result, hasLength(1));
    expect(result.single.channelId, '42');
    expect(parser.parseShortGuide(null, bare), isEmpty);
    expect(XtreamEpgParser.parseDate(' '), isNull);
  });
}
