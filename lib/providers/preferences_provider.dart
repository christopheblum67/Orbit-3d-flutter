import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
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

final matchmakingProvider = FutureProvider.autoDispose
    .family<List<Movie>, String>((ref, profileId) async {
  final profile = ref.watch(currentProfileProvider);
  final movies = ref.watch(moviesProvider).valueOrNull ?? const <Movie>[];

  if (profile == null || profile.id != profileId) {
    return const <Movie>[];
  }

  if (movies.isEmpty) return const <Movie>[];

  final favorites = profile.favoriteGenres
      .map((g) => g.trim().toLowerCase())
      .where((g) => g.isNotEmpty)
      .toList();

  final scored = movies.map((m) {
    final titleLower = m.title.toLowerCase();
    final genresStr = m.genre.toLowerCase();
    final descLower = m.description.toLowerCase();

    var favCount = 0;
    var score = 0;

    for (final fav in favorites) {
      final inGenre = genresStr.contains(fav);
      final inTitle = inGenre || titleLower.contains(fav);
      final inDesc = descLower.contains(fav);
      if (inGenre) score += 3;
      if (inTitle) score += 1;
      if (inDesc && !inGenre) score += 1;
      if (inGenre || inTitle || inDesc) favCount++;
    }

    final ratingBonus = m.rating >= 7
        ? 2
        : (m.rating >= 5 ? 1 : 0);

    return (movie: m, score: score, favCount: favCount, bonus: ratingBonus);
  }).toList();

  scored.sort((a, b) {
    final s = b.score.compareTo(a.score);
    if (s != 0) return s;
    final b_ = b.favCount.compareTo(a.favCount);
    if (b_ != 0) return b_;
    return b.bonus.compareTo(a.bonus);
  });

  return scored
      .where((e) => e.favCount > 0)
      .map((e) => e.movie)
      .take(20)
      .toList();
});
