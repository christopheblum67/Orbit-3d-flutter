import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Service minimal d'analyse Firebase (FirebaseAnalytics).
///
/// La plupart des appels sont fire-and-forget : ils ne doivent jamais
/// bloquer l'UI ni faire échouer le reste de l'application. Si Firebase
/// n'est pas initialisé (`google-services.json` absent ou échec réseau),
/// les appels sont simplement ignorés.
class AnalyticsService {
  FirebaseAnalytics? _analytics;

  /// Vrai seulement si Firebase est reellement initialise ET exploitable.
  /// Permet aux appelants de ne pas toucher `FirebaseAnalytics.instance`
  /// quand aucune config google-services n'est disponible.
  bool get isReady => _analytics != null;

  /// Idempotent : prépare l'accès à FirebaseAnalytics sans échouer.
  Future<void> init() async {
    if (_analytics != null) return;
    final result = await safeAsync(
      () async {
        // `Firebase.initializeApp()` sans options ne trouve que la config
        // generee par le plugin google-services. Sur un build sans
        // `google-services.json` exploitable (ex. flavor debug, CI) il leve
        // « No Firebase App '[DEFAULT]' has been created » a chaque appel.
        // On court-circuite des que l'app existe deja.
        final apps = Firebase.apps;
        if (apps.isNotEmpty) {
          return FirebaseAnalytics.instance;
        }
        await Firebase.initializeApp();
        return FirebaseAnalytics.instance;
      },
      context: 'AnalyticsService.init',
      fallbackValue: null,
    );
    _analytics = result.valueOrNull;
  }

  /// Visionnage d'un écran (l'événement standard `screen_view`).
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? 'screen',
    );
  }

  /// Sélection d'un contenu (standard `select_content`).
  Future<void> logContentSelected(
    String contentType,
    String itemId, {
    String? title,
    String? category,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logSelectContent(
      contentType: contentType,
      itemId: itemId,
      parameters: {
        if (title != null) 'title': title,
        if (category != null) 'category': category,
      },
    );
  }

  /// Recherche (standard `search`).
  Future<void> logSearch(String query, {int? resultCount}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logSearch(
      searchTerm: query,
      parameters: {if (resultCount != null) 'result_count': resultCount},
    );
  }

  /// Démarrage de lecture d'un média (`play_content`).
  Future<void> logPlaybackStart(
    String contentType,
    String itemId, {
    String? title,
    String? channelName,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: 'play_content',
      parameters: {
        'content_type': contentType,
        'item_id': itemId,
        if (title != null) 'title': title,
        if (channelName != null) 'channel_name': channelName,
      },
    );
  }

  /// Ouverture application (`app_open`).
  Future<void> logAppOpen() async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logAppOpen();
  }
}
