import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager {
  static const String _xtreamBaseUrlKey = 'xtream_base_url';
  static const String _xtreamUsernameKey = 'xtream_username';
  static const String _xtreamPasswordKey = 'xtream_password';
  static const String _m3uUrlKey = 'm3u_url';
  static const String _activeSourceKey = 'active_source'; // 'xtream' ou 'm3u'

  Future<void> saveXtream({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_xtreamBaseUrlKey, baseUrl);
    await prefs.setString(_xtreamUsernameKey, username);
    await prefs.setString(_xtreamPasswordKey, password);
    await prefs.setString(_activeSourceKey, 'xtream');
  }

  Future<void> saveM3u(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_m3uUrlKey, url);
    await prefs.setString(_activeSourceKey, 'm3u');
  }

  Future<Map<String, String?>> getActiveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getString(_activeSourceKey);
    if (active == 'xtream') {
      return {
        'type': 'xtream',
        'baseUrl': prefs.getString(_xtreamBaseUrlKey),
        'username': prefs.getString(_xtreamUsernameKey),
        'password': prefs.getString(_xtreamPasswordKey),
      };
    } else if (active == 'm3u') {
      return {
        'type': 'm3u',
        'url': prefs.getString(_m3uUrlKey),
      };
    }
    return {'type': null};
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xtreamBaseUrlKey);
    await prefs.remove(_xtreamUsernameKey);
    await prefs.remove(_xtreamPasswordKey);
    await prefs.remove(_m3uUrlKey);
    await prefs.remove(_activeSourceKey);
  }
}
