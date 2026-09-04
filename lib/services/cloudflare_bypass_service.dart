import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Récupère les cookies Cloudflare (dont `cf_clearance`) en passant par un vrai
/// WebView Chromium, puis les réinjecte dans les requêtes HTTP du lecteur.
///
/// `cf_clearance` est lié à (IP, User-Agent). Comme le WebView et ExoPlayer
/// tournent sur le même appareil, l'IP correspond ; on mémorise donc aussi le
/// User-Agent utilisé par le WebView pour l'appliquer à la lecture.
class CloudflareBypassService {
  CloudflareBypassService._();

  static final CloudflareBypassService instance = CloudflareBypassService._();

  /// host (ex. `draap.online`) -> en-têtes à appliquer (Cookie + User-Agent).
  final Map<String, _CfEntries> _byHost = {};

  /// Métasynchronisé : évite de lancer deux WebViews pour le même host.
  final Map<String, Future<_CfEntries?>> _inFlight = {};

  /// Renvoie les en-têtes déjà obtenus pour [host], ou `null`.
  Map<String, String>? headersForHost(String host) {
    final e = _byHost[host];
    if (e == null) return null;
    return e.toHeaders();
  }

  bool hasCookieFor(String host) => _byHost[host]?.hasCfClearance == true;

  /// Force l'effacement (au cas où le cookie serait expiré / révoqué).
  void invalidate(String host) {
    _byHost.remove(host);
  }

  /// Ouvre un WebView plein écran sur [host], attend la résolution du
  /// challenge Cloudflare, récupère les cookies et construit les en-têtes.
  ///
  /// [context] sert à insérer le WebView. Renvoie les en-têtes, ou `null` si
  /// l'utilisateur ferme / l'acquisition échoue.
  Future<Map<String, String>?> obtainHeaders(
    BuildContext context,
    String host,
  ) {
    final pending = _inFlight[host];
    if (pending != null) {
      return pending.then((e) => e?.toHeaders());
    }
    final future = _doObtain(context, host);
    _inFlight[host] = future;
    future.whenComplete(() => _inFlight.remove(host));
    return future.then((e) => e?.toHeaders());
  }

  Future<_CfEntries?> _doObtain(BuildContext context, String host) async {
    final baseUrl = 'https://$host/';
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[CloudflareBypass] Page started: $url');
          },
          onPageFinished: (url) {
            debugPrint('[CloudflareBypass] Page finished: $url');
          },
          onNavigationRequest: (request) {
            debugPrint('[CloudflareBypass] Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    final completer = Completer<Map<String, String>>();
    late final OverlayEntry entry;

    // Délai d'attente global : après ce délai, on récolte ce qu'on a.
    final timer = Timer(const Duration(seconds: 60), () {
      if (completer.isCompleted) return;
      debugPrint('[CloudflareBypass] Global timeout, harvesting...');
      _harvest(baseUrl, controller).then(completer.complete).catchError((_) {
        completer.complete(<String, String>{});
      });
    });

    entry = OverlayEntry(
      builder: (bc) => _BypassOverlay(
        host: host,
        controller: controller,
        onDone: (cookies) {
          if (!completer.isCompleted) completer.complete(cookies);
        },
        onClose: () {
          if (!completer.isCompleted) completer.complete(<String, String>{});
        },
      ),
    );

    Overlay.of(context).insert(entry);

    // Charger la page d'accueil pour déclencher le challenge Cloudflare
    try {
      await controller.loadRequest(Uri.parse(baseUrl));
    } catch (e) {
      debugPrint('[CloudflareBypass] loadRequest error: $e');
    }

    try {
      final cookies = await completer.future;
      timer.cancel();
      if (cookies.isEmpty) {
        // Dernière tentative de collecte.
        final last = await _harvest(baseUrl, controller);
        cookies.addAll(last);
      }
      if (cookies.isEmpty) return null;
      final entries = _CfEntries.fromCookies(cookies);
      _byHost[host] = entries;
      debugPrint('[CloudflareBypass] Host=$host headers=${entries.toHeaders()}');
      return entries;
    } finally {
      if (entry.mounted) entry.remove();
    }
  }

  Future<Map<String, String>> _harvest(
    String baseUrl,
    WebViewController controller,
  ) async {
    final map = <String, String>{};
    try {
      final cookies = await WebViewCookieManager()
          .getCookies(domain: Uri.parse(baseUrl));
      for (final c in cookies) {
        if (c.name.trim().isNotEmpty) {
          map[c.name] = c.value;
          debugPrint('[CloudflareBypass] Cookie: ${c.name}=${c.value.substring(0, c.value.length > 20 ? 20 : c.value.length)}...');
        }
      }
      final ua = await _tryGetUserAgent(controller);
      if (ua != null && ua.isNotEmpty) {
        map['__user_agent__'] = ua;
        debugPrint('[CloudflareBypass] Captured UA: $ua');
      }
    } catch (e) {
      debugPrint('[CloudflareBypass] Harvest error: $e');
    }
    return map;
  }

  Future<String?> _tryGetUserAgent(WebViewController controller) async {
    try {
      final r = await controller.runJavaScriptReturningResult(
        'navigator.userAgent',
      );
      if (r is String) return r.replaceAll('"', '');
    } catch (_) {}
    return null;
  }
}

class _CfEntries {
  _CfEntries(this.cookies, this.userAgent);

