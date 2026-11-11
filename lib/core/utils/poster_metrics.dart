import 'package:orbit_3d_flutter/core/utils/app_log.dart';

/// Mesures de chargement des posters, actives uniquement avec
/// `--dart-define=POSTER_METRICS=true`. Aucune URL n'est journalisée.
class PosterMetrics {
  PosterMetrics._();

  static const bool enabled =
      bool.fromEnvironment('POSTER_METRICS', defaultValue: false);
  static const int _reportEvery = 40;

  static final List<int> _latenciesMs = [];
  static int _immediate = 0;
  static int _errors = 0;
  static int _disposedBeforeLoad = 0;
  static int _deferred = 0;

  /// Tuile dont le chargement a été retardé pendant un scroll rapide.
  static void recordDeferred() => _deferred++;

  /// Image affichée sans passer par le placeholder (cache mémoire/disque rapide).
  static void recordImmediate() {
    _immediate++;
    _maybeReport();
  }

  static void recordLoaded(int latencyMs) {
    _latenciesMs.add(latencyMs);
    _maybeReport();
  }

  static void recordError() {
    _errors++;
    _maybeReport();
  }

  /// Tuile sortie de l'écran avant la fin du chargement (scroll rapide).
  static void recordAbandoned() {
    _disposedBeforeLoad++;
  }

  static void _maybeReport() {
    final total = _immediate + _errors + _latenciesMs.length;
    if (total == 0 || total % _reportEvery != 0) return;
    final sorted = [..._latenciesMs]..sort();
    int pct(double p) =>
        sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * p).round()];
    logDiag(
      'PosterMetrics total=$total immediat=$_immediate '
      'charges=${sorted.length} erreurs=$_errors '
      'abandonnes=$_disposedBeforeLoad differes=$_deferred '
      'p50=${pct(0.5)}ms p90=${pct(0.9)}ms max=${sorted.isEmpty ? 0 : sorted.last}ms',
    );
    _latenciesMs.clear();
    _immediate = 0;
    _errors = 0;
    _disposedBeforeLoad = 0;
    _deferred = 0;
  }
}
