import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RadioFavoritesStore {
  RadioFavoritesStore._();

  static Future<void> _tail = Future<void>.value();

  static Future<T> _locked<T>(Future<T> Function() action) {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    return () async {
      await previous;
      try {
        return await action();
      } finally {
        done.complete();
      }
    }();
  }

  static String _key(String profileId) => 'radio_favorites_$profileId';

  static Future<Set<String>> read(String profileId) => _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        return (prefs.getStringList(_key(profileId)) ?? const <String>[])
            .toSet();
      });

  static Future<Set<String>> toggle(String profileId, String name) =>
      _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        final favorites =
            (prefs.getStringList(_key(profileId)) ?? const <String>[]).toSet();
        if (!favorites.remove(name)) favorites.add(name);
        if (!await prefs.setStringList(_key(profileId), favorites.toList())) {
          throw StateError('Impossible d’enregistrer les favoris radio.');
        }
        return favorites;
      });

  static Future<void> applyIfUnchanged(
    String profileId,
    Set<String> expected,
    Set<String> merged,
    void Function() checkSession,
  ) =>
      _locked(() async {
        final prefs = await SharedPreferences.getInstance();
        checkSession();
        final key = _key(profileId);
        final original = prefs.getStringList(key);
        if (!setEquals((original ?? const <String>[]).toSet(), expected)) {
          throw StateError('Les favoris radio ont changé. Réessayez.');
        }
        if (setEquals(expected, merged)) return;
        try {
          if (!await prefs.setStringList(key, merged.toList()..sort())) {
            throw StateError('Impossible de synchroniser les favoris radio.');
          }
          checkSession();
        } catch (_) {
          final restored = original == null
              ? await prefs.remove(key)
              : await prefs.setStringList(key, original);
          if (!restored) {
            throw StateError('Impossible de restaurer les favoris radio.');
          }
          rethrow;
        }
      });
}
