import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Énumère les étapes de la régénération des flux au démarrage.
enum StartupStep {
  live('Chaînes live'),
  movies('Films & VOD'),
  series('Séries'),
  radio('Radios'),
  replay('Replays'),
  epg('Guide TV (EPG)'),
  ai('Recommandations');

  const StartupStep(this.label);
  final String label;
}

/// Contrôleur de l'écran de démarrage : régénère tous les flux en parallèle
/// et expose une progression en %, ainsi que les contenus récupérés qui
/// serviront aux recommandations personnalisées.
class StartupRefreshController extends ChangeNotifier {
  final ApiService _api;
  final Set<StartupStep> _todo;
  final Set<StartupStep> _done = {};

  // Poids de chaque étape dans la progression globale.
  static const Map<StartupStep, double> _weights = {
    StartupStep.live: 0.22,
    StartupStep.movies: 0.22,
    StartupStep.series: 0.20,
    StartupStep.radio: 0.06,
    StartupStep.replay: 0.12,
    StartupStep.epg: 0.10,
    StartupStep.ai: 0.08,
  };

  bool _started = false;
  bool _finished = false;
  StartupStep? _current;
  Object? _error;
  bool _skippedEpg = false;

  List<Movie> movies = const [];
  List<Series> series = const [];

  StartupRefreshController(this._api, {Set<StartupStep>? steps})
      : _todo = steps ??
            {
              StartupStep.live,
              StartupStep.movies,
              StartupStep.series,
              StartupStep.radio,
              StartupStep.replay,
              StartupStep.epg,
              StartupStep.ai,
            };

  double get progress {
    if (_todo.isEmpty) return 1.0;
    var total = 0.0;
    for (final step in _todo) {
      total += _weights[step] ?? 0.1;
    }
    var completed = 0.0;
    for (final step in _done) {
      if (_todo.contains(step)) completed += _weights[step] ?? 0.1;
    }
    return (completed / total).clamp(0.0, 1.0);
  }

  int get percent => (progress * 100).round();

  bool get isFinished => _finished;
  StartupStep? get currentStep => _current;
  Object? get error => _error;

  /// Ne met l'EPG de côté qu'une fois pour éviter un blocage long au démarrage.
  bool get skippedEpg => _skippedEpg;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final futures = <Future<void>>[];

    for (final step in _todo) {
      switch (step) {
        case StartupStep.live:
          futures.add(_run(step, () async {
            await _api.fetchLiveChannels();
          },),);
        case StartupStep.movies:
          futures.add(_run(step, () async {
            final list = await _api.fetchMovies();
            movies = list;
          },),);
        case StartupStep.series:
          futures.add(_run(step, () async {
            final list = await _api.fetchSeries();
            series = list;
          },),);
        case StartupStep.radio:
          futures.add(_run(step, () async {
            await _api.fetchRadioChannels();
          },),);
        case StartupStep.replay:
          futures.add(_run(step, () async {
            await _api.fetchReplays();
          },),);
        case StartupStep.epg:
          futures.add(_run(step, () async {
            try {
              await _api.fetchEpg();
            } finally {
              // Marqué comme traité même en erreur (non bloquant).
            }
          },),);
        case StartupStep.ai:
          // L'étape IA est purement indicative : on la marque instantanément
          // comme faite pour que la progression reste fluide sans latence.
          futures.add(_run(step, () async {},),);
      }
    }

    await Future.wait(futures);
    _finished = true;
    _current = null;
    notifyListeners();
  }

  Future<void> _run(StartupStep step, Future<void> Function() action) async {
    _current = step;
    notifyListeners();
    try {
      await action();
      _done.add(step);
    } catch (e) {
      _error = e;
      // On marque l'étape comme faite pour ne pas bloquer le démarrage :
      // un échec réseau ne doit pas empêcher l'accès à l'application.
      _done.add(step);
      if (step == StartupStep.epg) _skippedEpg = true;
    } finally {
      notifyListeners();
    }
  }
}