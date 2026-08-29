import 'package:dio/dio.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import 'subscription_manager.dart';

class ApiService {
  final Dio _dio = Dio();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

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
      // TODO: parser le fichier M3U
      throw UnimplementedError('M3U parsing not yet implemented');
    } else {
      throw Exception('Aucun abonnement configuré');
    }
  }

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
}
