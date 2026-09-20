import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
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
    final result = await safeAsync<List<Channel>>(
      () async {
        _api ??= ref.read(apiServiceProvider);
        final channels = await _api!.fetchLiveChannels();
        return _filterKidChannels(channels);
      },
      context: 'KidsController.loadChannels',
    );
    if (result.isSuccess) {
      state = state.copyWith(channelsAsync: AsyncData(result.valueOrNull!));
    } else {
      final e = result.errorOrNull!;
      state = state.copyWith(
        channelsAsync: AsyncError(
          e.originalError ?? e,
          e.stackTrace ?? StackTrace.current,
        ),
      );
    }
  }

  Future<void> loadMovies() async {
    state = state.copyWith(moviesAsync: const AsyncLoading());
    final result = await safeAsync<List<Movie>>(
      () async {
        _api ??= ref.read(apiServiceProvider);
        final movies = await _api!.fetchMovies();
        return _filterKidMovies(movies);
      },
      context: 'KidsController.loadMovies',
    );
    if (result.isSuccess) {
      state = state.copyWith(moviesAsync: AsyncData(result.valueOrNull!));
    } else {
      final e = result.errorOrNull!;
      state = state.copyWith(
        moviesAsync: AsyncError(
          e.originalError ?? e,
          e.stackTrace ?? StackTrace.current,
        ),
      );
    }
  }

  Future<void> loadSeries() async {
    state = state.copyWith(seriesAsync: const AsyncLoading());
    final result = await safeAsync<List<Series>>(
      () async {
        _api ??= ref.read(apiServiceProvider);
        final series = await _api!.fetchSeries();
        return _filterKidSeries(series);
      },
      context: 'KidsController.loadSeries',
    );
    if (result.isSuccess) {
      state = state.copyWith(seriesAsync: AsyncData(result.valueOrNull!));
    } else {
      final e = result.errorOrNull!;
      state = state.copyWith(
        seriesAsync: AsyncError(
          e.originalError ?? e,
          e.stackTrace ?? StackTrace.current,
        ),
      );
    }
  }

  Future<void> loadReplays() async {
    state = state.copyWith(replaysAsync: const AsyncLoading());
    final result = await safeAsync<List<ReplayItem>>(
      () async {
        _api ??= ref.read(apiServiceProvider);
        final replays = await _api!.fetchReplays();
        return _filterKidReplays(replays);
      },
      context: 'KidsController.loadReplays',
    );
    if (result.isSuccess) {
      state = state.copyWith(replaysAsync: AsyncData(result.valueOrNull!));
    } else {
      final e = result.errorOrNull!;
      state = state.copyWith(
        replaysAsync: AsyncError(
          e.originalError ?? e,
          e.stackTrace ?? StackTrace.current,
        ),
      );
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