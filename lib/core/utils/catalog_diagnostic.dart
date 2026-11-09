import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/app_log.dart';

int _nextDiagnosticId = 0;

/// Les noms doivent être des constantes internes, jamais des données utilisateur.
Future<T> traceCatalogStep<T>(
  String kind,
  String step,
  Future<T> Function() action, {
  void Function(String) log = logDiag,
  Duration warningAfter = const Duration(seconds: 15),
}) async {
  final id = ++_nextDiagnosticId;
  final stopwatch = Stopwatch()..start();
  final prefix = 'CATALOG id=$id kind=$kind step=$step';
  log('$prefix state=start');
  final timer = Timer(warningAfter, () {
    log('$prefix state=waiting elapsedMs=${stopwatch.elapsedMilliseconds}');
  });
  try {
    final result = await action();
    log('$prefix state=complete durationMs=${stopwatch.elapsedMilliseconds}');
    return result;
  } catch (error) {
    log('$prefix state=failed durationMs=${stopwatch.elapsedMilliseconds} '
        'errorType=${error.runtimeType}');
    rethrow;
  } finally {
    timer.cancel();
    stopwatch.stop();
  }
}
