import 'package:flutter/foundation.dart';

/// Entrée du circuit breaker pour un hôte donné.
class _HostBreakerState {
  _HostBreakerState();

  int failureCount = 0;
  DateTime? lastFailure;
  DateTime? cooldownUntil;

  bool get isInCooldown =>
      cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);

  Duration get remainingCooldown {
    if (cooldownUntil == null) return Duration.zero;
    final remaining = cooldownUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void recordFailure({Duration cooldown = const Duration(seconds: 90)}) {
    failureCount++;
    lastFailure = DateTime.now();
    if (failureCount >= 2) {
      cooldownUntil = DateTime.now().add(cooldown);
      if (kDebugMode) {
        debugPrint(
            'HostCircuitBreaker: host entered cooldown until $cooldownUntil');
      }
    }
  }

  void recordSuccess() {
    failureCount = 0;
    lastFailure = null;
    cooldownUntil = null;
  }

  void reset() {
    failureCount = 0;
    lastFailure = null;
    cooldownUntil = null;
  }
}

/// Service singleton gérant le cooldown par hôte (circuit breaker)
/// pour éviter de marteler un serveur qui répond 401/403/timeout.
class HostCircuitBreaker extends ChangeNotifier {
  HostCircuitBreaker._internal();

  static final HostCircuitBreaker instance = HostCircuitBreaker._internal();

  final Map<String, _HostBreakerState> _states = {};

  _HostBreakerState _getState(String host) =>
      _states.putIfAbsent(host, _HostBreakerState.new);

  /// Vérifie si l'hôte est en cooldown.
  bool isInCooldown(String host) => _getState(host).isInCooldown;

  /// Retourne la durée restante du cooldown pour l'hôte.
  Duration remainingCooldown(String host) => _getState(host).remainingCooldown;

  /// Enregistre un échec pour l'hôte (401, Source error, timeout, etc.).
  /// Si failureCount >= 2, met l'hôte en cooldown pour [cooldown] durée.
  void recordFailure(String host,
      {Duration cooldown = const Duration(seconds: 90)}) {
    _getState(host).recordFailure(cooldown: cooldown);
    notifyListeners();
  }

  /// Enregistre un succès pour l'hôte (remet le compteur à zéro).
  void recordSuccess(String host) {
    _getState(host).recordSuccess();
    notifyListeners();
  }

  /// Réinitialise l'état pour un hôte (utile pour tests ou reset manuel).
  void resetHost(String host) {
    _getState(host).reset();
    notifyListeners();
  }

  /// Réinitialise tous les hôtes.
  void resetAll() {
    for (final state in _states.values) {
      state.reset();
    }
    notifyListeners();
  }

  /// Message formaté pour l'UI si l'hôte est en cooldown.
  String? cooldownMessage(String host) {
    final state = _getState(host);
    if (!state.isInCooldown) return null;
    final seconds = state.remainingCooldown.inSeconds;
    return 'Serveur protégé (anti-leech), nouvelle tentative dans ${seconds}s';
  }
}
