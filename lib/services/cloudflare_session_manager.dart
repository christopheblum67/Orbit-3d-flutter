import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';

@visibleForTesting
Future<String> readCloudflareCookies({
  required Future<String> Function() readNative,
  required Future<String> Function() readJavaScript,
}) async {
  try {
    final cookies = await readNative();
    if (cookies.isNotEmpty) return cookies;
  } catch (_) {
    debugPrint('[CF] Native cookie storage unavailable');
  }
  try {
    return await readJavaScript();
  } catch (_) {
    debugPrint('[CF] JavaScript cookie storage unavailable');
    return '';
  }
}

/// Gestionnaire de session Cloudflare pour le zapping IPTV.
///
/// Intercepte le challenge Cloudflare via WebView headless, extrait les cookies
/// (cf_clearance) et le User-Agent, et les injecte dans les headers du lecteur video.
///
/// Ce service est volontairement independant de l'UI : il ne manipule aucun
/// BuildContext. Le fallback manuel (WebView visible) est du ressort de
/// [PlayerScreen] via `CloudflareBypassService.obtainHeaders(context, host)`.
class CloudflareSessionManager extends ChangeNotifier {
  static final CloudflareSessionManager _instance =
      CloudflareSessionManager._internal();
  static const _cookieChannel = MethodChannel('orbit/cloudflare_cookies');
  factory CloudflareSessionManager() => _instance;
  CloudflareSessionManager._internal()
      : _attemptTimeouts = _defaultAttemptTimeouts;
  @visibleForTesting
  CloudflareSessionManager.forTesting({
    List<Duration> attemptTimeouts = _defaultAttemptTimeouts,
  }) : _attemptTimeouts = attemptTimeouts;

  static const String _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

