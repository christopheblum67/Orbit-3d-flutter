import 'package:flutter/services.dart';

/// Contrôle du foreground service de type `mediaPlayback` (Android 14+).
///
/// Maintenir le processus vivant pendant la lecture en arrière-plan et
/// afficher la notification de lecture obligatoire.
/// Pont vers le MethodChannel « orbit/playback_service » (PlaybackServiceChannel.kt).
class BackgroundPlaybackService {
  static const _channel = MethodChannel('orbit/playback_service');

  /// Lance (ou met à jour) le foreground service de lecture.
  Future<bool> start({
    String title = 'Orbit',
    String subtitle = 'Lecture en cours',
  }) async {
    try {
      return await _channel.invokeMethod<bool>('start', {
        'title': title,
        'subtitle': subtitle,
      }) ?? false;
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