  final Map<String, String> cookies;
  final String? userAgent;

  bool get hasCfClearance =>
      cookies.keys.any((k) => k.toLowerCase() == 'cf_clearance');

  static _CfEntries fromCookies(Map<String, String> raw) {
    final cookies = <String, String>{};
    String? ua;
    raw.forEach((k, v) {
      if (k == '__user_agent__') {
        ua = v;
      } else {
        cookies[k] = v;
      }
    });
    return _CfEntries(cookies, ua);
  }

  Map<String, String> toHeaders() {
    final headers = <String, String>{};
    if (userAgent != null && userAgent!.isNotEmpty) {
      headers['User-Agent'] = userAgent!;
    }
    if (cookies.isNotEmpty) {
      headers['Cookie'] = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
    }
    return headers;
  }
}

/// Overlay plein écran qui présente le WebView Cloudflare et un bouton
/// « Valider » une fois le challenge passé.
class _BypassOverlay extends StatefulWidget {
  const _BypassOverlay({
    required this.host,
    required this.controller,
    required this.onDone,
    required this.onClose,
  });

  final String host;
  final WebViewController controller;
  final void Function(Map<String, String>) onDone;
  final VoidCallback onClose;

  @override
  State<_BypassOverlay> createState() => _BypassOverlayState();
}

class _BypassOverlayState extends State<_BypassOverlay> {
  bool _checking = false;
  Timer? _autoCheckTimer;
  int _pageLoadCount = 0;

  @override
  void initState() {
    super.initState();
    // Vérification auto toutes les 3s pour détecter cf_clearance
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_checking) _harvestAndCheck();
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _harvestAndCheck() async {
    if (_checking) return;
    _checking = true;
    setState(() {});
    try {
      final cookies = await WebViewCookieManager()
          .getCookies(domain: Uri.parse('https://${widget.host}/'));
      final map = <String, String>{};
      bool hasCf = false;
      for (final c in cookies) {
        if (c.name.trim().isNotEmpty) {
          map[c.name] = c.value;
          if (c.name.toLowerCase() == 'cf_clearance') hasCf = true;
        }
      }
      if (hasCf) {
        debugPrint('[CloudflareBypass] cf_clearance detected, auto-completing');
        widget.onDone(map);
        return;
      }
      _pageLoadCount++;
      // Recharger la page toutes les 2 vérifications si pas de cookie
      if (_pageLoadCount % 2 == 0) {
        debugPrint('[CloudflareBypass] Reloading page to trigger challenge...');
        try {
          await widget.controller.loadRequest(Uri.parse('https://${widget.host}/'));
        } catch (_) {}
      }
    } catch (_) {}
    finally {
      if (mounted) {
        _checking = false;
        setState(() {});
      }
    }
  }

  Future<void> _harvestAndDone() async {
    if (_checking) return;
    _checking = true;
    setState(() {});
    try {
      final cookies = await WebViewCookieManager()
          .getCookies(domain: Uri.parse('https://${widget.host}/'));
      final map = <String, String>{};
      for (final c in cookies) {
        if (c.name.trim().isNotEmpty) map[c.name] = c.value;
      }
      widget.onDone(map);
    } catch (_) {
      widget.onDone(<String, String>{});
    } finally {
      if (mounted) {
        _checking = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                  Expanded(
                    child: Text(
                      'Vérification ${widget.host}',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _checking ? null : _harvestAndDone,
                    child: Text(_checking ? 'Attente…' : 'Valider'),
                  ),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: widget.controller)),
            if (_checking)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(color: Color(0xFF00CFE8)),
              ),
          ],
        ),
      ),
    );
  }
}
