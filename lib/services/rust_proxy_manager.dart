import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:orbit_3d_flutter/services/stream_relay.dart'
    show kRustProxyBase, kRustProxyStatusPath;

/// Cycle de vie du process proxy Rust local, vu depuis l'app.
enum RustProxyLifecycle { idle, starting, running, failed, stopped }

/// État renvoyé par `GET /api/proxy-status` (structures alignées sur
/// `status::ProxyStatus` côté Rust).
@immutable
class RustProxyStatus {
  const RustProxyStatus({
    required this.status,
    required this.port,
    required this.cacheHitRatio,
    required this.segmentsCached,
    required this.proxyMode,
    required this.wafBlocks,
    required this.upstreamFallbackRetries,
    required this.sessionResets,
  });

  factory RustProxyStatus.fromJson(Map<String, dynamic> json) {
    return RustProxyStatus(
      status: json['status'] as String? ?? 'unknown',
      port: (json['port'] as num?)?.toInt() ?? 0,
      cacheHitRatio: (json['cache_hit_ratio'] as num?)?.toDouble() ?? 0,
      segmentsCached: (json['segments_cached'] as num?)?.toInt() ?? 0,
      proxyMode: json['proxy_mode'] as String? ?? '',
      wafBlocks: (json['waf_blocks'] as num?)?.toInt() ?? 0,
      upstreamFallbackRetries:
          (json['upstream_fallback_retries'] as num?)?.toInt() ?? 0,
      sessionResets: (json['session_resets'] as num?)?.toInt() ?? 0,
    );
  }

  final String status;
  final int port;
  final double cacheHitRatio;
  final int segmentsCached;
  final String proxyMode;

  /// Réponses upstream bloquées par le WAF (403/406/429/503).
  final int wafBlocks;

  /// Basculements sur l'empreinte TLS de secours.
  final int upstreamFallbackRetries;

  /// Sessions jugées invalides côté proxy (re-bootstrap attendu).
  final int sessionResets;
}

/// Pilote le process proxy Rust : détection du binaire, démarrage, watchdog
/// (relance si mort + renewal proactif de session si le WAF bloque en
/// répété), arrêt à la destruction, ping `/api/proxy-status` avant de marquer
/// « ready ».
///
/// Singleton Riverpod-free : une seule instance partagée, exposée à Riverpod
/// via [rustProxyManagerProvider] (voir `providers.dart`). La classe ne fait
/// AUCUN appel réseau/process en import — tout est déclenché par `start()`.
class RustProxyManager {
  RustProxyManager._();

  static final RustProxyManager instance = RustProxyManager._();

  /// Nom du binaire (sans extension ; `.exe` ajouté sur Windows).
  static const String binaryName = 'orbit_proxy_server';

  /// Nombre maximal de relances automatiques consécutives (watchdog borné).
  static const int maxRestartAttempts = 3;

  /// Nombre de nouveaux blocages WAF (delta observé entre deux pings du
  /// watchdog) au-delà duquel la session est renouvelée proactivement.
  static const int wafBlockRestartThreshold = 8;

  /// Nombre maximal de renewals proactifs consécutifs sans période saine
  /// (anti-boucle : si le WAF continue de bloquer, on arrête de relancer).
  static const int maxSessionResets = 3;

  final ValueNotifier<bool> _ready = ValueNotifier<bool>(false);
  final ValueNotifier<RustProxyLifecycle> _lifecycle =
      ValueNotifier<RustProxyLifecycle>(RustProxyLifecycle.idle);

  Process? _process;
  Timer? _watchdog;
  Completer<void>? _starting;
  RustProxyStatus? _lastStatus;
  int _restartCount = 0;

  /// Dernier `waf_blocks` observé (delta → renewal proactif).
  int _lastSeenWafBlocks = 0;

  /// Renewals proactifs effectués depuis la dernière période saine.
  int _rebootCount = 0;