  /// Budget par tentative. Les delais sont reellement appliques via
  /// `Future.timeout`, ce qui evite qu'un challenge bloque indefiniment.
  static const List<Duration> _defaultAttemptTimeouts = <Duration>[
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 45),
  ];
  final List<Duration> _attemptTimeouts;

  /// Duree de vie prudente d'un cookie cf_clearance avant renouvellement.
  static const Duration _cookieLifetime = Duration(hours: 2);

  String _userAgent = _defaultUserAgent;

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
  Future<void>? _pendingRenewal;

  static const String _sessionSecretKey = 'cloudflare_session';
  // Anciennes clés : migration vers le coffre après une écriture réussie.
  static const String _prefsKeyCookies = 'cf_cookies';
  static const String _prefsKeyUserAgent = 'cf_user_agent';
  static const String _prefsKeyBaseUrl = 'cf_base_url';
  static const String _prefsKeyExpiry = 'cf_cookie_expiry';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var serialized = await readSecretStrict(_sessionSecretKey);
      if (serialized == null) {
        final legacyCookies = prefs.getString(_prefsKeyCookies);
        final legacyUa = prefs.getString(_prefsKeyUserAgent);
        final legacyBase = prefs.getString(_prefsKeyBaseUrl);
        final legacyExpiry = prefs.getInt(_prefsKeyExpiry);
        if (legacyCookies != null &&
            legacyUa != null &&
            legacyBase != null &&
            legacyExpiry != null) {
          serialized = jsonEncode({
            'cookies': legacyCookies,
            'userAgent': legacyUa,
            'baseUrl': legacyBase,
            'expiry': legacyExpiry,
          });
          await writeSecretStrict(_sessionSecretKey, serialized);
        }
      }
      if (serialized == null) return;
      final session = jsonDecode(serialized) as Map<String, dynamic>;
      final cookies = session['cookies'] as String?;
      final ua = session['userAgent'] as String?;
      final base = session['baseUrl'] as String?;
      final expiryMs = session['expiry'] as int?;
      await prefs.remove(_prefsKeyCookies);
      await prefs.remove(_prefsKeyUserAgent);
      await prefs.remove(_prefsKeyBaseUrl);
      await prefs.remove(_prefsKeyExpiry);
      if (cookies != null && ua != null && base != null && expiryMs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
        if (expiry.isAfter(DateTime.now())) {
          _cookies = cookies;
          _userAgent = ua;
          _baseUrl = base;
          _cookieExpiry = expiry;
          _isInitialized = true;
          _noChallengeRequired = false;
          _startRenewalTimer();
          debugPrint('☁️ [CF] session restaurée depuis le stockage local');
        }
      }
    } catch (_) {
      // Non bloquant : on repart sur un challenge frais.
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      await writeSecretStrict(
        _sessionSecretKey,
        jsonEncode({
          'cookies': _cookies,
          'userAgent': _userAgent,
          'baseUrl': _baseUrl,
          'expiry': _cookieExpiry?.millisecondsSinceEpoch ?? 0,
        }),
      );
    } catch (_) {
      // Non bloquant.
    }
  }

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
  Map<String, String> get videoHeaders {
    final headers = <String, String>{
      'User-Agent': _userAgent,
      'Referer': _baseUrl,
      'Accept': '*/*',
      'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
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
      final parsed = Uri.tryParse(baseUrl);
      if (parsed == null ||
          !parsed.hasAuthority ||
          parsed.userInfo.isNotEmpty ||
          (parsed.scheme != 'http' && parsed.scheme != 'https')) {
        throw ArgumentError('Invalid Cloudflare origin');
      }
      final origin = parsed.origin;
      _disposed = false;
      if (isReady &&
          (_cookiesValid || _noChallengeRequired) &&
          _baseUrl == origin) {
        return;
      }
      await _loadFromPrefs();
      if (isReady && _cookiesValid && _baseUrl == origin) return;

      // Un changement d'hote peut reintroduire un challenge : on repart de zero.
      if (_baseUrl != origin) {
        _noChallengeRequired = false;
        _cookies = '';
        _cookieExpiry = null;
      }
      _baseUrl = origin;
      _isInitialized = false;
      await _runChallenge();
    });
  }

  /// Force un nouveau challenge (cookie expire, erreur 403, zapping changement
  /// de host). Ne deadloque pas : le corps du challenge est inline.
  Future<void> renewSession({bool force = false}) {
    final pending = _pendingRenewal;
    if (pending != null) return pending;
    final renewal = _synchronized(() async {
      _disposed = false;
      if (!force && isReady && _cookiesValid) return;

      debugPrint('☁️ [CF] renewing Cloudflare session');
      final previousCookies = _cookies;
      final previousExpiry = _cookieExpiry;
      final previousUserAgent = _userAgent;
      _noChallengeRequired = false;
      _cookies = '';
      _cookieExpiry = null;
      _isInitialized = false;
      try {
        await _runChallenge();
      } catch (_) {
        if (previousCookies.isNotEmpty &&
            previousExpiry != null &&
            previousExpiry.isAfter(DateTime.now())) {
          _cookies = previousCookies;
          _cookieExpiry = previousExpiry;
          _userAgent = previousUserAgent;
          _isInitialized = true;
          _notify();
        }
        rethrow;
      }
    });
    _pendingRenewal = renewal;
    return renewal.whenComplete(() {
      if (identical(_pendingRenewal, renewal)) _pendingRenewal = null;
    });
  }

  /// Headers a utiliser pour une lecture. Declenche un renouvellement
  /// non bloquant si la session a expire.
  Map<String, String> getFreshHeaders() {
    // Ne relance un renouvellement que si un challenge avait reellement ete
    // obtenu. Sans clearance, boucler ne ferait que recreer l'echec initial.
    if (!_cookiesValid && !_noChallengeRequired) {
      unawaited(renewSession().catchError((Object _) {}));
    } else if (_cookieExpiry != null &&
        DateTime.now()
            .add(const Duration(minutes: 15))
            .isAfter(_cookieExpiry!) &&
        !_noChallengeRequired) {
      unawaited(renewSession(force: true).catchError((Object _) {}));
    }
    return videoHeaders;
  }

  /// Demarre un renouvellement preventif periodique.
  void _startRenewalTimer() {
    _renewalTimer?.cancel();
    if (_noChallengeRequired) return;
    _renewalTimer = Timer.periodic(const Duration(minutes: 90), (_) {
      if (!_cookiesValid) {
        unawaited(renewSession().catchError((Object _) {}));
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
          '(budget ${timeout.inSeconds}s)');
      try {
        await _runSingleAttempt(timeout);
        if (_cookiesValid) {
          await _saveToPrefs();
          debugPrint('☁️ [CF] clearance obtained on attempt ${attempt + 1} '
              'in ${DateTime.now().difference(startedAt).inMilliseconds}ms');
          return;
        }
        // La page s'est chargee normalement sans emettre de cf_clearance :
        // cet hote n'est pas derriere un challenge. Inutile d'insister.
        _noChallengeRequired = true;
        debugPrint('☁️ [CF] aucun challenge Cloudflare requis '
            '(page chargee en ${DateTime.now().difference(startedAt).inMilliseconds}ms)');
        return;
      } catch (_) {
        lastError = StateError('Cloudflare attempt failed');
        debugPrint('☁️ [CF] attempt ${attempt + 1} failed');
      }
    }
    throw StateError('Cloudflare challenge failed: $lastError');
  }

  /// Une tentative de navigation, plafonnee par [timeout].
  Future<void> _runSingleAttempt(Duration timeout) async {
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final nativeUserAgent = await controller.getUserAgent();
    if (nativeUserAgent != null && nativeUserAgent.trim().isNotEmpty) {
      _userAgent = nativeUserAgent;
    } else {
      await controller.setUserAgent(_userAgent);
    }

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    final cookieManager = WebViewCookieManager();
    final completer = Completer<String?>();
    var active = true;
    var pageGeneration = 0;
    int? mainHttpError;
    Uri? mainPage;

    // Cloudflare résout son challenge JavaScript APRÈS le chargement de la
    // page. On poll les cookies jusqu'à capturer cf_clearance, OU jusqu'à
    // confirmer que la page n'est pas un challenge Cloudflare.
    Future<void> onPageFinished(String url) async {
      if (!active || completer.isCompleted) return;
      final generation = ++pageGeneration;
      final current = Uri.tryParse(url);
      final expected = Uri.tryParse(_baseUrl);
      if (current == null ||
          expected == null ||
          !current.hasAuthority ||
          !expected.hasAuthority ||
          (current.scheme != 'http' && current.scheme != 'https') ||
          (expected.scheme != 'http' && expected.scheme != 'https') ||
          current.origin != expected.origin) {
        completer.completeError(StateError('Cloudflare origin changed'));
        return;
      }
      while (active && !completer.isCompleted && generation == pageGeneration) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!active || completer.isCompleted || generation != pageGeneration) {
          return;
        }
        final cookies = await _extractCookies(controller, cookieManager, url);
        if (!active || completer.isCompleted || generation != pageGeneration) {
          return;
        }
        if (cookies != null && mainHttpError == null) {
          completer.complete(cookies);
          return;
        }
        // Vérifie si la page est un challenge Cloudflare non résolu.
        try {
          final title = await controller.runJavaScriptReturningResult(
            'document.title',
          );
          if (!active ||
              completer.isCompleted ||
              generation != pageGeneration) {
            return;
          }
          final t = title.toString().toLowerCase();
          final isChallenge = t.contains('just a moment') ||
              t.contains('checking your browser') ||
              t.contains('attention required') ||
              t.contains('cloudflare');
          if (!isChallenge && mainHttpError == null) {
            // Page normale : pas de challenge requis.
            completer.complete(null);
            return;
          }
        } catch (_) {}
      }
    }

    void onHttpError(HttpResponseError error) {
      if (!active || completer.isCompleted) return;
      final request = error.request?.uri;
      final expected = Uri.parse(_baseUrl);
      final page = mainPage ?? expected;
      if (request == null ||
          (request.scheme != 'http' && request.scheme != 'https') ||
          request.origin != expected.origin ||
          (request.path.isEmpty ? '/' : request.path) !=
              (page.path.isEmpty ? '/' : page.path) ||
          request.query != page.query) {
        return;
      }
      final status = error.response?.statusCode;
      mainHttpError = status;
      if (status == 403 || status == 503) return;
      completer.completeError(
        StateError('HTTP $status during CF challenge'),
      );
    }

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          pageGeneration++;
          mainHttpError = null;
          mainPage = Uri.tryParse(url);
        },
        onPageFinished: onPageFinished,
        onNavigationRequest: (NavigationRequest request) =>
            NavigationDecision.navigate,
        onHttpError: onHttpError,
      ),
    );

    try {
      final results = await Future.wait<Object?>([
        controller.loadRequest(Uri.parse(_baseUrl)).then<Object?>((_) => null),
        completer.future,
      ]).timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'CF challenge still pending after ${timeout.inSeconds}s',
          timeout,
        ),
      );
      final cookies = results[1] as String?;
      if (cookies == null) {
        _noChallengeRequired = true;
      } else {
        _cookies = cookies;
        _cookieExpiry = DateTime.now().add(_cookieLifetime);
      }
    } finally {
      active = false;
      pageGeneration++;
    }
  }

  /// Lit d'abord le stockage natif, qui inclut les cookies HttpOnly.
  Future<String?> _extractCookies(
    WebViewController controller,
    WebViewCookieManager cookieManager,
    String url,
  ) async {
    final raw = await readCloudflareCookies(
      readNative: () async {
        if (Platform.isAndroid) {
          return await _cookieChannel.invokeMethod<String>(
                'getCookies',
                {'url': url},
              ) ??
              '';
        }
        final cookies = await cookieManager.getCookies(domain: Uri.parse(url));
        return cookies.map((c) => '${c.name}=${c.value}').join('; ');
      },
      readJavaScript: () async =>
          (await controller.runJavaScriptReturningResult('document.cookie'))
              .toString()
              .replaceAll('"', ''),
    );

    if (raw.isEmpty) {
      debugPrint('☁️ [CF] no cookies returned');
      return null;
    }

    final entries =
        raw.split(';').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    // On conserve cf_clearance + autres cookies Cloudflare/sessions.
    final relevant = entries.where((c) {
      final name = c.split('=').first.toLowerCase();
      return name.startsWith('cf_') ||
          name.contains('session') ||
          name.contains('auth') ||
          name.contains('token');
    }).toList();

    final kept = relevant.isNotEmpty ? relevant : entries;
    final hasClearance = kept.any((cookie) {
      final separator = cookie.indexOf('=');
      return separator > 0 &&
          cookie.substring(0, separator).toLowerCase() == 'cf_clearance' &&
          cookie.substring(separator + 1).trim().isNotEmpty;
    });
    if (!hasClearance) return null;

    debugPrint('☁️ [CF] cookies captured: ${kept.length} entries, '
        'cf_clearance=$hasClearance');
    return kept.join('; ');
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
