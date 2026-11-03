import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Surveillance de la connectivité réseau avec diffusion d'événements.
/// Combine l'état des interfaces réseau avec une vérification DNS de l'accès
/// Internet.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _init();
  }

  /// Instance globale de connectivité Flutter.
  final Connectivity _connectivity = Connectivity();
  final _connectionStream = StreamController<NetworkState>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Stream<NetworkState> get connectionStream => _connectionStream.stream;

  /// État courant de la connexion (mis à jour à chaque changement).
  NetworkState _state = NetworkState.unknown;
  NetworkState get state => _state;
  bool _disposed = false;
  bool _receivedConnectivityEvent = false;

  void _init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        _receivedConnectivityEvent = true;
        _updateState(_mapResults(results));
      },
      onError: (Object error, StackTrace stackTrace) {
        LoggerService.instance.error(
          'ConnectivityService stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    unawaited(_loadInitialState());
  }

  Future<void> _loadInitialState() async {
    final initialState = await _checkInitialState();
    if (!_disposed && !_receivedConnectivityEvent) {
      _updateState(initialState);
    }
  }

  /// Détermine si une interface réseau est disponible au démarrage.
  Future<NetworkState> _checkInitialState() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_mapResults(results) == NetworkState.noConnection) {
        return NetworkState.noConnection;
      }
      return await _canResolveInternetHost()
          ? NetworkState.connected
          : NetworkState.noConnection;
    } catch (error, stackTrace) {
      LoggerService.instance.error(
        'Unable to determine the initial network state',
        error: error,
        stackTrace: stackTrace,
      );
      return NetworkState.unknown;
    }
  }

  /// Mappe les interfaces réseau fournies par connectivity_plus.
  NetworkState _mapResults(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none)
        ? NetworkState.connected
        : NetworkState.noConnection;
  }

  void _updateState(NetworkState newState) {
    if (_disposed || _state == newState) return;
    _state = newState;
    _connectionStream.add(newState);
    notifyListeners();
  }

  Future<bool> _canResolveInternetHost() async {
    try {
      final addresses = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 3),
      );
      return addresses.isNotEmpty;
    } catch (error) {
      LoggerService.instance.warning(
        'Internet DNS check failed',
        error: error,
      );
      return false;
    }
  }

  /// Vérifie si on a internet (pas juste Wi-Fi/mobile).
  Future<bool> hasInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_mapResults(results) == NetworkState.noConnection) return false;
      return await _canResolveInternetHost();
    } catch (error, stackTrace) {
      LoggerService.instance.error(
        'Unable to verify Internet connectivity',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_connectionStream.close());
    super.dispose();
  }
}

/// État de la connexion réseau.
enum NetworkState { connected, noConnection, unknown }

/// Message lisible pour l'utilisateur depuis NetworkState.
String networkStateToString(NetworkState state) {
  switch (state) {
    case NetworkState.connected:
      return 'Connexion OK';
    case NetworkState.noConnection:
      return 'Pas de connexion internet';
    case NetworkState.unknown:
      return 'Vérification en cours';
  }
}
