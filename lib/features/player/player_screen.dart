import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/stream_prewarm_service.dart';
import 'package:orbit_3d_flutter/services/cloudflare_bypass_service.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';

class PlayerRouteData {
  const PlayerRouteData({
    required this.streamUrl,
    this.title,
    this.channels = const [],
    this.index = 0,
    this.progressId,
    this.initialPositionMs,
    this.contentType = PlaybackContentType.live,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int index;
  final String? progressId;
  final int? initialPositionMs;
  final PlaybackContentType contentType;
}

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.streamUrl,
    this.title,
    this.channels = const [],
    this.initialIndex = 0,
    this.progressId,
    this.initialPositionMs,
    this.contentType = PlaybackContentType.live,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int initialIndex;
  final String? progressId;
  final int? initialPositionMs;
  final PlaybackContentType contentType;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

enum _PlayerStatus { loading, error, ready }

/// Durée maximale accordée à initialise() avant de basculer sur le
/// prochain User-Agent : évite de bloquer le zapping sur un flux muet.
const _probTimeout = Duration(seconds: 12);

/// Durée d'affichage de la barre d'info avant masquage automatique.
const _infoBarDuration = Duration(milliseconds: 4500);

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  List<Channel> _channels = const [];
  late int _index;
  VideoPlayerController? _controller;
  VideoPlayerController? _cachedNext;
  int? _cachedNextIndex;
  VideoPlayerController? _cachedPrev;
  int? _cachedPrevIndex;
  int? _preloadTarget;
  _PlayerStatus _status = _PlayerStatus.loading;
  bool _handlingError = false;
  bool _autorecovered = false;
  int _generation = 0;
  bool _showInfo = false;
  Timer? _infoTimer;
  Timer? _saveProgressTimer;
  Timer? _statusBarTimer;
  bool _volumeToZap = false;
  bool _immersive = false;
  bool _statusBarVisible = false;
  bool _hasAppliedInitialPosition = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerScreen');

  bool get _canZap => _channels.length > 1;
  bool get _hasNext => _canZap && _index < _channels.length - 1;
  bool get _hasPrevious => _canZap && _index > 0;

  String get _activeStreamUrl {
    if (_channels.isEmpty) return widget.streamUrl;
    return _channels[_index].streamUrl.isNotEmpty
        ? _channels[_index].streamUrl
        : widget.streamUrl;
  }

  Channel? get _currentChannel => _channels.isEmpty ? null : _channels[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channels = widget.channels;
    _index = widget.initialIndex;
    if (_channels.isNotEmpty) {
      if (_index < 0) _index = 0;
      if (_index >= _channels.length) _index = _channels.length - 1;
    }
    _initializePlayer();
    _startSaveProgressTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreSystemUi();
    _infoTimer?.cancel();
    _saveProgressTimer?.cancel();
    _statusBarTimer?.cancel();
    _saveProgress();
    _focusNode.dispose();
    _generation++;
    _disposeActive();
    _disposeCachedNext();
    _disposeCachedPrev();
    _preloadTarget = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncImmersive();
    } else {
      _restoreSystemUi();
    }
  }

  /// Passe en plein écran immersif (masque status bar + navbar Android)
  /// quand la vidéo joue. Ne fait RIEN si la barre est temporairement visible
  /// (touch/OK) — le timer la masquera après 25s.
  void _syncImmersive() {
    final playing = _status == _PlayerStatus.ready &&
        _controller != null &&
        _controller!.value.isPlaying;
    if (playing && !_immersive && !_statusBarVisible) {
      _immersive = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    } else if (!playing && _immersive) {
      _restoreSystemUi();
    }
  }

