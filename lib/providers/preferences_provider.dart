import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, UserPreferences>(
  PreferencesNotifier.new,
);

class PreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    _load();
    return const UserPreferences();
  }

  Future<void> _load() async {
    final storage = ref.read(storageServiceProvider);
    final prefs = await storage.getPreferences();
    state = prefs;
  }

  Future<void> update(UserPreferences prefs) async {
    final storage = ref.read(storageServiceProvider);
    await storage.savePreferences(prefs);
    state = prefs;
  }

  Future<void> updateParental({
    required bool enabled,
    int ageRestriction = 0,
  }) async {
    await update(
      state.copyWith(
        parentalControlEnabled: enabled,
        ageRestriction: ageRestriction,
      ),
    );
  }

  Future<void> setProfileVisible(bool visible) async {
    await update(state.copyWith(profileVisible: visible));
  }

  Future<void> setAllowRecording(bool allow) async {
    await update(state.copyWith(allowRecording: allow));
  }

  Future<void> setLanguage(String language) async {
    await update(state.copyWith(language: language));
  }

  Future<void> setTheme(String theme) async {
    await update(state.copyWith(theme: theme));
  }

  Future<void> setFontScale(double scale) async {
    await update(state.copyWith(fontScale: scale.clamp(0.8, 1.5)));
  }

  Future<void> importFromJson(UserPreferences imported) async {
    await update(imported);
  }
}

/// Code PIN parental : état en mémoire ET écritures disque.
///
/// Un seul provider fait les deux. La version précédente empilait deux
/// couches — `parentalPinProvider` portait la valeur, `ParentalPinController`
/// faisait les écritures — et ce dernier **capturait le `Ref` du provider à la
/// construction** pour le garder indéfiniment. Conserver une référence de
/// `Provider` dans un objet est le piège classique de Riverpod : elle survit
/// au dispose du provider, et les lectures suivantes lèvent.
///
/// Chaque écriture disque est suivie d'une vérification `ref.mounted`, qui
/// est la seule façon fiable de savoir si le notifier est encore vivant.
final parentalPinControllerProvider =
    NotifierProvider<ParentalPinNotifier, String?>(ParentalPinNotifier.new);

class ParentalPinNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Affectation directe en mémoire, sans écriture disque.
  void set(String? pin) => state = pin;

  Future<void> setPin(String pin) async {
    await ref.read(storageServiceProvider).setParentalPin(pin);
    if (!ref.mounted) return;
    state = pin;
  }

  Future<void> clearPin() async {
    await ref.read(storageServiceProvider).clearParentalPin();
    if (!ref.mounted) return;
    state = null;
  }

  Future<String?> getPin() async {
    final pin = await ref.read(storageServiceProvider).getParentalPin();
    if (!ref.mounted) return pin;
    state = pin;
    return pin;
  }
}
