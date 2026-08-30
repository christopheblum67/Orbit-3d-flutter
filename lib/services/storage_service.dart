import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _profilesBox = 'profiles';
  static const String _settingsBox = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_profilesBox);
    await Hive.openBox(_settingsBox);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = Hive.box(_profilesBox);
    await box.put(profile.id, profile.toMap());
  }

  Future<List<UserProfile>> getProfiles() async {
    final box = Hive.box(_profilesBox);
    return box.values.map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> deleteProfile(String id) async {
    final box = Hive.box(_profilesBox);
    await box.delete(id);
  }

  Future<void> setSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  dynamic getSetting(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key);
  }
}