  /// Affiche les barres système (status + nav) pendant [duration] puis
  /// repasse en immersiveSticky. Appelé sur tap écran ou touche OK.
  void _showStatusBarTemporarily(
      {Duration duration = const Duration(seconds: 25)}) {
    if (_statusBarVisible) {
      _statusBarTimer?.cancel();
    } else {
      _statusBarVisible = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _statusBarTimer = Timer(duration, () {
      if (mounted) {
        _statusBarVisible = false;
        _statusBarTimer = null;
        _syncImmersive(); // repasse en immersive si lecture en cours
      }
    });
  }

  /// Restaure la system UI par défaut de l'application (sortie player, pause).
  void _restoreSystemUi() {
    _statusBarTimer?.cancel();
    _statusBarVisible = false;
    if (!_immersive) return;
    _immersive = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Démarre le timer de sauvegarde périodique de la progression.
  void _startSaveProgressTimer() {
    if (widget.progressId == null) return;
    _saveProgressTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveProgress(),
    );
  }

  /// Sauvegarde la position courante de lecture.
  void _saveProgress() {
    final id = widget.progressId;
    if (id == null) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    final duration = controller.value.duration;
    final positionMs = position.inMilliseconds;
    final durationMs = duration.inMilliseconds;
    // Si la lecture est terminée (> 95 %), on efface la progression.
    if (durationMs > 0 && positionMs > durationMs * 0.95) {
      ref.read(playbackProgressServiceProvider).clear(id);
    } else {
      ref
          .read(playbackProgressServiceProvider)
          .save(id, positionMs, durationMs);
    }
  }

  /// Applique la position initiale si elle est fournie et que le controller
  /// est prêt.
  void _applyInitialPosition() {
    if (_hasAppliedInitialPosition) return;
    final initialMs = widget.initialPositionMs;
    if (initialMs == null || initialMs <= 0) {
      _hasAppliedInitialPosition = true;
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    _hasAppliedInitialPosition = true;
    final position = Duration(milliseconds: initialMs);
    final duration = controller.value.duration;
    if (position < duration) {
      controller.seekTo(position);
    }
  }

  void _initializePlayer() {
    _generation++;
    _handlingError = false;
    _autorecovered = false;
    _startAttempt();
    _startPreload();
  }

  Future<void> _startAttempt() async {
    final gen = _generation;
    if (!mounted) return;
    // Applique la config « Night Focus » au processeur audio natif AVANT la
    // création d'un contrôleur, pour qu'elle soit active à la configuration
    // du pipeline audio (par défaut : by-pass quand le switch maître est OFF).
    final nf = ref.read(advancedSettingsProvider);
    await NightFocusAudioService.push(
      nf.nightFocusEnabled,
      dialogueBoostDb: nf.nightFocusDialogueBoost ? 4.0 : 0,
      bassKillerCutoffHz: nf.nightFocusBassKiller ? 120.0 : 0,
      vocalGainDb: nf.nightFocusDialogueBoost ? nf.nightFocusVocalGainDb : 0,
      audioDelayMs: nf.nightFocusAudioShiftMs,
    );
    if (!isLikelyStreamUrl(_activeStreamUrl)) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }
    // Flux préchauffé par la grille Live TV : zapping sans démarrage à froid.
    final prewarmed = StreamPrewarmService.instance.take(_activeStreamUrl);
    if (prewarmed != null) {
      _controller = prewarmed;
      prewarmed.addListener(_onControllerUpdate);
      prewarmed.play();
      if (!mounted || gen != _generation || _controller != prewarmed) {
        _disposeController(prewarmed);
        return;
      }
      _setStatus(_PlayerStatus.ready);
      _showInfoBrief();
      _recordHistory();
      return;
    }
    _setStatus(_PlayerStatus.loading);
    // Si le moteur principal du type de contenu est une application externe
    // (VLC / MX), on tente d'abord de diriger la lecture vers celle-ci.
    if (_engineConfig.primary.isExternal) {
      final external = await _launchExternal();
      if (external && mounted && gen == _generation) return;
      if (!mounted || gen != _generation) return;
      // Échec du lecteur externe : on retombe sur le moteur interne.
    }
    // Priorité : sur les serveurs hybrides, l'URL « style live » /u/p/{id}
    // (redirigée vers un CDN signé) fonctionne pour le VOD tandis que le
    // chemin /movie/{id} renvoie 401. On tente donc les variantes dans
    // l'ordre, en complétant par les User-Agents si toutes échouent.
    final variants = await _resolvedVariants();
    for (final attemptUrl in variants) {
      final found = await _tryPlay(gen, attemptUrl);
      if (found) return;
      if (!mounted || gen != _generation) return;
    }
    if (gen == _generation) {
      // Échec du moteur interne : si le moteur de secours est externe, on
      // bascule sur le fallback (ex. libVLC) avant de déclarer une erreur.
      if (_engineConfig.fallback.isExternal) {
        final external = await _launchFallbackExternal();
        if (external && mounted && gen == _generation) return;
        if (!mounted || gen != _generation) return;
      }
      _setStatus(_PlayerStatus.error);
    }
  }

  /// Tente de diriger la lecture vers le moteur de secours externe (fallback,
  /// ex. libVLC) en cas d'échec du moteur principal interne.
  Future<bool> _launchFallbackExternal() async {
    final engine = _engineConfig.fallback;
    if (!engine.isExternal) return false;
    try {
      final url = _activeStreamUrl;
      final uri =
          engine == PlayerEngine.vlc ? Uri.parse('vlc://$url') : Uri.parse(url);
      final ui = Uri.parse(url);
      final supported = await canLaunchUrl(uri) || await canLaunchUrl(ui);
      if (!supported) return false;
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication) ||
              await launchUrl(ui, mode: LaunchMode.externalApplication);
      if (launched && mounted) {
        _setStatus(_PlayerStatus.ready);
        _showInfoBrief();
      }
      return launched;
    } catch (_) {
      return false;
    }
  }

