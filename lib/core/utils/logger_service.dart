import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  LoggerService._();

  static final LoggerService _instance = LoggerService._();
  static LoggerService get instance => _instance;

  static const String _tag = 'Orbit3D';
  static bool _isProduction = false;

  static void configure({required bool isProduction}) {
    _isProduction = isProduction;
  }

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_isProduction && level == LogLevel.debug) return;

    final String logTag = tag ?? _tag;
    final String formattedMessage = '[${level.name.toUpperCase()}] $message';

    switch (level) {
      case LogLevel.debug:
        developer.log(formattedMessage, name: logTag, level: 0);
        break;
      case LogLevel.info:
        developer.log(formattedMessage, name: logTag, level: 1);
        break;
      case LogLevel.warning:
        developer.log(formattedMessage, name: logTag, level: 2, error: error);
        break;
      case LogLevel.error:
        developer.log(
          formattedMessage,
          name: logTag,
          level: 3,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.critical:
        developer.log(
          formattedMessage,
          name: logTag,
          level: 4,
          error: error,
          stackTrace: stackTrace,
        );
        break;
    }

    if (kDebugMode) debugPrint(formattedMessage);
    // `debug` est supprimé en release.
    //
    // Ce n'est pas cosmétique : le service TMDB journalise requête ET réponse
    // pour chaque film de la grille, donc plusieurs centaines d'appels au
    // chargement de la section Films. Émettre tout cela vers logcat en release
    // sature le tampon et ralentit sensiblement l'écran. On s'appuie sur
    // `kReleaseMode` plutôt que sur `_isProduction`, qui n'était jamais
    // positionné et laissait donc passer ce volume.
    if (kDebugMode || level != LogLevel.debug) {
      emit(formattedMessage);
    }
  }

  /// Journalise vers `logcat` sans condition de build.
  ///
  /// `developer.log` n'apparaît dans `logcat` que sur certaines configurations,
  /// et `debugPrint` est muet en release. Conséquence concrète : toute la
  /// trace de diagnostic de la lecture (détection de stall, erreurs de
  /// providers) était **invisible** sur le build installé, ce qui rendait
  /// impossible de distinguer un blocage réseau d'un faux positif du
  /// `StallDetector`.
  ///
  /// `print` écrit toujours sur stdout, qui est redirigé vers `logcat` sous le
  /// tag `flutter`. Le préfixe `Orbit3D` permet de filtrer.
  static void emit(String message) {
    // ignore: avoid_print
    print('Orbit3D $message');
  }

  void debug(String message, {String? tag}) =>
      log(message, level: LogLevel.debug, tag: tag);
  void info(String message, {String? tag}) =>
      log(message, level: LogLevel.info, tag: tag);
  void warning(String message, {String? tag, Object? error}) =>
      log(message, level: LogLevel.warning, tag: tag, error: error);
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: LogLevel.error,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
  void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: LogLevel.critical,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
}
