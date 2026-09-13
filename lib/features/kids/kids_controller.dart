import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class KidsState {
  final AsyncValue<List<Channel>> channelsAsync;
  final AsyncValue<List<Movie>> moviesAsync;
  final AsyncValue<List<Series>> seriesAsync;
  final AsyncValue<List<ReplayItem>> replaysAsync;

  const KidsState({
    this.channelsAsync = const AsyncLoading(),
    this.moviesAsync = const AsyncLoading(),
    this.seriesAsync = const AsyncLoading(),
    this.replaysAsync = const AsyncLoading(),
  });

  KidsState copyWith({
    AsyncValue<List<Channel>>? channelsAsync,
    AsyncValue<List<Movie>>? moviesAsync,
    AsyncValue<List<Series>>? seriesAsync,
    AsyncValue<List<ReplayItem>>? replaysAsync,
  }) {
    return KidsState(
      channelsAsync: channelsAsync ?? this.channelsAsync,
      moviesAsync: moviesAsync ?? this.moviesAsync,
      seriesAsync: seriesAsync ?? this.seriesAsync,
      replaysAsync: replaysAsync ?? this.replaysAsync,
    );
  }
}

class KidsController extends Notifier<KidsState> {
  ApiService? _api;

  @override
  KidsState build() {
    return const KidsState();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadChannels(),
      loadMovies(),
      loadSeries(),
      loadReplays(),
    ]);
  }

  Future<void> loadChannels() async {
    state = state.copyWith(channelsAsync: const AsyncLoading());
    try {
      _api ??= ref.read(apiServiceProvider);
      final channels = await _api!.fetchLiveChannels();
      final kidChannels = _filterKidChannels(channels);
      state = state.copyWith(channelsAsync: AsyncData(kidChannels));
    } catch (e, st) {
      state = state.copyWith(channelsAsync: AsyncError(e, st));
    }
  }

  Future<void> loadMovies() async {
    state = state.copyWith(moviesAsync: const AsyncLoading());
    try {
      _api ??= ref.read(apiServiceProvider);
      final movies = await _api!.fetchMovies();
      final kidMovies = _filterKidMovies(movies);
      state = state.copyWith(moviesAsync: AsyncData(kidMovies));
    } catch (e, st) {
      state = state.copyWith(moviesAsync: AsyncError(e, st));
    }
  }

  Future<void> loadSeries() async {
    state = state.copyWith(seriesAsync: const AsyncLoading());
    try {
      _api ??= ref.read(apiServiceProvider);
      final series = await _api!.fetchSeries();
      final kidSeries = _filterKidSeries(series);
      state = state.copyWith(seriesAsync: AsyncData(kidSeries));
    } catch (e, st) {
      state = state.copyWith(seriesAsync: AsyncError(e, st));
    }
  }

  Future<void> loadReplays() async {
    state = state.copyWith(replaysAsync: const AsyncLoading());
    try {
      _api ??= ref.read(apiServiceProvider);
      final replays = await _api!.fetchReplays();
      final kidReplays = _filterKidReplays(replays);
      state = state.copyWith(replaysAsync: AsyncData(kidReplays));
    } catch (e, st) {
      state = state.copyWith(replaysAsync: AsyncError(e, st));
    }
  }

  List<Channel> _filterKidChannels(List<Channel> channels) {
    final filter = ref.read(contentFilterProvider);
    return channels.where((c) => !filter.isHiddenChannel(c)).toList();
  }

  List<Movie> _filterKidMovies(List<Movie> movies) {
    final filter = ref.read(contentFilterProvider);
    return movies.where((m) => !filter.isHiddenMovie(m)).toList();
  }

  List<Series> _filterKidSeries(List<Series> series) {
    final filter = ref.read(contentFilterProvider);
    return series.where((s) => !filter.isHiddenSeries(s)).toList();
  }

  List<ReplayItem> _filterKidReplays(List<ReplayItem> replays) {
    final filter = ref.read(contentFilterProvider);
    return replays.where((r) => !filter.isHiddenReplay(r)).toList();
  }

  
}

final kidsControllerProvider = NotifierProvider<KidsController, KidsState>(KidsController.new);