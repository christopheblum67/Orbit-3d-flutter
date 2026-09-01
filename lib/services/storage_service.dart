import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/user_preferences.dart';
import '../models/subscription.dart';

class StorageService {
  static const String _profilesBox = 'profiles';
  static const String _settingsBox = 'settings';
  static const String _subscriptionsBox = 'subscriptions';

  Future<void> init() async {
    await Hive.openBox(_profilesBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox<Subscription>(_subscriptionsBox);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = Hive.box(_profilesBox);
    await box.put(profile.id, profile.toMap());
  }

  Future<List<UserProfile>> getProfiles() async {
    final box = Hive.box(_profilesBox);
    return box.values
        .whereType<Map>()
        .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteProfile(String id) async {
    final box = Hive.box(_profilesBox);
    await box.delete(id);
  }

  static const String _prefsKey = 'user_preferences';
  static const String _parentalPinKey = 'parental_pin';

  Future<void> savePreferences(UserPreferences prefs) async {
    final box = Hive.box(_settingsBox);
    await box.put(_prefsKey, prefs.toMap());
  }

  Future<UserPreferences> getPreferences() async {
    final box = Hive.box(_settingsBox);
    final map = box.get(_prefsKey);
    if (map is Map) {
      return UserPreferences.fromMap(Map<String, dynamic>.from(map));
    }
    return const UserPreferences();
  }

  Future<void> setParentalPin(String pin) async {
    final box = Hive.box(_settingsBox);
    await box.put(_parentalPinKey, pin);
  }

  Future<String?> getParentalPin() async {
    final box = Hive.box(_settingsBox);
    return box.get(_parentalPinKey);
  }

  Future<void> clearParentalPin() async {
    final box = Hive.box(_settingsBox);
    await box.delete(_parentalPinKey);
  }

  Future<void> setSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  dynamic getSetting(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key);
  }

  // --- Subscriptions ---

  Future<void> saveSubscription(Subscription subscription) async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    await box.put(subscription.id, subscription);
  }

  Future<List<Subscription>> getSubscriptions() async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    return box.values.toList();
  }

  Future<Subscription?> getActiveSubscription() async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    for (final s in box.values) {
      if (s.isActive) return s;
    }
    return null;
  }

  Future<void> deleteSubscription(String id) async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    await box.delete(id);
  }

  Future<void> clearSubscriptions() async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    await box.clear();
  }

  Future<void> setActiveSubscription(String id) async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    for (final sub in box.values) {
      final updated = sub.copyWith(isActive: sub.id == id);
      await box.put(sub.id, updated);
    }
  }

  Future<void> migrateFromSharedPreferences() async {
    final box = Hive.box<Subscription>(_subscriptionsBox);
    if (box.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final activeSource = prefs.getString('active_source');
    final xtreamBaseUrl = prefs.getString('xtream_base_url');
    final xtreamUsername = prefs.getString('xtream_username');
    final xtreamPassword = prefs.getString('xtream_password');
    final m3uUrl = prefs.getString('m3u_url');

    Subscription? sub;
    if (activeSource == 'xtream' && xtreamBaseUrl != null && xtreamUsername != null) {
      sub = Subscription(
        id: const Uuid().v4(),
        name: 'Abonnement principal',
        type: SubscriptionType.xtream,
        baseUrl: xtreamBaseUrl,
        username: xtreamUsername,
        password: xtreamPassword,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } else if (activeSource == 'm3u' && m3uUrl != null) {
      sub = Subscription(
        id: const Uuid().v4(),
        name: 'Playlist M3U',
        type: SubscriptionType.m3u,
        m3uUrl: m3uUrl,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    if (sub != null) {
      await box.put(sub.id, sub);
    }
  }
}