  /// Anti-chevauchement du tick périodique du watchdog (ping lent).
  bool _watchdogBusy = false;

  bool _disposed = false;
  bool _manualStop = false;

  /// Crochet Android à brancher en S4 (lancement du binaire natif via FFI /
  /// `flutter_rust_bridge` ou `Process.start` sur le support dir). Tant qu'il
  /// est `null`, `start()` est un no-op structuré sur Android/iOS (aucun
  /// crash) — le desktop et les tests restent fonctionnels immédiatement.
  Future<Process> Function(String binaryPath)? androidProcessLauncher;

  static const Duration _pingTimeout = Duration(seconds: 2);
  static const Duration _readyTimeout = Duration(seconds: 5);
  static const Duration _watchdogInterval = Duration(seconds: 8);

  /// `true` quand le process a répondu au ping `/api/proxy-status`.
  bool get isReady => _ready.value;

  /// Notifiable Riverpod-agnostic (consommable via `ref.listen` à la main).
  ValueListenable<bool> get readyListenable => _ready;
  ValueListenable<RustProxyLifecycle> get lifecycleListenable => _lifecycle;

  RustProxyLifecycle get lifecycle => _lifecycle.value;
  RustProxyStatus? get lastStatus => _lastStatus;

  /// Base HTTP du proxy local (défaut `http://127.0.0.1:8787`).
  String get proxyBase => kRustProxyBase;

  String get binaryFileName =>
      Platform.isWindows ? '$binaryName.exe' : binaryName;

  /// Démarre le proxy s'il n'est pas déjà prêt (idempotent ; attend la fin
  /// d'un démarrage en cours). Sur plateformes non supportées (Android sans
  /// hook, etc.) revient immédiatement.
  Future<void> ensureStarted() async {
    if (_disposed || _manualStop) return;
    if (isReady) return;
    if (_lifecycle.value == RustProxyLifecycle.starting) {
      await _starting?.future;
      return;
    }
    await start();
  }

