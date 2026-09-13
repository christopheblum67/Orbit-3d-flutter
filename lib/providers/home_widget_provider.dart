import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/home_widget_service.dart';

/// Synchronise le widget d'accueil Android avec le profil actif et le nombre
/// de favoris. Activé dans `OrbitApp` : chaque changement met à jour le widget.
final homeWidgetSyncProvider = Provider<HomeWidgetSync>((ref) {
  final sync = HomeWidgetSync(ref);
  sync.listen();
  ref.onDispose(sync.dispose);
  return sync;
});

class HomeWidgetSync {
  HomeWidgetSync(this._ref);

  final Ref _ref;

  void listen() {
    _ref.listen<Map<String, FavoriteEntry>>(favoritesProvider, (_, favorites) {
      final profile = _ref.read(currentProfileProvider);
      // ignore: avoid_slow_async_io
      unawaited(HomeWidgetService.instance.updateWidgetData(
        profileName: profile?.firstName,
        favoritesCount: favorites.length,
      ));
    });
    _ref.listen(currentProfileProvider, (_, profile) {
      final favorites = _ref.read(favoritesProvider);
      // ignore: avoid_slow_async_io
      unawaited(HomeWidgetService.instance.updateWidgetData(
        profileName: profile?.firstName,
        favoritesCount: favorites.length,
      ));
    });
  }

  void dispose() {}
}