  /// Ordre des User-Agents à tenter à la lecture. Quand l'impersonation TLS
  /// est active (réglage avancé), on privilégie l'User-Agent navigateur
  /// (index 0) qui imite le trafic d'un navigateur moderne pour contourner
  /// Cloudflare ; sinon on tente d'abord l'Agent natif ExoPlayer.
  List<int> _userAgentOrder() {
    final tls = ref.read(advancedSettingsProvider).useTlsImpersonation;
    if (!tls) {
      return [
        for (var i = playbackUserAgents.length - 1; i >= 0; i--) i,
      ];
    }
    return [
      for (var i = 0; i < playbackUserAgents.length; i++) i,
    ];
  }

  /// Variantes d'URL candidates à tenter. Quand le proxy Rust est prêt et
  /// que le flux est un candidat (draap.online), chaque variante est rebasée
  /// via le relais local : l'entrée passe par `/proxy/hls` (manifest HLS/DASH)
  /// ou `/proxy/stream|segment` (média), puis le player suit les URLs
  /// réécrites `/hls/<hash>/…` renvoyées par le serveur. Comportement
  /// inchangé si le proxy n'est pas prêt ou si l'URL n'est pas relayable.
  Future<List<String>> _resolvedVariants() async {
    final manager = ref.read(rustProxyManagerProvider);
    // Démarrage best-effort (no-op si binaire absent / Android sans hook FFI),
    // borné par le ping : on attend une fenêtre courte AVANT de relayer.
    if (isRelayCandidate(_activeStreamUrl) && !manager.isReady) {
      await manager.ensureStarted();
    }
    var variants = streamUrlVariants(_activeStreamUrl);
    if (manager.isReady) {
      variants = variants
          .map((u) => maybeRebaseThroughProxy(u, proxyReady: true))
          .toList();
    }
    return variants;
  }

  /// Construit les en-têtes HTTP pour une URL de flux, en fusionnant les
  /// cookies Cloudflare (`cf_clearance`) déjà obtenus pour ce host, si
  /// présents. Ceux-ci sont utilisés par ExoPlayer pour ses propres requêtes.
  Map<String, String> _resolvedHeaders(String url, int agentIndex) {
    final base = streamHeaders(url, userAgentIndex: agentIndex);
    final host = Uri.tryParse(url)?.host;
    if (host != null) {
      final cf = CloudflareBypassService.instance.headersForHost(host);
      if (cf != null) base.addAll(cf);
    }
    return base;
  }

  /// Configuration de moteur du type de contenu couramment lu.
  PlayerPerTypeConfig get _engineConfig =>
      ref.read(advancedSettingsProvider).configFor(widget.contentType);

