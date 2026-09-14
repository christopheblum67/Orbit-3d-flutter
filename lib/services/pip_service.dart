import 'package:flutter/services.dart';

/// Contrôle du mode Picture-in-Picture natif (Android 8+).
///
/// Pont vers le MethodChannel « orbit/pip » implémenté dans PipChannel.kt.
class PipService {
  static const _channel = MethodChannel('orbit/pip');

  /// `true` si le device expose la fonctionnalité Picture-in-Picture.
  Future<bool> get isSupported async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Demande l'entrée en mode PiP avec le ratio de la vidéo courante.
  ///
  /// [width]/[height] définissent le ratio d'image (défaut 16:9).
  /// Retourne `false` si la demande a été refusée (PiP indisponible).
  Future<bool> enter({int width = 16, int height = 9}) async {
    try {
      return await _channel.invokeMethod<bool>('enter', {
        'width': width,
        'height': height,
      }) ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}