  /// Démarre le binaire et attend un ping positif. No-op si déjà prêt,
  /// si un démarrage est en cours ou si la plateforme n'est pas supportée.
  Future<void> start({String? binaryPath, bool isRestart = false}) async {
    if (_disposed || _manualStop) return;
    if (isReady || _lifecycle.value == RustProxyLifecycle.starting) return;
    if (isRestart && _restartCount >= maxRestartAttempts) return;
    if (!_processSupported()) {
      _lifecycle.value = RustProxyLifecycle.stopped;
      return;
    }

    final starting = Completer<void>();
    _starting = starting;
    _lifecycle.value = RustProxyLifecycle.starting;

    try {
      final binary = binaryPath ?? await resolveBinaryPath();
      if (binary == null) {
        debugPrint('[RustProxy] Binaire introuvable — proxy désactivé.');
        _lifecycle.value = RustProxyLifecycle.failed;
        return;
      }

      final process = await _launchProcess(binary);
      _process = process;
      _manualStop = false;

      process.stdout.transform(utf8.decoder).listen((chunk) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isNotEmpty) debugPrint('[RustProxy:out] $line');
        }
      });
      process.stderr.transform(utf8.decoder).listen((chunk) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isNotEmpty) debugPrint('[RustProxy:err] $line');
        }
      });

      unawaited(_watchExit(process));
      _startWatchdog();

      final ok = await _waitUntilReady();
      if (ok) {
        _restartCount = 0;
        _rebootCount = 0;
        _lastSeenWafBlocks = _lastStatus?.wafBlocks ?? 0;
        _ready.value = true;
        _lifecycle.value = RustProxyLifecycle.running;
        debugPrint('[RustProxy] Prêt et vérifié sur $proxyBase.');
      } else {
        _lifecycle.value = RustProxyLifecycle.failed;
        await _kill(process);
        if (identical(_process, process)) _process = null;
        debugPrint(
          '[RustProxy] Démarrage échoué : ping $kRustProxyStatusPath KO.',
        );
      }
    } catch (e) {
      debugPrint('[RustProxy] start() error: $e');
      _lifecycle.value = RustProxyLifecycle.failed;
    } finally {
      _starting = null;
      if (!starting.isCompleted) starting.complete();
    }
  }

  /// Interroge `GET /api/proxy-status`. Met à jour [lastStatus] en cas de
  /// réponse JSON exploitable. Renvoie `true` si HTTP 200.
  Future<bool> ping() async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse('$proxyBase$kRustProxyStatusPath'))
          .timeout(_pingTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(_pingTimeout);
      if (response.statusCode != HttpStatus.ok) return false;
      final body =
          await response.transform(utf8.decoder).join().timeout(_pingTimeout);
      _tryParseStatus(body);
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Arrête le process (SIGTERM puis SIGKILL en secours) et le watchdog.
  Future<void> stop() async {
    _manualStop = true;
    _watchdog?.cancel();
    _watchdog = null;
    _ready.value = false;
    _lifecycle.value = RustProxyLifecycle.stopped;
    final process = _process;
    _process = null;
    if (process == null) return;
    await _kill(process);
  }

  /// Stop + libère les notifiers. Appelé par le provider (`ref.onDispose`).
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    _ready.dispose();
    _lifecycle.dispose();
  }

  /// Cherche le binaire du proxy dans l'ordre :
  ///   1. `ORBIT_PROXY_BIN` (CI / tests / desktop avancé) ;
  ///   2. asset extrait : `<support>/orbit_rust_proxy/<bin>` puis `<support>/` ;
  ///   3. Android : `<externalStorage>/orbit_rust_proxy/<bin>` puis racine ;
  ///   4. à côté de l'exécutable (desktop : launcher / répertoire de build).
  Future<String?> resolveBinaryPath() async {
    final fromEnv = Platform.environment['ORBIT_PROXY_BIN'];
    if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
      return fromEnv;
    }

    final fileName = binaryFileName;
    for (final dir in await _candidateDirs()) {
      final candidate = '$dir${Platform.pathSeparator}$fileName';
      if (File(candidate).existsSync()) return candidate;
    }

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final candidate = '$exeDir${Platform.pathSeparator}$fileName';
      if (File(candidate).existsSync()) return candidate;
    } catch (_) {}

    return null;
  }

  /// Répertoires susceptibles de contenir le binaire extrait/bundlé.
  Future<List<String>> _candidateDirs() async {
    final dirs = <String>[];
    try {
      final support = await getApplicationSupportDirectory();
      dirs.add('${support.path}${Platform.pathSeparator}orbit_rust_proxy');
      dirs.add(support.path);
    } catch (_) {}
    if (kIsWeb) return dirs;
    try {
      if (Platform.isAndroid) {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          dirs.add('${ext.path}${Platform.pathSeparator}orbit_rust_proxy');
          dirs.add(ext.path);
        }
      }
    } catch (_) {}
    return dirs;
  }

  /// Vanne de branchement Android (S4) + garde-fous desktop/tests.
  Future<Process> _launchProcess(String binary) async {
    final launcher = androidProcessLauncher;
    if (launcher != null && (Platform.isAndroid || Platform.isIOS)) {
      return launcher(binary);
    }
    return Process.start(
      binary,
      const <String>[],
      mode: ProcessStartMode.normal,
      runInShell: false,
    );
  }

  /// Marque le décès du process ; le watchdog périodique relance ensuite.
  Future<void> _watchExit(Process process) async {
    final code = await process.exitCode;
    if (_disposed || !identical(_process, process)) return;
    debugPrint('[RustProxy] Process arrêté (exit $code).');
    _process = null;
    _ready.value = false;
    _lifecycle.value = RustProxyLifecycle.stopped;
  }