  /// Tente de diriger la lecture vers une application externe (VLC / MX).
  /// Renvoie `true` si le lancement a réussi (le player interne se met en
  /// pause et l'utilisateur poursuit dans l'app externe).
  Future<bool> _launchExternal() async {
    final engine = _engineConfig.primary;
    if (!engine.isExternal) return false;
    try {
      final url = _activeStreamUrl;
      // Pour VLC on préfère le schéma vlc:// ; sinon intent https générique.
      final uri =
          engine == PlayerEngine.vlc ? Uri.parse('vlc://$url') : Uri.parse(url);
      final ui = Uri.parse(url);
      final supported = await canLaunchUrl(uri) || await canLaunchUrl(ui);
      if (!supported) return false;
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication) ||
              await launchUrl(
                ui,
                mode: LaunchMode.externalApplication,
              );
      if (launched && mounted) {
        _setStatus(_PlayerStatus.ready);
        _showInfoBrief();
      }
      return launched;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryPlay(int gen, String url) async {
    final userAgentOrder = _userAgentOrder();
    for (final agentIndex in userAgentOrder) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: _resolvedHeaders(url, agentIndex),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      _controller = controller;
      controller.addListener(_onControllerUpdate);
      try {
        await controller.initialize().timeout(_probTimeout);
      } catch (e) {
        debugPrint('Orbit3D video error ($url): $e');
        if (_controller == controller) {
          _disposeController(controller);
          _controller = null;
        } else {
          _disposeController(controller);
        }
        continue;
      }
      if (!mounted || gen != _generation || _controller != controller) {
        _disposeController(controller);
        return true;
      }
      if (controller.value.hasError) {
        debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
        _disposeController(controller);
        _controller = null;
        continue;
      }
      controller.play();
      if (!mounted || gen != _generation || _controller != controller) {
        _disposeController(controller);
        return true;
      }
      _setStatus(_PlayerStatus.ready);
      _applyInitialPosition();
      _showInfoBrief();
      _recordHistory();
      return true;
    }
    return false;
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    _syncImmersive();
    if (_status != _PlayerStatus.ready) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    _handleActiveError();
  }

  void _handleActiveError() {
    if (!mounted || _handlingError) return;
    final gen = _generation;
    _handlingError = true;
    _disposeActive();
    if (!mounted || gen != _generation) {
      _handlingError = false;
      return;
    }
    if (!_autorecovered) {
      _autorecovered = true;
      _handlingError = false;
      _startAttempt();
      return;
    }
    _handlingError = false;
    _setStatus(_PlayerStatus.error);
  }

  void _goNext() {
    if (_hasNext) _switchTo(_index + 1);
  }

  void _goPrevious() {
    if (_hasPrevious) _switchTo(_index - 1);
  }

  void _switchTo(int target) {
    if (!mounted ||
        target == _index ||
        target < 0 ||
        target >= _channels.length) {
      return;
    }
    _generation++;
    _autorecovered = false;
    _handlingError = false;
    final forward = target > _index;
    final oldActive = _controller;
    final newActive = _takeCachedFor(target);
    if (forward) {
      _disposeCachedPrev();
    } else {
      _disposeCachedNext();
    }
    _index = target;
    _preloadTarget = null;
    _controller = newActive;
    if (oldActive != null) {
      oldActive.removeListener(_onControllerUpdate);
      if (oldActive.value.isInitialized && !oldActive.value.hasError) {
        oldActive.pause();
        if (forward) {
          _cachedPrev = oldActive;
          _cachedPrevIndex = target - 1;
        } else {
          _cachedNext = oldActive;
          _cachedNextIndex = target + 1;
        }
      } else {
        oldActive.dispose();
      }
    }
    if (newActive != null) {
      newActive.addListener(_onControllerUpdate);
      newActive.play();
      _setStatus(_PlayerStatus.ready);
      _showInfoBrief();
    } else {
      _startAttempt();
    }
    _startPreload();
  }

