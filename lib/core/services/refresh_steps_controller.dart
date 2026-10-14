import 'package:flutter/foundation.dart';

import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Étapes de la régénération des flux (catalogue, EPG, replays).
///
/// Vit ici (et non dans l'écran de démarrage) pour être partagée entre :
/// — l'écran de démarrage ([StartupRefreshController]) ;
/// — le rafraîchissement à la demande (`RefreshProgressScreen`), déclenché au
///   lancement quand les données ont plus de 30 min, et sur « Mettre à jour ».
///
/// `startup_refresh_controller.dart` ré-exporte cet enum : les imports
/// existants (`show StartupStep`) continuent de fonctionner.
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

/// Poids de chaque étape dans la progression globale (%).
///
/// Partagé par les deux contrôleurs pour que la barre avance identiquement,
/// qu'on soit au démarrage ou sur un rafraîchissement à la demande.
const Map<StartupStep, double> kRefreshStepWeights = {
  StartupStep.live: 0.22,
  StartupStep.movies: 0.22,
  StartupStep.series: 0.20,
  StartupStep.radio: 0.06,
  StartupStep.replay: 0.12,
  StartupStep.epg: 0.10,
  StartupStep.ai: 0.08,
};

/// Comptabilité d'une séquence d'étapes de régénération des flux.
///
/// **Purement observationnelle** : ne connaît ni Riverpod ni le réseau.
/// L'appelant fournit le travail de chaque étape via [run] ; la classe se
/// contente d'exposer une progression pondérée, l'étape courante et l'ensemble
/// des étapes terminées — exactement ce que consomme `RefreshProgressView`.
///
/// Chaque étape est marquée « terminée » même en cas d'échec : une panne réseau
/// ne doit jamais bloquer la barre de progression ni l'accès à l'application.
class RefreshStepsController extends ChangeNotifier {
  RefreshStepsController({required Set<StartupStep> steps}) : _todo = steps;

  final Set<StartupStep> _todo;
  final Set<StartupStep> _done = {};
  bool _started = false;
  bool _finished = false;
  bool _disposed = false;
  StartupStep? _current;
  Object? _error;
  bool _skippedEpg = false;

  Set<StartupStep> get doneSteps => _done;
  bool get isFinished => _finished;
  StartupStep? get currentStep => _current;
  Object? get error => _error;

  /// Vrai si l'étape EPG a échoué (à signaler, sans bloquer).
  bool get skippedEpg => _skippedEpg;

  /// Progression pondérée dans `[0, 1]`.
  double get progress {
    if (_todo.isEmpty) return 1.0;
    var total = 0.0;
    for (final step in _todo) {
      total += kRefreshStepWeights[step] ?? 0.1;
    }
    var completed = 0.0;
    for (final step in _done) {
      if (_todo.contains(step)) completed += kRefreshStepWeights[step] ?? 0.1;
    }
    return (completed / total).clamp(0.0, 1.0);
  }

  int get percent => (progress * 100).round();

  /// Exécute les étapes de [_todo], une à une, via [action].
  ///
  /// Séquentiel volontairement : lancer toutes les requêtes en parallèle sature
  /// le rate-limit du panel (429) et fait échouer l'ensemble. Le court répit
  /// entre deux étapes laisse respirer le serveur.
  Future<void> run(
    Future<void> Function(StartupStep step) action, {
    Duration gap = const Duration(milliseconds: 250),
  }) async {
    if (_started) return;
    _started = true;

    for (final step in _todo) {
      if (_disposed) return;
      await _run(step, () => action(step));
      await Future<void>.delayed(gap);
    }

    _finished = true;
    _current = null;
    _notify();
  }

  Future<void> _run(StartupStep step, Future<void> Function() action) async {
    _current = step;
    _notify();
    final result = await safeAsync<void>(
      () => action(),
      context: 'RefreshStepsController._run(${step.name})',
    );
    if (result.isFailure) {
      _error = result.errorOrNull?.originalError ?? result.errorOrNull;
      if (step == StartupStep.epg) _skippedEpg = true;
    }
    _done.add(step);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
