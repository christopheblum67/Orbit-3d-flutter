import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/epg_program.dart';
import 'subscription_manager.dart';

class ApiService {
  final Dio _dio = Dio();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  // ---------- Canaux en direct ----------
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

  // ---------- EPG (XMLTV) ----------
  Future<List<EPGProgram>> fetchEpg(String epgUrl) async {
    final response = await _dio.get(epgUrl);
    return parseXmltv(response.data.toString());
  }

  // ---------- Parseur M3U simple ----------
  List<Channel> parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Channel>[];
    String? currentName;
    for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        // Format : #EXTINF:-1 tvg-id="..." tvg-name="..." group-title="...", Nom
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        if (nameMatch != null) {
          currentName = nameMatch.group(1)!.trim();
        }
        // Extraction du logo éventuel
        // Pour simplifier, on stocke juste le nom; les autres attributs seront extraits si besoin
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentName != null) {
          channels.add(Channel(
            id: channels.length.toString(),
            name: currentName,
            logoUrl: '', // à améliorer avec tvg-logo
            streamUrl: line.trim(),
            group: '', // à améliorer avec group-title
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