  VideoPlayerController? _takeCachedFor(int target) {
    VideoPlayerController? cached;
    if (_cachedNextIndex == target) {
      cached = _cachedNext;
      _cachedNext = null;
      _cachedNextIndex = null;
    } else if (_cachedPrevIndex == target) {
      cached = _cachedPrev;
      _cachedPrev = null;
      _cachedPrevIndex = null;
    }
    if (cached == null) return null;
    cached.removeListener(_onControllerUpdate);
    if (!cached.value.isInitialized || cached.value.hasError) {
      cached.dispose();
      return null;
    }
    return cached;
  }

  Future<void> _startPreload() async {
    final gen = _generation;
    if (!mounted || _channels.isEmpty) return;
    if (!ref.read(advancedSettingsProvider).zeroLagPrefetch) return;
    final target = _index + 1;
    if (target >= _channels.length) return;
    if (_cachedNext != null || _preloadTarget == target) return;
    final channelUrl = _channels[target].streamUrl;
    if (!isLikelyStreamUrl(channelUrl)) return;
    _preloadTarget = target;
    // Préchargement relais : on passe par le proxy local si celui-ci est prêt
    // et que la chaîne cible est un candidat au relais.
    final targetUrl = maybeRebaseThroughProxy(
      channelUrl,
      proxyReady: ref.read(rustProxyManagerProvider).isReady,
    );
    for (var attempt = 0; attempt < playbackUserAgents.length; attempt++) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(targetUrl),
        httpHeaders: _resolvedHeaders(targetUrl, attempt),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      try {
        await controller.initialize().timeout(_probTimeout);
      } catch (e) {
        debugPrint('Orbit3D preload error: $e');
        _disposeController(controller);
        continue;
      }
      if (!mounted || gen != _generation || _preloadTarget != target) {
        _disposeController(controller);
        if (_preloadTarget == target) _preloadTarget = null;
        return;
      }
      if (controller.value.hasError) {
        _disposeController(controller);
        continue;
      }
      if (!mounted || gen != _generation || _cachedNext != null) {
        _disposeController(controller);
        return;
      }
      controller.pause();
      _cachedNext = controller;
      _cachedNextIndex = target;
      _preloadTarget = null;
      return;
    }
    if (mounted && gen == _generation && _preloadTarget == target) {
      _preloadTarget = null;
    }
  }

  void _disposeController(VideoPlayerController controller) {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
  }

  void _disposeActive() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    _disposeController(controller);
  }

  void _disposeCachedNext() {
    final controller = _cachedNext;
    _cachedNext = null;
    _cachedNextIndex = null;
    if (controller == null) return;
    _disposeController(controller);
  }

  void _disposeCachedPrev() {
    final controller = _cachedPrev;
    _cachedPrev = null;
    _cachedPrevIndex = null;
    if (controller == null) return;
    _disposeController(controller);
  }

  void _setStatus(_PlayerStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
    _syncImmersive();
  }

  Future<void> _retry() async {
    _generation++;
    _handlingError = false;
    _autorecovered = false;
    _disposeCachedNext();
    _disposeCachedPrev();
    _startAttempt();
    _startPreload();
  }

  /// `true` si on peut proposer le déblocage Cloudflare pour le flux courant.
  bool get _canCloudflare {
    final host = Uri.tryParse(_activeStreamUrl)?.host;
    if (host == null || host.isEmpty) return false;
    return !CloudflareBypassService.instance.hasCookieFor(host);
  }

  /// Ouvre un WebView de déblocage Cloudflare (cf_clearance), puis relance la
  /// lecture.
  Future<void> _unlockCloudflare() async {
    if (!mounted) return;
    final host = Uri.tryParse(_activeStreamUrl)?.host;
    if (host == null || host.isEmpty) return;
    _setStatus(_PlayerStatus.loading);
    final headers =
        await CloudflareBypassService.instance.obtainHeaders(context, host);
    if (!mounted) return;
    if (headers == null || headers.isEmpty) {
      _setStatus(_PlayerStatus.error);
      return;
    }
    _retry();
  }

  void _showInfoBrief() {
    _infoTimer?.cancel();
    if (!mounted) return;
    setState(() => _showInfo = true);
    _infoTimer = Timer(_infoBarDuration, () {
      if (mounted) setState(() => _showInfo = false);
    });
  }

  void _recordHistory() {
    final channel = _currentChannel;
    if (channel == null) return;
    try {
      ref
          .read(historyServiceProvider)
          .addEntry('channel', channel.name, channel.streamUrl);
    } catch (_) {}
  }

  void _toggleInfo() {
    _infoTimer?.cancel();
    setState(() => _showInfo = !_showInfo);
  }

  void _openAudioControls() {
    showAudioControlsSheet(context);
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
    _syncImmersive();
  }

  void _toggleVolumeZap() {
    setState(() => _volumeToZap = !_volumeToZap);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.pageUp) {
      _goPrevious();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown) {
      _goNext();
      return KeyEventResult.handled;
    }
    if (_volumeToZap) {
      if (key == LogicalKeyboardKey.audioVolumeUp) {
        _goNext();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.audioVolumeDown) {
        _goPrevious();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _toggleInfo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _currentChannel?.name ?? widget.title ?? 'Lecture';
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _restoreSystemUi();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (_status) {
              _PlayerStatus.loading => const VideoLoadingState(),
              _PlayerStatus.error => VideoErrorState(
                  onRetry: _retry,
                  onCloudflare: _canCloudflare ? _unlockCloudflare : null,
                  cloudflareMessage: _canCloudflare
                      ? 'Le flux est protégé par un challenge Cloudflare. '
                          'Débloque-le puis réessaie.'
                      : null,
                ),
              _PlayerStatus.ready => Stack(
                  fit: StackFit.expand,
                  children: [
                    Focus(
                      autofocus: true,
                      child: KeyboardListener(
                        focusNode: _focusNode,
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.select ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.numpadEnter)) {
                            _showStatusBarTemporarily();
                          }
                        },
                        child: _ReadyPlayer(
                          controller: _controller!,
                          onTap: () {
                            _toggleInfo();
                            _showStatusBarTemporarily();
                          },
                        ),
                      ),
                    ),
                    if (_showInfo && _currentChannel != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: _InfoBar(
                            channel: _currentChannel!,
                            onClose: _toggleInfo,
                            onAudioControls: _openAudioControls,
                          ),
                        ),
                      ),
                  ],
                ),
            },
          ),
        ),
      ),
      bottomNavigationBar: _canZap
          ? _ZapBar(
              index: _index,
              total: _channels.length,
              volumeToZap: _volumeToZap,
              onPrevious: _hasPrevious ? _goPrevious : null,
              onNext: _hasNext ? _goNext : null,
              onToggleVolumeZap: _toggleVolumeZap,
            )
          : null,
      floatingActionButton: _status == _PlayerStatus.ready
          ? FloatingActionButton.large(
              onPressed: _togglePlayPause,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(_controller!.value.isPlaying),
                ),
              ),
            )
          : null,
    );
  }
}

