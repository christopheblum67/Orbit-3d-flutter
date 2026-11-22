import 'dart:io';
import 'package:flutter/services.dart';

/// Service pour quitter proprement l'application sur Android
/// Utilise MethodChannel pour appeler Activity.finishAndRemoveTask()
class AppExitService {
  static const MethodChannel _channel = MethodChannel('orbit.iptv/app_exit');

  /// Quitte l'application complètement (Android)
  /// Sur iOS, utilise SystemNavigator.pop() (comportement standard)
  /// Sur Android, appelle finishAndRemoveTask() via MethodChannel
  static Future<void> exitApp() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('exitApp');
        // Si le MethodChannel réussit, l'app se ferme côté natif
        // Sinon on fallback sur SystemNavigator.pop()
      } on PlatformException catch (_) {
        // Fallback si le channel n'est pas implémenté
        SystemNavigator.pop();
      }
    } else {
      // iOS, Web, Desktop : comportement standard
      SystemNavigator.pop();
    }
  }
}