import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>(
  (ref) => PreferencesNotifier(ref),
);

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  final Ref _ref;

  PreferencesNotifier(this._ref) : super(const UserPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    final prefs = await storage.getPreferences();
    state = prefs;
  }

  Future<void> update(UserPreferences prefs) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.savePreferences(prefs);
    state = prefs;
  }

  Future<void> updateParental(
      {required bool enabled, int ageRestriction = 0,}) async {
    await update(state.copyWith(
      parentalControlEnabled: enabled,
      ageRestriction: ageRestriction,
    ),);
  }

  Future<void> setNotifications(bool enabled) async {
    await update(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setLanguage(String language) async {
    await update(state.copyWith(language: language));
  }

  Future<void> setTheme(String theme) async {
    await update(state.copyWith(theme: theme));
  }
}

final parentalPinProvider = StateProvider<String?>((ref) => null);

final parentalPinControllerProvider = Provider<ParentalPinController>((ref) {
  return ParentalPinController(ref);
});

class ParentalPinController {
  final Ref _ref;
  ParentalPinController(this._ref);

  Future<void> setPin(String pin) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setParentalPin(pin);
    _ref.read(parentalPinProvider.notifier).state = pin;
  }

  Future<void> clearPin() async {
    final storage = _ref.read(storageServiceProvider);
    await storage.clearParentalPin();
    _ref.read(parentalPinProvider.notifier).state = null;
  }

  Future<String?> getPin() async {
    final storage = _ref.read(storageServiceProvider);
    final pin = await storage.getParentalPin();
    _ref.read(parentalPinProvider.notifier).state = pin;
    return pin;
  }
}
