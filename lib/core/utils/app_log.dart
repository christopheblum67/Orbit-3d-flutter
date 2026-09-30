import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Journalisation diag persistante.
///
/// `debugPrint` est throttlé et `developer.log` se retrouve parfois filtré
/// dans logcat sur un APK debug lancé hors `flutter run`. On passe donc par un
/// MethodChannel vers `android.util.Log`, qui est toujours capturé, et on
/// écrit aussi dans un fichier lisible par `adb`.
class AppLog {
  AppLog._();

  static const MethodChannel _channel =
      MethodChannel('com.example.orbit_3d_flutter/app_log');

  static bool _nativeReady = false;

  static void _init() {
    if (_nativeReady) return;
    _nativeReady = true;
    _channel.setMethodCallHandler((call) async => null);
  }

  static void write(String message) {
    developer.log(message, name: 'OrbitDiag');
    if (kDebugMode) debugPrint(message);
    _init();
    _channel
        .invokeMethod<void>('log', <String, String>{'message': message})
        .catchError((_) {});
  }
}

void logDiag(String message) => AppLog.write(message);
