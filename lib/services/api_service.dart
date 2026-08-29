import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/epg_program.dart';
import '../models/replay_item.dart';
import 'subscription_manager.dart';

class ApiService {
  final Dio _dio = Dio();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  // ---------- Canaux live ----------
  Future<List<Channel>> fetchLiveChannels() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams';
      final response = await _dio.get(url);
      return (response.data as List).map((e) => Channel.fromMap(e)).toList();
    } else if (sub['type'] == 'm3u') {
      final url = sub['url']!;
      final response = await _dio.get(url);
      return parseM3u(response.data.toString());
    } else {
      throw Exception('Aucun abonnement configuré');
    }
  }

  // ---------- Films (VOD) ----------
  Future<List<Movie>> fetchMovies() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/player_api.php?username=$username&password=$password&action=get_vod_streams';
      final response = await _dio.get(url);
      return (response.data as List).map((e) => Movie.fromMap(e)).toList();
    }
    throw UnimplementedError('M3U not implemented for movies');
  }

  // ---------- Séries ----------
  Future<List<Series>> fetchSeries() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/player_api.php?username=$username&password=$password&action=get_series';
      final response = await _dio.get(url);
      return (response.data as List).map((e) => Series.fromMap(e)).toList();
    }
    throw UnimplementedError('M3U not implemented for series');
  }

  // ---------- Radios ----------
  Future<List<Channel>> fetchRadioChannels() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams&category=radio';
      final response = await _dio.get(url);
      return (response.data as List).map((e) => Channel.fromMap(e)).toList();
    }
    throw UnimplementedError('M3U not implemented for radio');
  }

  // ---------- Replays ----------
  Future<List<ReplayItem>> fetchReplays() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/player_api.php?username=$username&password=$password&action=get_simple_data_table&stream_id=replay';
      final response = await _dio.get(url);
      return (response.data as List).map((e) => ReplayItem.fromMap(e)).toList();
    }
    throw UnimplementedError('M3U not implemented for replay');
  }

  // ---------- EPG (XMLTV) ----------
  Future<List<EPGProgram>> fetchEpg() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/xmltv.php?username=$username&password=$password';
      final response = await _dio.get(url);
      return parseXmltv(response.data.toString());
    }
    throw UnimplementedError('M3U not implemented for EPG');
  }

  // ---------- Parseur M3U simple ----------
  List<Channel> parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Channel>[];
    String? currentName;
    for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        if (nameMatch != null) {
          currentName = nameMatch.group(1)!.trim();
        }
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentName != null) {
          channels.add(Channel(
            id: channels.length.toString(),
            name: currentName,
            logoUrl: '',
            streamUrl: line.trim(),
            group: '',
          ));
          currentName = null;
        }
      }
    }
    return channels;
  }

  // ---------- Parseur XMLTV basique ----------
  List<EPGProgram> parseXmltv(String content) {
    final document = XmlDocument.parse(content);
    final programs = <EPGProgram>[];
    for (final prog in document.findAllElements('programme')) {
      final channelId = prog.getAttribute('channel') ?? '';
      final title = prog.getElement('title')?.innerText ?? '';
      final desc = prog.getElement('desc')?.innerText ?? '';
      final start = DateTime.parse(prog.getAttribute('start') ?? '');
      final end = DateTime.parse(prog.getAttribute('stop') ?? '');
      programs.add(EPGProgram(
        channelId: channelId,
        title: title,
        description: desc,
        start: start,
        end: end,
      ));
    }
    return programs;
  }
}
