import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/device_info.dart';

/// Garde-fou centralisé pour le mode TV
///
/// Combine :
/// - Etat initial via détection multi-méthodes
/// - Activation manuelle (première interaction clavier/D-pad)
/// - Désactivation forcée si nécessaire
class TvModeController extends ChangeNotifier {
  bool _enabled = false;
  bool _autoDetected = false;
  DeviceDetectionResult? _detectionResult;

  bool get enabled => _enabled;
  bool get autoDetected => _autoDetected;
  DeviceDetectionResult? get detectionResult => _detectionResult;

  /// Active le mode TV manuellement (ex. première pression D-pad)
  void enable() {
    if (!_enabled) {
      _enabled = true;
      notifyListeners();
    }
  }

  /// Désactive le mode TV
  void disable() {
    if (_enabled) {
      _enabled = false;
      notifyListeners();
    }
  }

  /// Force l'état (pour tests/debug)
  void setEnabled(bool v) {
    if (_enabled != v) {
      _enabled = v;
      notifyListeners();
    }
  }

  /// Met à jour depuis la détection automatique
  Future<void> updateFromDetection(DeviceDetectionResult result) async {
    _detectionResult = result;
    if (result.isTv && !_autoDetected) {
      _autoDetected = true;
      if (!_enabled) {
        _enabled = true;
        notifyListeners();
      }
    }
    // Si pas TV détecté automatiquement, on garde l'état actuel
    // (peut être activé manuellement plus tard)
  }

  /// Reset pour tests
  void reset() {
    _enabled = false;
    _autoDetected = false;
    _detectionResult = null;
    notifyListeners();
  }
}

/// Provider central pour le mode TV
final tvModeControllerProvider = Provider<TvModeController>(
  (ref) {
    final controller = TvModeController();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Provider booléen pratique (lecteur direct)
final tvModeProvider = Provider<bool>((ref) {
  return ref.watch(tvModeControllerProvider).enabled;
});