/// Watchdog : tant que le manager n'est pas détruit ni arrêté à la main :
///   - process vivant et prêt → ping + renewal proactif si le WAF bloque en
///     répété ([_maybeRebootstrap]) ;
///   - process absent (mort, jamais démarré) → relance, bornée à
///     [maxRestartAttempts] consécutifs avant d'abandonner.
void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogInterval, (_) async {
      if (_disposed || _manualStop) return;
      if (_watchdogBusy) return;
      _watchdogBusy = true;
      try {
        if (_process != null && isReady) {
          await ping();
          await _maybeRebootstrap();
          return;
        }
        if (_process != null || isReady) return;
        if (_restartCount >= maxRestartAttempts) return;
        if (_lifecycle.value == RustProxyLifecycle.failed) return;
        _restartCount++;
        debugPrint(
          '[RustProxy] Watchdog : relance $_restartCount/$maxRestartAttempts…',
        );
        unawaited(start(isRestart: true));
      } finally {
        _watchdogBusy = false;
      }
    });
  }

  /// Renewal proactif de la session (spec Cloudflare, pilier 3) : si le
  /// nombre de blocages WAF a augmenté de plus de [wafBlockRestartThreshold]
  /// depuis le dernier ping, on renouvelle la session (le proxy repart avec
  /// un cookie jar et un pool TLS neufs). Une période sans nouveau blocage
  /// réarme le compteur de renewals.
  Future<void> _maybeRebootstrap() async {
    if (_disposed || _manualStop) return;
    final status = _lastStatus;
    if (status == null) return;

    final delta = status.wafBlocks - _lastSeenWafBlocks;
    _lastSeenWafBlocks = status.wafBlocks;

    if (delta <= 0) {
      // Session saine : aucun nouveau blocage → on réarme les renewals.
      _rebootCount = 0;
      return;
    }
    if (delta < wafBlockRestartThreshold || _rebootCount >= maxSessionResets) {
      return;
    }

    _rebootCount++;
    debugPrint(
      '[RustProxy] Blocages WAF répétés (delta $delta, total ${status.wafBlocks}) '
      '→ renewal proactif de la session…',
    );
    await restartSession();
  }

  /// Renewal proactif : tue le process (cookie jar + pool TLS re-créés à la
  /// relance), puis redémarre. Les segments déjà bufferisés par le player ne
  /// sont pas affectés ; les suivants repartent sur la nouvelle session.
  Future<void> restartSession() async {
    if (_disposed || _manualStop) return;
    debugPrint('[RustProxy] restartSession()…');
    await stop();
    // stop() pose _manualStop=true pour ne pas se faire relancer en boucle ;
    // ici on veut au contraire un nouveau start immédiat.
    _manualStop = false;
    _restartCount = 0;
    _rebootCount = 0;
    await start(isRestart: true);
  }

  /// Attend que le process réponde à `/api/proxy-status`, ou abandonne.
  Future<bool> _waitUntilReady() async {
    final deadline = DateTime.now().add(_readyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_disposed || _manualStop) return false;
      if (_process == null) return false;
      if (await ping()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  void _tryParseStatus(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        _lastStatus =
            RustProxyStatus.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Réponse non-JSON : on ignore, le booléen du ping reste la vérité.
    }
  }

  Future<void> _kill(Process process) async {
    try {
      process.kill(ProcessSignal.sigterm);
    } catch (_) {}
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } catch (_) {
      try {
        process.kill(ProcessSignal.sigkill);
      } catch (_) {}
    }
  }

  /// Plateformes supportées par le `Process.start` générique de ce sprint.
  bool _processSupported() {
    if (kIsWeb) return false;
    if (Platform.isAndroid || Platform.isIOS) {
      // Le process natif Android (FFI / binaire bundled) sera branché via
      // [androidProcessLauncher] en S4 : aujourd'hui pas de support natif.
      return androidProcessLauncher != null;
    }
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }
}
