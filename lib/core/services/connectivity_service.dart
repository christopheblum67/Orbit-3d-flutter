import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Surveillance de la connectivité réseau avec diffusion d'événements.
/// Utilise la package Connectivity en fallback vers une ping HTTP simple.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _init();
  }

  /// Instance globale de connectivité Flutter.
  final Connectivity _connectivity = Connectivity();
  final _connectionStream = StreamController<NetworkState>.broadcast();
  Stream<NetworkState> get connectionStream => _connectionStream.stream;

  /// État courant de la connexion (mis à jour à chaque changement).
  NetworkState _state = NetworkState.unknown;
  NetworkState get state => _state;

  /// État initial : détermine si on est connecté au lancement de l'app.
  Future<NetworkState> _checkInitialState() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        // Test supplémentaire : accès réel à Internet ?
        final result2 = await InternetAddress.ping('8.8.8.8',
            timeout: const Duration(seconds: 3));
        if (result2.isNotEmpty) {
          return NetworkState.connected;
        }
      }
      return NetworkState.noConnection;
    } catch (_) {
      return NetworkState.unknown;
    }
  }

  /// Écoute des changements de connexion en temps réel.
  void _listener() {
    final subscription = _connectivity.onConnectivityChanged.listen((result) {
      final newState = _mapResult(result);
      if (_state != newState) {
        _state = newState;
        _connectionStream.sink.add(_state);
        notifyListeners();
      }
    });
    // Garde l'abonnement en vie (évité la collecte GC immédiate).
    _ = subscription;
  }

  /// Mappe le résultat brute de Connectivity vers notre enum NetworkState.
  NetworkState _mapResult(ConnectivityResult result) {
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile) {
      return NetworkState.connected;
    }
    return NetworkState.noConnection;
  }

  /// Vérifie si on a internet (pas juste Wi-Fi/mobile).
  Future<bool> hasInternet() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        final result2 = await InternetAddress.ping('8.8.8.8',
            timeout: const Duration(seconds: 3));
        return result2.isNotEmpty;
      }
      return false;
    } catch (_) {
      return false;
    }
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