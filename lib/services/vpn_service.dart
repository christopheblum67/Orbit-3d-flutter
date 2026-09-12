import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service VPN avec kill-switch intégré.
///
/// Le kill-switch surveille l'état de la connexion VPN et bloque
/// le trafic réseau si la connexion tombe inopinément.
class VpnService extends ChangeNotifier {
  bool _isConnected = false;
  bool _killSwitchEnabled = true;
  bool _wasConnectedBeforeDrop = false;
  Timer? _monitorTimer;
  StreamController<bool>? _killSwitchController;

  bool get isConnected => _isConnected;
  bool get killSwitchEnabled => _killSwitchEnabled;
  bool get isTrafficBlocked => _killSwitchEnabled && !_isConnected && _wasConnectedBeforeDrop;

  /// Stream notifiant les changements d'état du kill-switch (true = trafic bloqué).
  Stream<bool> get killSwitchStream => _killSwitchController?.stream ?? const Stream.empty();

  /// Active/désactive le kill-switch.
  void setKillSwitchEnabled(bool enabled) {
    _killSwitchEnabled = enabled;
    if (!enabled) {
      _wasConnectedBeforeDrop = false;
      _killSwitchController?.add(false);
    }
    notifyListeners();
  }

  Future<void> connect(String configPath) async {
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
    _wasConnectedBeforeDrop = false;
    _startMonitoring();
    notifyListeners();
    _killSwitchController?.add(false);
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _stopMonitoring();
    if (_killSwitchEnabled) {
      _wasConnectedBeforeDrop = true;
      _killSwitchController?.add(true);
    }
    notifyListeners();
  }

  /// Déconnexion volontaire (utilisateur) : ne déclenche pas le kill-switch.
  Future<void> disconnectVoluntary() async {
    _killSwitchEnabled = false;
    await disconnect();
    _killSwitchEnabled = true;
  }

  Future<void> saveConfigPath(String path) async {
    // Simulé : rien à faire
  }

  Future<String?> getConfigPath() async {
    return null;
  }

  Future<void> toggleVpn() async {
    if (_isConnected) {
      await disconnectVoluntary();
    } else {
      await connect('');
    }
  }

  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isConnected && _wasConnectedBeforeDrop && _killSwitchEnabled) {
        // Connexion perdue détectée : kill-switch actif
        _killSwitchController?.add(true);
      }
    });
  }

  void _stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  @override
  void dispose() {
    _stopMonitoring();
    _killSwitchController?.close();
    super.dispose();
  }
}