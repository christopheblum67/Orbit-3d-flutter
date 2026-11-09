import 'package:shared_preferences/shared_preferences.dart';

/// Détecte une fin anormale du lecteur (plantage natif) lors de la session
/// précédente. Un plantage natif ne peut pas être intercepté en Dart : on
/// pose un drapeau à l'ouverture du lecteur et on l'efface à sa fermeture
/// propre. S'il est encore levé à l'ouverture suivante, le « mode sûr »
/// (un seul lecteur à la fois, pas de préchargement) est activé 24 h.
class PlayerCrashGuard {
  PlayerCrashGuard._();

  static const _activeKey = 'player_session_active';
  static const _safeUntilKey = 'player_safe_mode_until_ms';
  static const _safeDuration = Duration(hours: 24);

  static bool _safeMode = false;

  static bool get safeMode => _safeMode;

  static Future<void> begin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (prefs.getBool(_activeKey) ?? false) {
        await prefs.setInt(_safeUntilKey, now + _safeDuration.inMilliseconds);
      }
      _safeMode = now < (prefs.getInt(_safeUntilKey) ?? 0) ||
          (prefs.getBool(_activeKey) ?? false);
      await prefs.setBool(_activeKey, true);
    } catch (_) {}
  }

  static Future<void> end() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activeKey, false);
    } catch (_) {}
  }
}
