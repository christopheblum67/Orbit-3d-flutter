import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Pont vers le widget d'accueil Android (home_widget).
///
/// Envoie les données affichées par le widget (profil actif, nombre de
/// favoris) puis demande sa mise à jour. Tous les appels sont protégés :
/// si le plugin est indisponible (tests, plateforme non supportée), l'app
/// continue normalement.
class HomeWidgetService {
  HomeWidgetService._();

  static final HomeWidgetService instance = HomeWidgetService._();

  static const _widgetName = 'OrbitHomeWidgetProvider';

  /// Publie [profileName] et [favoritesCount] dans le widget puis le
  /// rafraîchit. Appelé à chaque changement pertinent (favoris, profil).
  Future<void> updateWidgetData({
    String? profileName,
    int? favoritesCount,
  }) async {
    await safeAsync(() async {
      await HomeWidget.saveWidgetData<String>(
        'widget_title',
        'Orbit IPTV',
      );
      final profile =
          (profileName == null || profileName.isEmpty) ? '—' : profileName;
      await HomeWidget.saveWidgetData<String>(
        'widget_profile',
        'Profil : $profile',
      );
      final count = favoritesCount ?? 0;
      await HomeWidget.saveWidgetData<String>(
        'widget_favorites',
        '$count ${count > 1 ? 'favoris' : 'favori'}',
      );
      await HomeWidget.updateWidget(name: _widgetName);
    }, context: 'updateWidgetData');
  }

  /// Abonnement aux données de lancement via le widget (tap / action rapide).
  Stream<Uri?> get widgetClicks => HomeWidget.widgetClicked;

  /// URI du premier lancement fait depuis le widget.
  Future<Uri?> initiallyLaunched() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();
}

/// Nom logique de l'action « ouvrir les favoris » envoyée par le widget.
const String kWidgetActionFavorites = 'orbit://widget/favorites';

/// Route cible associée à chaque action du widget.
String? routeForWidgetUri(Uri? uri) {
  if (uri == null) return null;
  return switch (uri.toString()) {
    kWidgetActionFavorites => '/favorites',
    _ => null,
  };
}