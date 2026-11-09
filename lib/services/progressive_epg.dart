import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Limits preview requests to one at a time across rapid channel changes.
class ShortEpgRequestGate {
  Future<void>? _active;

  Future<List<EPGProgram>> start(
    Future<List<EPGProgram>> Function() request,
    bool Function() shouldStart,
  ) async {
    while (_active != null) {
      await _active;
    }
    if (!shouldStart()) return const <EPGProgram>[];
    final result = Future.sync(request);
    final active =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _active = active;
    try {
      return await result;
    } finally {
      if (identical(_active, active)) _active = null;
    }
  }
}

Stream<List<EPGProgram>> progressiveEpg({
  required Future<List<EPGProgram>> Function() loadFull,
  required Future<List<EPGProgram>>? Function(bool Function()) startShort,
  List<EPGProgram>? cachedShort,
  Duration debounce = const Duration(milliseconds: 800),
}) {
  late final StreamController<List<EPGProgram>> controller;
  Timer? timer;
  var stopped = false;
  var fullDone = false;
  var fullHasData = false;
  var shortDone = false;
  var hasData = false;
  Object? fullError;
  StackTrace? fullStack;

  void finishIfReady() {
    if (!fullDone || !shortDone || stopped) return;
    if (!hasData) {
      if (fullError != null) {
        controller.addError(fullError!, fullStack);
      } else {
        controller.add(const <EPGProgram>[]);
      }
    }
    unawaited(controller.close());
  }

  void emit(List<EPGProgram> programs) {
    if (stopped || programs.isEmpty) return;
    hasData = true;
    controller.add(programs);
  }

  controller = StreamController<List<EPGProgram>>(
    onListen: () {
      if (cachedShort != null && cachedShort.isNotEmpty) {
        emit(cachedShort);
        shortDone = true;
      } else {
        timer = Timer(debounce, () {
          if (stopped || fullHasData) return;
          final short = startShort(() => !stopped && !fullHasData);
          if (short == null) {
            shortDone = true;
            finishIfReady();
            return;
          }
          short.then((programs) {
            if (!fullHasData) emit(programs);
            shortDone = true;
            finishIfReady();
          }, onError: (Object error, StackTrace stack) {
            LoggerService.instance.warning(
              'EPG court indisponible (${error.runtimeType})',
            );
            shortDone = true;
            finishIfReady();
          });
        });
      }
      Future.sync(loadFull).then((programs) {
        if (stopped) return;
        fullHasData = programs.isNotEmpty;
        if (fullHasData) {
          timer?.cancel();
          shortDone = true;
        }
        fullDone = true;
        emit(programs);
        finishIfReady();
      }, onError: (Object error, StackTrace stack) {
        if (stopped) return;
        fullDone = true;
        fullError = error;
        fullStack = stack;
        LoggerService.instance.warning(
          'EPG complet indisponible (${error.runtimeType})',
        );
        finishIfReady();
      });
    },
    onCancel: () {
      stopped = true;
      timer?.cancel();
    },
  );
  return controller.stream;
}
