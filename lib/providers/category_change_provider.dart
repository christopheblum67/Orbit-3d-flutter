import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CategoryCatalog { movies, series }

typedef CategoryChangeKey = ({String subscriptionId, CategoryCatalog catalog});

final categoryCountTrackerProvider = Provider<CategoryCountTracker>(
  (ref) => CategoryCountTracker(),
);

final categoryIncreasesProvider =
    FutureProvider.family<Map<String, int>, CategoryChangeKey>(
        (ref, key) async {
  try {
    return await ref.watch(categoryCountTrackerProvider).increases(key);
  } catch (error, stack) {
    LoggerService.instance.error(
      'Impossible de lire les changements de catégories : $error',
      tag: 'catalog',
      error: error,
    );
    LoggerService.instance.error('$stack', tag: 'catalog');
    rethrow;
  }
});

/// Stocke une référence par abonnement et les hausses de la dernière mise à jour.
class CategoryCountTracker {
  final Map<CategoryChangeKey, Future<void>> _pending = {};

  String _key(CategoryChangeKey key) =>
      'category_counts_v1:${key.catalog.name}:${key.subscriptionId}';

  Future<Map<String, int>> increases(CategoryChangeKey key) async {
    final pending = _pending[key];
    if (pending != null) await pending;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(key));
    if (raw == null) return const {};
    return _decodeCounts(jsonDecode(raw)['increases']);
  }

  Future<void> record(
    CategoryChangeKey key,
    Iterable<String> categoryIds, {
    required bool refresh,
  }) {
    final counts = <String, int>{};
    for (final id in categoryIds) {
      if (id.isNotEmpty) counts[id] = (counts[id] ?? 0) + 1;
    }
    if (counts.isEmpty) return Future.value();
    final previous = _pending[key];
    final operation = () async {
      if (previous != null) await previous;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(key));
      final data = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
      final old = data == null ? null : _decodeCounts(data['counts']);
      final oldIncreases =
          data == null ? <String, int>{} : _decodeCounts(data['increases']);
      if (old != null && mapEquals(old, counts) && !refresh) return;
      final increased = <String, int>{
        if (old != null)
          for (final entry in counts.entries)
            if (entry.value > (old[entry.key] ?? 0)) entry.key: entry.value,
      };
      if (old != null &&
          mapEquals(old, counts) &&
          mapEquals(oldIncreases, increased)) {
        return;
      }
      final saved = await prefs.setString(
        _key(key),
        jsonEncode({'counts': counts, 'increases': increased}),
      );
      if (!saved) throw StateError('Impossible de sauvegarder les compteurs.');
    }();
    _pending[key] = operation;
    return operation.whenComplete(() {
      if (identical(_pending[key], operation)) _pending.remove(key);
    });
  }

  static Map<String, int> _decodeCounts(Object? value) {
    if (value is! Map) throw const FormatException('Compteurs invalides');
    return value.map((key, value) {
      if (key is! String || value is! int || value < 0) {
        throw const FormatException('Compteur invalide');
      }
      return MapEntry(key, value);
    });
  }
}