class _ZapBar extends StatelessWidget {
  const _ZapBar({
    required this.index,
    required this.total,
    required this.volumeToZap,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleVolumeZap,
  });

  final int index;
  final int total;
  final bool volumeToZap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToggleVolumeZap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Chaîne précédente',
              onPressed: onPrevious,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${index + 1} / $total',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    volumeToZap
                        ? 'Zapping rapide · volume = chaîne'
                        : 'Zapping rapide',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: volumeToZap
                  ? 'Volume normal'
                  : 'Changer de chaîne avec le volume',
              onPressed: onToggleVolumeZap,
              icon: Icon(
                volumeToZap ? Icons.tap_and_play : Icons.volume_up,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Chaîne suivante',
              onPressed: onNext,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBar extends ConsumerWidget {
  const _InfoBar({
    required this.channel,
    this.onClose,
    this.onAudioControls,
  });

  final Channel channel;
  final VoidCallback? onClose;
  final VoidCallback? onAudioControls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final epgAsync = ref.watch(channelEpgProvider(channel.epgChannelId));
    final (nowProgram, nextProgram) = _nowAndNext(epgAsync.value ?? const []);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.72),
                Colors.black.withValues(alpha: 0.28),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (epgAsync.isLoading && nowProgram == null)
                      Text(
                        'Programme en cours de chargement…',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      )
                    else
                      _EpgRow(now: nowProgram, next: nextProgram),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Réglages audio & sync',
                onPressed: onAudioControls,
                icon: const Icon(
                  Icons.nightlight_round,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Masquer les infos',
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpgRow extends StatelessWidget {
  const _EpgRow({required this.now, required this.next});

  final EPGProgram? now;
  final EPGProgram? next;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = now;
    if (current == null) {
      return const Row(
        children: [
          Icon(Icons.tv_off_rounded, size: 14, color: Colors.white54),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Programme non disponible',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq_rounded, size: 14, color: scheme.tertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${_fmt(current.start)} - ${_fmt(current.end)}   ${current.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (next != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Colors.white54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Suivant : ${_fmt(next!.start)}   ${next!.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

(EPGProgram?, EPGProgram?) _nowAndNext(List<EPGProgram> programs) {
  final now = DateTime.now();
  EPGProgram? current;
  EPGProgram? next;
  for (final program in programs) {
    if (!program.start.isAfter(now) && program.end.isAfter(now)) {
      current = program;
      break;
    }
  }
  if (current != null) {
    final index = programs.indexOf(current);
    if (index + 1 < programs.length && programs[index + 1].start.isAfter(now)) {
      next = programs[index + 1];
    }
  } else if (programs.isNotEmpty) {
    next = programs.firstWhere(
      (p) => p.start.isAfter(now),
      orElse: () => programs.last,
    );
  }
  return (current, next);
}

String _fmt(DateTime time) => DateFormat('HH:mm').format(time);

class _ReadyPlayer extends ConsumerStatefulWidget {
  const _ReadyPlayer({required this.controller, required this.onTap});

  final VideoPlayerController controller;
  final VoidCallback onTap;

  @override
  ConsumerState<_ReadyPlayer> createState() => _ReadyPlayerState();
}

class _ReadyPlayerState extends ConsumerState<_ReadyPlayer> {
  bool _showBuffering = false;
  bool _showHardwareControls = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlayerStateChanged);
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChanged);
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final isBuffering = widget.controller.value.isBuffering;
    if (isBuffering != _showBuffering) {
      setState(() => _showBuffering = isBuffering);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showHardwareControls) {
        setState(() => _showHardwareControls = false);
      }
    });
  }

  void _showControls() {
    if (!_showHardwareControls) {
      setState(() => _showHardwareControls = true);
    }
    _startHideControlsTimer();
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    _showControls();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showControls(),
      onDoubleTap: _togglePlayPause,
      onLongPress: () =>
          setState(() => _showHardwareControls = !_showHardwareControls),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
              // Buffering indicator
              if (_showBuffering)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              // Hardware controls overlay
              if (_showHardwareControls)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Progress bar
                      VideoProgressIndicator(widget.controller,
                          allowScrubbing: true),
                      // Control buttons
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => widget.controller.seekTo(
                                  widget.controller.value.position -
                                      const Duration(seconds: 10),
                                ),
                                icon: const Icon(Icons.replay_10,
                                    color: Colors.white),
                                tooltip: 'Reculer 10s',
                              ),
                              IconButton.filledTonal(
                                onPressed: () {
                                  if (widget.controller.value.isPlaying) {
                                    widget.controller.pause();
                                  } else {
                                    widget.controller.play();
                                  }
                                },
                                icon: Icon(
                                  widget.controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                tooltip: widget.controller.value.isPlaying
                                    ? 'Pause'
                                    : 'Lecture',
                              ),
                              IconButton.filledTonal(
                                onPressed: () => widget.controller.seekTo(
                                  widget.controller.value.position +
                                      const Duration(seconds: 30),
                                ),
                                icon: const Icon(Icons.forward_30,
                                    color: Colors.white),
                                tooltip: 'Avancer 30s',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
