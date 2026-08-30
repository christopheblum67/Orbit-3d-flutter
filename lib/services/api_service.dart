import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../models/epg_program.dart';
import '../models/replay_item.dart';
import 'stream_helpers.dart' as stream_helpers;
import 'subscription_manager.dart';

class StreamNetworkException implements Exception {
  StreamNetworkException(this.message, {this.original, this.isRetriable = false});

  final String message;
  final Object? original;
  final bool isRetriable;

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    followRedirects: true,
    maxRedirects: 5,
  ));
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  Future<Response<dynamic>> _get(String url) {
    return stream_helpers.retryStream(
      () => _performGet(url),
      attempts: 2,
      shouldRetry: (error) {
        if (error is StreamNetworkException) return error.isRetriable;
        return true;
      },
    );
  }

  Future<Response<dynamic>> _performGet(String url) async {
    try {
      return await _dio.get<dynamic>(url);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  StreamNetworkException _toNetworkException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return StreamNetworkException(
          'Délai de connexion au serveur dépassé (15 s). '
          'Vérifiez votre connexion Internet et la disponibilité du serveur.',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.sendTimeout:
        return StreamNetworkException(
          'Délai d\'envoi dépassé (15 s). Le serveur ne répond pas correctement.',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.receiveTimeout:
        return StreamNetworkException(
          'Le serveur met trop de temps à répondre (30 s). '
          'Le flux est peut-être indisponible ou bloqué (ex. Cloudflare).',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.transformTimeout:
        return StreamNetworkException(
          'La réponse du serveur n\'a pas pu être traitée à temps. '
          'Le flux est peut-être indisponible ou bloqué (ex. Cloudflare).',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.connectionError:
        return StreamNetworkException(
          'Impossible de se connecter au serveur. '
          'Vérifiez votre réseau et l\'accès au serveur.',
          original: e,
          isRetriable: true,
        );
      case DioExceptionType.badCertificate:
        return StreamNetworkException(
          'Certificat de sécurité invalide. '
          'Vérifiez la configuration HTTPS du serveur.',
          original: e,
        );
      case DioExceptionType.cancel:
        return StreamNetworkException('Requête annulée.', original: e);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final message = switch (status) {
          401 => 'Accès refusé par le serveur (code 401). '
              'Vérifiez vos identifiants Xtream.',
          403 => 'Accès refusé par le serveur (code 403). '
              'L\'abonnement est peut-être bloqué.',
          404 => 'Ressource introuvable (code 404). '
              'Vérifiez l\'adresse du serveur.',
          _ => 'Le serveur a renvoyé une erreur (code ${status ?? 'inconnu'}).',
        };
        return StreamNetworkException(message, original: e);
      case DioExceptionType.unknown:
        return StreamNetworkException(
          'Erreur réseau inattendue : ${e.message ?? e.runtimeType}.',
          original: e,
          isRetriable: true,
        );
    }
  }

  // ---------- Canaux live ----------
  Future<List<Channel>> fetchLiveChannels() async {
    final sub = await _subscriptionManager.getActiveSubscription();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams';
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final streamUrl = _buildXtreamStreamUrl(baseUrl, username, password, map['stream_id']?.toString());
        final channel = Channel.fromMap(map).copyWith(streamUrl: streamUrl);
        channel.requireStreamUrl();
        return channel;
      }).toList();
    } else if (sub['type'] == 'm3u') {
      final url = sub['url']!;
      final response = await _get(url);
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
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final streamUrl = _buildXtreamStreamUrl(baseUrl, username, password, map['stream_id']?.toString(), type: 'movie');
        final movie = Movie.fromMap(map).copyWith(streamUrl: streamUrl);
        movie.requireStreamUrl();
        return movie;
      }).toList();
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
      final response = await _get(url);
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
      final response = await _get(url);
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
      final response = await _get(url);
      return (response.data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        final id = map['stream_id']?.toString() ?? '';
        final streamUrl = id.isEmpty
            ? ''
            : '$baseUrl/player_api.php?username=$username&password=$password&stream=$id&start=${map['start'] ?? ''}&end=${map['end'] ?? ''}';
        final replay = ReplayItem.fromMap(map).copyWith(streamUrl: streamUrl);
        replay.requireStreamUrl();
        return replay;
      }).toList();
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
      final response = await _get(url);
      return parseXmltv(response.data.toString());
    }
    throw UnimplementedError('M3U not implemented for EPG');
  }

  // ---------- Parseur M3U simple ----------
  String _buildXtreamStreamUrl(String baseUrl, String username, String password, String? streamId, {String type = ''}) {
    if (streamId == null || streamId.isEmpty) return '';
    final typeParam = type.isEmpty ? '' : '&type=$type';
    return '$baseUrl/player_api.php?username=$username&password=$password&stream=$streamId$typeParam';
  }

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
            streamUrl: stream_helpers.requireStreamUrl(line.trim(), label: currentName),
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