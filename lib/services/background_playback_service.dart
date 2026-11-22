import 'dart:async';

import 'package:flutter/services.dart';

/// Contrôle du foreground service de type `mediaPlayback` (Android 14+).
///
/// Maintient le processus vivant pendant la lecture en arrière-plan, affiche la
/// notification de lecture obligatoire et expose la `MediaSession` native
/// (télécommande TV, casque Bluetooth, contrôles de la notification).
///
/// Pont vers le MethodChannel « orbit/playback_service »
/// (PlaybackServiceChannel.kt).
///
/// Sens natif → Dart : le canal émet des commandes distantes
/// (`play`, `pause`, `stop`, `next`, `previous`) que l'écran lecteur consomme
/// via [commands]. L'abonnement est volontairement un flux *broadcast* statique
/// posé une seule fois : un `PlayerScreen` recréé ne doit pas laisser un
/// `MethodCallHandler` orphelin, et il ne doit pas non plus écraser le handler
/// d'une instance plus récente.
class BackgroundPlaybackService {
  static const _channel = MethodChannel('orbit/playback_service');

  /// Commandes distantes émises par la MediaSession native.
  static final StreamController<String> _commands =
      StreamController<String>.broadcast();

  static bool _handlerInstalled = false;

  BackgroundPlaybackService() {
    if (!_handlerInstalled) {
      _handlerInstalled = true;
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'command') {
      final cmd = call.arguments;
      if (cmd is String && cmd.isNotEmpty) {
        _commands.add(cmd);
      }
    }
    return null;
  }

  /// Flux des commandes distantes : `play`, `pause`, `stop`, `next`,
  /// `previous`. Ne se termine jamais.
  Stream<String> get commands => _commands.stream;

  /// Lance (ou met à jour) le foreground service de lecture.
  ///
  /// [playing] synchronise l'état de la MediaSession native (icône play/pause
  /// de la notification et des contrôles système).
  Future<bool> start({
    String title = 'Orbit',
    String subtitle = 'Lecture en cours',
    bool playing = true,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('start', {
            'title': title,
            'subtitle': subtitle,
            'playing': playing,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Met à jour métadonnées et état lecture/pause de la MediaSession sans
  /// relancer le service (utilisé quand l'état change alors que le service
  /// tourne déjà, ex. pause depuis la télécommande).
  Future<bool> updateSession({
    String title = 'Orbit',
    String subtitle = 'Lecture en cours',
    bool playing = true,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('update', {
            'title': title,
            'subtitle': subtitle,
            'playing': playing,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Arrête le foreground service et retire la notification.
  Future<bool> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stop') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
