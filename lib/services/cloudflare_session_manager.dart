import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Gestionnaire de session Cloudflare pour le zapping IPTV.
///
/// Intercepte le challenge Cloudflare via WebView invisible, extrait les cookies
/// (cf_clearance) et le User-Agent, et les injecte dans les headers du lecteur vidéo.
class CloudflareSessionManager extends ChangeNotifier {
  static final CloudflareSessionManager _instance =
      CloudflareSessionManager._internal();
  factory CloudflareSessionManager() => _instance;
  CloudflareSessionManager._internal();

  static const String _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

  final String _userAgent = _defaultUserAgent;
  String _cookies = '';
  String _baseUrl = '';
  DateTime? _cookieExpiry;
  bool _isInitialized = false;
  bool _isChallenging = false;
  Timer? _renewalTimer;

  String get userAgent => _userAgent;
  String get cookies => _cookies;
  bool get isReady => _isInitialized && _cookies.isNotEmpty;
  bool get isChallenging => _isChallenging;

  /// Headers HTTP à injecter dans le lecteur vidéo (video_player, fijkplayer, etc.)
  Map<String, String> get videoHeaders => {
        'User-Agent': _userAgent,
        'Cookie': _cookies,
        'Referer': _baseUrl,
        'Accept': '*/*',
        'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
      };

  /// Initialise la session Cloudflare : lance le challenge WebView invisible.
  /// À appeler au démarrage de l'app (ex: dans StartupSplashScreen).
  Future<void> initialize({required String baseUrl}) async {
    if (_isInitialized && _cookies.isNotEmpty) return;

    _baseUrl = baseUrl;
    _isChallenging = true;
    notifyListeners();

    try {
      await _performChallenge();
      _isInitialized = true;
      _isChallenging = false;
      _startRenewalTimer();
      notifyListeners();
    } catch (e) {
      _isChallenging = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Effectue le challenge Cloudflare via WebView headless.
  Future<void> _performChallenge() async {
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_userAgent);

    // Configuration Android spécifique pour les cookies
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    final cookieManager = WebViewCookieManager();
    final completer = Completer<void>();

    void onPageStarted(String url) {
      // Page de challenge Cloudflare chargee
    }

    Future<void> onPageFinished(String url) async {
      // Challenge reussi, on recupere les cookies
      await _extractCookies(cookieManager, url);
      if (!completer.isCompleted) completer.complete();
    }

    NavigationDecision onNavigationRequest(NavigationRequest request) {
      // Suivre les redirections Cloudflare
      return NavigationDecision.navigate;
    }

    void onHttpError(HttpResponseError error) {
      // Erreur HTTP pendant le challenge
      if (!completer.isCompleted) {
        completer.completeError(
          Exception(
            'Cloudflare challenge failed: ${error.response?.statusCode}',
          ),
        );
      }
    }

    controller.setNavigationDelegate(NavigationDelegate(
      onPageStarted: onPageStarted,
      onPageFinished: onPageFinished,
      onNavigationRequest: onNavigationRequest,
      onHttpError: onHttpError,
    ),
    );

    await controller.loadRequest(Uri.parse(_baseUrl));
    await completer.future;
  }

  /// Extrait les cookies Cloudflare (cf_clearance, etc.) après le challenge.
  Future<void> _extractCookies(
    WebViewCookieManager cookieManager,
    String url,
  ) async {
    final uri = Uri.parse(url);
    final cookies = await cookieManager.getCookies(domain: uri);
    if (cookies.isEmpty) return;

    // Filtrer les cookies pertinents (cf_clearance, session, etc.)
    final relevantCookies = cookies
        .where(
          (c) =>
              c.name.contains('cf_') ||
              c.name.toLowerCase().contains('session') ||
              c.name.toLowerCase().contains('auth') ||
              c.name.toLowerCase().contains('token'),
        )
        .toList();

    if (relevantCookies.isNotEmpty) {
      _cookies = relevantCookies.map((c) => '${c.name}=${c.value}').join('; ');
      // Estimer l'expiration (Cloudflare ~ quelques heures)
      _cookieExpiry = DateTime.now().add(const Duration(hours: 3));
      debugPrint(
        '☁️ Cloudflare session cookies updated: ${_cookies.length} chars',
      );
    }

    // Aussi récupérer tous les cookies en fallback
    if (_cookies.isEmpty) {
      _cookies = cookies.map((c) => '${c.name}=${c.value}').join('; ');
      _cookieExpiry = DateTime.now().add(const Duration(hours: 3));
    }
  }

  /// Renouvelle la session (re-challenge) si cookies expirés ou invalides.
  Future<void> renewSession() async {
    if (_isChallenging) return;
    debugPrint('☁️ Renewing Cloudflare session...');
    _cookies = '';
    _cookieExpiry = null;
    await initialize(baseUrl: _baseUrl);
  }

  /// Vérifie si les cookies sont encore valides.
  bool get _cookiesValid =>
      _cookies.isNotEmpty &&
      _cookieExpiry != null &&
      DateTime.now().isBefore(_cookieExpiry!);

  /// Démarre un timer de renouvellement préventif (toutes les 2h).
  void _startRenewalTimer() {
    _renewalTimer?.cancel();
    _renewalTimer = Timer.periodic(const Duration(hours: 2), (_) async {
      if (!_cookiesValid) {
        await renewSession();
      }
    });
  }

  /// Force le rafraîchissement des headers (appelé avant chaque zapping).
  Map<String, String> getFreshHeaders() {
    if (!_cookiesValid) {
      // Trigger renewal asynchrone, mais on retourne les headers actuels
      unawaited(renewSession());
    }
    return videoHeaders;
  }

  /// Détecte si une erreur de lecture est due à Cloudflare (403, challenge page, etc.)
  bool isCloudflareError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('cloudflare') ||
        msg.contains('challenge') ||
        msg.contains('cf_clearance') ||
        msg.contains('blocked') ||
        msg.contains('access denied');
  }

  @override
  void dispose() {
    _renewalTimer?.cancel();
    super.dispose();
  }
}

/// Extension pour `unawaited` sans import `dart:async` partout.
T unawaited<T>(Future<T> future) {
  // Ignore le futur intentionnellement
  return future as T;
}
