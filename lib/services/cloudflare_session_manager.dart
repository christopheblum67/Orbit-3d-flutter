import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Gestionnaire de session Cloudflare pour le zapping IPTV.
///
/// Intercepte le challenge Cloudflare via WebView headless, extrait les cookies
/// (cf_clearance) et le User-Agent, et les injecte dans les headers du lecteur video.
///
/// Ce service est volontairement independant de l'UI : il ne manipule aucun
/// BuildContext. En cas de refus de lecture, l'ecran du lecteur peut ouvrir le
/// site du fournisseur dans le navigateur systeme pour une verification
/// manuelle ; la reprise reste une action explicite de l'utilisateur.
class CloudflareSessionManager extends ChangeNotifier {
  static final CloudflareSessionManager _instance =
      CloudflareSessionManager._internal();
  factory CloudflareSessionManager() => _instance;
  CloudflareSessionManager._internal();

  static const String _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

  /// Budget par tentative. Les delais sont reellement appliques via
  /// `Future.timeout`, ce qui evite qu'un challenge bloque indefiniment.
  static const List<Duration> _attemptTimeouts = <Duration>[
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 45),
  ];

  /// Duree de vie prudente d'un cookie cf_clearance avant renouvellement.
  static const Duration _cookieLifetime = Duration(hours: 2);

  final String _userAgent = _defaultUserAgent;

  String _cookies = '';
  String _baseUrl = '';
  DateTime? _cookieExpiry;
  bool _isInitialized = false;
  bool _isChallenging = false;
  bool _disposed = false;

  /// Le panneau ne presente aucun challenge Cloudflare : la page se charge
  /// normalement et aucun `cf_clearance` n'est emis. Exiger ce cookie faisait
  /// echouer l'initialisation apres 3 tentatives (et bruyait `getFreshHeaders`
  /// d'un renouvellement a chaque appel) alors que la lecture fonctionne.
  bool _noChallengeRequired = false;
  Timer? _renewalTimer;

  /// Chaine de serialisation des challenges. Un simpleFuture se terminant
  /// toujours sans erreur evite les deadlocks du type "s'auto-verrouiller".
  Future<void> _lock = Future<void>.value();

  String get userAgent => _userAgent;
  String get cookies => _cookies;
  String get baseUrl => _baseUrl;
  bool get isReady =>
      _isInitialized && (_cookies.isNotEmpty || _noChallengeRequired);
  bool get isChallenging => _isChallenging;

  /// Vrai si un cookie de clearance est present et encore dans sa fenetre.
  bool get hasClearance => _cookiesValid;

  /// Headers HTTP a injecter dans le lecteur video (video_player, fijkplayer).
  /// Inclut les hints Sec-CH-UA attendus par la detection navigateur Cloudflare.
  Map<String, String> get videoHeaders {
    final headers = <String, String>{
      'User-Agent': _userAgent,
      'Referer': _baseUrl,
      'Accept': '*/*',
      'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
      'Sec-CH-UA': '"Chromium";v="119", "Not?A_Brand";v="24"',
      'Sec-CH-UA-Mobile': '?1',
      'Sec-CH-UA-Platform': '"Android"',
      'Sec-Fetch-Dest': 'video',
      'Sec-Fetch-Mode': 'playback',
      'Sec-Fetch-Site': 'cross-site',
    };
    // Un header Cookie vide est rejete par certains serveurs : ne l'envoie
    // que si des cookies ont reellement ete captures.
    if (_cookies.isNotEmpty) headers['Cookie'] = _cookies;
    return headers;
  }

  /// Serialise [action] derriere le challenge en cours.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final run = _lock.then((_) => action());
    _lock = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Initialise la session Cloudflare : lance le challenge WebView headless.
  /// Idempotent : si une session valide existe deja, ne relance rien.
  Future<void> initialize({required String baseUrl}) {
    return _synchronized(() async {
      // Le singleton est partage : on peut avoir ete dispose par un provider.
      _disposed = false;
      if (isReady && _cookiesValid) return;

      // Un changement d'hote peut reintroduire un challenge : on repart de zero.
      if (_baseUrl != baseUrl) {
        _noChallengeRequired = false;
        _cookies = '';
        _cookieExpiry = null;
      }
      _baseUrl = baseUrl;
      _isInitialized = false;
      await _runChallenge();
    });
  }

  /// Force un nouveau challenge (cookie expire, erreur 403, zapping changement
  /// de host). Ne deadloque pas : le corps du challenge est inline.
  Future<void> renewSession() {
    return _synchronized(() async {
      _disposed = false;
      if (isReady && _cookiesValid) return;

      debugPrint('☁️ [CF] renewing Cloudflare session for $_baseUrl');
      _noChallengeRequired = false;
      _cookies = '';
      _cookieExpiry = null;
      _isInitialized = false;
      await _runChallenge();
    });
  }

  /// Headers a utiliser pour une lecture. Declenche un renouvellement
  /// non bloquant si la session a expire.
  Map<String, String> getFreshHeaders() {
    // Ne relance un renouvellement que si un challenge avait reellement ete
    // obtenu. Sans clearance, boucler ne ferait que recreer l'echec initial.
    if (!_cookiesValid && !_noChallengeRequired) {
      unawaited(renewSession());
    }
    return videoHeaders;
  }

  /// Demarre un renouvellement preventif periodique.
  void _startRenewalTimer() {
    _renewalTimer?.cancel();
    if (_noChallengeRequired) return;
    _renewalTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (!_cookiesValid) {
        unawaited(renewSession());
      }
    });
  }

  bool get _cookiesValid =>
      _cookies.isNotEmpty &&
      _cookieExpiry != null &&
      DateTime.now().isBefore(_cookieExpiry!);

  /// Execute le challenge sous le drapeau _isChallenging et valide le resultat.
  Future<void> _runChallenge() async {
    if (_baseUrl.isEmpty) {
      throw StateError('CloudflareSessionManager: baseUrl not set');
    }

    _isChallenging = true;
    _notify();
    try {
      final result = await safeAsync<void>(
        _performChallenge,
        context: 'CloudflareSessionManager.challenge',
        reportToCrashlytics: false,
      );
      if (result.isFailure) {
        final err = result.errorOrNull!;
        throw err.originalError ?? err;
      }
      if (!_cookiesValid && !_noChallengeRequired) {
        throw StateError(
          'Cloudflare challenge finished but no cf_clearance cookie captured',
        );
      }
      _isInitialized = true;
      _startRenewalTimer();
    } finally {
      _isChallenging = false;
      _notify();
    }
  }

  /// Challenge WebView headless avec tentatives budgetisees.
  Future<void> _performChallenge() async {
    Object? lastError;
    for (var attempt = 0; attempt < _attemptTimeouts.length; attempt++) {
      final timeout = _attemptTimeouts[attempt];
      final startedAt = DateTime.now();
      debugPrint('☁️ [CF] attempt ${attempt + 1}/${_attemptTimeouts.length} '
          '(budget ${timeout.inSeconds}s) for $_baseUrl');
      try {
        await _runSingleAttempt(timeout);
        if (_cookiesValid) {
          debugPrint('☁️ [CF] clearance obtained on attempt ${attempt + 1} '
              'in ${DateTime.now().difference(startedAt).inMilliseconds}ms');
          return;
        }
        // La page s'est chargee normalement sans emettre de cf_clearance :
        // cet hote n'est pas derriere un challenge. Inutile d'insister.
        _noChallengeRequired = true;
        debugPrint('☁️ [CF] $_baseUrl ne requiert pas de challenge Cloudflare '
            '(page chargee en ${DateTime.now().difference(startedAt).inMilliseconds}ms)');
        return;
      } catch (e) {
        lastError = e;
        debugPrint('☁️ [CF] attempt ${attempt + 1} failed: $e');
      }
    }
    throw StateError('Cloudflare challenge failed: $lastError');
  }

  /// Une tentative de navigation, plafonnee par [timeout].
  Future<void> _runSingleAttempt(Duration timeout) async {
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_userAgent);

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    final cookieManager = WebViewCookieManager();
    final completer = Completer<void>();

    Future<void> onPageFinished(String url) async {
      if (completer.isCompleted) return;
      await _extractCookies(cookieManager, url);
      if (!completer.isCompleted) completer.complete();
    }

    void onHttpError(HttpResponseError error) {
      if (completer.isCompleted) return;
      completer.completeError(
        StateError('HTTP ${error.response?.statusCode} during CF challenge'),
      );
    }

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: onPageFinished,
        onNavigationRequest: (NavigationRequest request) =>
            NavigationDecision.navigate,
        onHttpError: onHttpError,
      ),
    );

    await controller.loadRequest(Uri.parse(_baseUrl));
    await completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'CF challenge still pending after ${timeout.inSeconds}s',
        timeout,
      ),
    );
  }

  /// Extrait les cookies Cloudflare apres le challenge.
  /// Les valeurs ne sont jamais journalisees.
  Future<void> _extractCookies(
    WebViewCookieManager cookieManager,
    String url,
  ) async {
    final uri = Uri.parse(url);
    final cookies = await cookieManager.getCookies(domain: uri);
    if (cookies.isEmpty) {
      debugPrint('☁️ [CF] no cookies returned for $url');
      return;
    }

    final relevant = cookies.where((c) {
      final n = c.name.toLowerCase();
      return n.startsWith('cf_') ||
          n.contains('session') ||
          n.contains('auth') ||
          n.contains('token');
    }).toList();

    final kept = relevant.isNotEmpty ? relevant : cookies;
    _cookies = kept.map((c) => '${c.name}=${c.value}').join('; ');
    _cookieExpiry = DateTime.now().add(_cookieLifetime);

    final hasClearance =
        kept.any((c) => c.name.toLowerCase() == 'cf_clearance');
    debugPrint('☁️ [CF] cookies captured: ${kept.length} entries, '
        '${_cookies.length} chars, cf_clearance=$hasClearance');
  }

  /// Detecte si une erreur de lecture est imputable a Cloudflare.
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
    _renewalTimer = null;
    _disposed = true;
    super.dispose();
  }
}
