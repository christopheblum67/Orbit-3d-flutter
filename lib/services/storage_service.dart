import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

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
    await HiveSync.write(_profilesBox, (box) => box.put(profile.id, profile.toMap()));
  }

  Future<List<UserProfile>> getProfiles() async {
    return HiveSync.read(_profilesBox, (box) {
      return box.values
          .whereType<Map>()
          .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<void> deleteProfile(String id) async {
    await HiveSync.write(_profilesBox, (box) => box.delete(id));
  }

  static const String _prefsKey = 'user_preferences';
  static const String _parentalPinKey = 'parental_pin';

  Future<void> savePreferences(UserPreferences prefs) async {
    await HiveSync.write(_settingsBox, (box) => box.put(_prefsKey, prefs.toMap()));
  }

  Future<UserPreferences> getPreferences() async {
    return HiveSync.read(_settingsBox, (box) {
      final map = box.get(_prefsKey);
      if (map is Map) {
        return UserPreferences.fromMap(Map<String, dynamic>.from(map));
      }
      return const UserPreferences();
    });
  }

  Future<void> setParentalPin(String pin) async {
    await HiveSync.write(_settingsBox, (box) => box.put(_parentalPinKey, pin));
  }

  Future<String?> getParentalPin() async {
    return HiveSync.read(_settingsBox, (box) => box.get(_parentalPinKey));
  }

  Future<void> clearParentalPin() async {
    await HiveSync.write(_settingsBox, (box) => box.delete(_parentalPinKey));
  }

  Future<void> setSetting(String key, dynamic value) async {
    await HiveSync.write(_settingsBox, (box) => box.put(key, value));
  }

  dynamic getSetting(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key);
  }

  // --- Subscriptions ---

  Future<void> saveSubscription(Subscription subscription) async {
    await HiveSync.write(_subscriptionsBox, (box) => box.put(subscription.id, subscription));
  }

  Future<List<Subscription>> getSubscriptions() async {
    return HiveSync.read(_subscriptionsBox, (box) => box.values.cast<Subscription>().toList());
  }

  Future<Subscription?> getActiveSubscription() async {
    return HiveSync.read(_subscriptionsBox, (box) {
      for (final s in box.values) {
        if (s.isActive) return s;
      }
      return null;
    });
  }

  Future<void> deleteSubscription(String id) async {
    await HiveSync.write(_subscriptionsBox, (box) => box.delete(id));
  }

  Future<void> clearSubscriptions() async {
    await HiveSync.write(_subscriptionsBox, (box) => box.clear());
  }

  Future<void> setActiveSubscription(String id) async {
    await HiveSync.write(_subscriptionsBox, (box) {
      for (final sub in box.values) {
        final updated = sub.copyWith(isActive: sub.id == id);
        box.put(sub.id, updated);
      }
    });
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
    if (activeSource == 'xtream' &&
        xtreamBaseUrl != null &&
        xtreamUsername != null) {
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