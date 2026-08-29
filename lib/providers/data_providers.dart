import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/series.dart';
import '../services/api_service.dart';
import 'providers.dart';

final liveChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchLiveChannels();
});

final moviesProvider = FutureProvider<List<Movie>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchMovies();
});

final seriesProvider = FutureProvider<List<Series>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSeries();
});
