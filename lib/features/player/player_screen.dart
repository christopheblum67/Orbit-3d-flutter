import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_monitoring_overlay.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/stream_prewarm_service.dart';
import 'package:orbit_3d_flutter/services/cloudflare_bypass_service.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';

class PlayerRouteData {
  const PlayerRouteData({
    required this.streamUrl,
    this.title,
    this.channels = const [],
    this.index = 0,
    this.progressId,
    this.initialPositionMs,
    this.contentType = PlaybackContentType.live,
    this.favorite,
    this.posterUrl,
    this.subtitle,
    this.rating,
    this.genre,
    this.year = 0,
    this.seriesName,
    this.episodeLabel,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int index;
  final String? progressId;
  final int? initialPositionMs;
  final PlaybackContentType contentType;

  /// Favori associé au contenu lancé (utilisé pour la lecture non live).
  /// En live, le favori est déduit de la chaîne courante.
  final FavoriteEntry? favorite;

  final String? posterUrl;
  final String? subtitle;
  final double? rating;
  final String? genre;
  final int year;
  final String? seriesName;
  final String? episodeLabel;
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
    this.favorite,
    this.posterUrl,
    this.subtitle,
    this.rating,
    this.genre,
    this.year = 0,
    this.seriesName,
    this.episodeLabel,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int initialIndex;
  final String? progressId;
  final int? initialPositionMs;
  final PlaybackContentType contentType;
  final FavoriteEntry? favorite;
  final String? posterUrl;
  final String? subtitle;
  final double? rating;
  final String? genre;
  final int year;
  final String? seriesName;
  final String? episodeLabel;

  @override
  ConsumerState<PlayerScreen> createState() => PlayerScreenState();
}

enum _PlayerStatus { loading, error, ready }

/// Durée maximale accordée à initialise() avant de basculer sur le
/// prochain User-Agent : évite de bloquer le zapping sur un flux muet.
const _probTimeout = Duration(seconds: 12);

/// Durée d'affichage de la footerbar avant masquage automatique.
const _footerBarDuration = Duration(seconds: 5);

class PlayerScreenState extends ConsumerState<PlayerScreen>
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
  String? _lastErrorDescription;
  int _generation = 0;
  bool _footerVisible = false;
  Timer? _footerTimer;
  Timer? _saveProgressTimer;
  bool _volumeToZap = false;
  bool _immersive = false;
  bool _hasAppliedInitialPosition = false;
  bool? _lastKnownPlaying;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerScreen');

  // Monitoring réseau & stall
  Timer? _monitoringTimer;
  StallDetector? _stallDetector;

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

  /// Favori associé au contenu en cours (déduit de la chaîne en live,
  /// sinon fourni par la route).
  FavoriteEntry? get _favoriteEntry {
    final channel = _currentChannel;
    if (channel != null) {
      return FavoriteEntry(
        type: ContentType.live,
        id: channel.id,
        title: channel.name,
        posterUrl: channel.logoUrl,
        subtitle: channel.groupLabel,
        streamUrl: channel.streamUrl,
      );
    }
    return widget.favorite;
  }

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
    _footerTimer?.cancel();
    _saveProgressTimer?.cancel();
    _monitoringTimer?.cancel();
    _stallDetector?.stop();
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
  /// quand la vidéo joue. Ne fait RIEN si la footerbar est visible (tap/OK) —
  /// son timer d'auto-masquage la fera disparaître (~5s) puis on reviendra ici.
  void _syncImmersive() {
    final playing = _status == _PlayerStatus.ready &&
        _controller != null &&
        _controller!.value.isPlaying;
    if (playing && !_immersive && !_footerVisible) {
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

  /// Affiche la footerbar (et les barres système) pendant [duration] puis la
  /// masque automatiquement. Appelé sur tap écran, touche OK ou zapping.
  void _showFooterBar({Duration duration = _footerBarDuration}) {
    _footerTimer?.cancel();
    final firstShow = !_footerVisible;
    _footerVisible = true;
    if (mounted && firstShow) setState(() {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _footerTimer = Timer(duration, () {
      if (!mounted) return;
      _footerVisible = false;
      _footerTimer = null;
      setState(() {});
      _syncImmersive(); // repasse en immersive si lecture en cours
    });
  }

  /// Masque immédiatement la footerbar (interaction utilisateur explicite).
  void _hideFooterBar() {
    _footerTimer?.cancel();
    _footerTimer = null;
    if (!_footerVisible) return;
    _footerVisible = false;
    if (mounted) setState(() {});
    _syncImmersive();
  }

  /// Bascule visible/caché de la footerbar (touche Échap de la télécommande).
  void _toggleFooter() {
    if (_footerVisible) {
      _hideFooterBar();
    } else {
      _showFooterBar();
    }
  }

  /// Restaure la system UI par défaut de l'application (sortie player, pause).
  void _restoreSystemUi() {
    _footerTimer?.cancel();
    _footerTimer = null;
    _footerVisible = false;
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
  /// est prêt. La durée peut être encore inconnue (0) au moment du seek :
  /// on n'empêche alors pas la reprise (ExoPlayer sait se positionner).
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
    if (duration.inMilliseconds <= 0 || position < duration) {
      controller.seekTo(position);
    }
  }

  void _initializePlayer() {
    _generation++;
    _handlingError = false;
    _autorecovered = false;
    _lastErrorDescription = null;
    _startAttempt();
    _startPreload();
  }

  Future<void> _startAttempt() async {
    final gen = _generation;
    if (!mounted) return;

    // Vérification connectivité au démarrage : si hors-ligne, afficher erreur directe
    final connectivity = ref.read(connectivityMonitorProvider);
    if (!connectivity.isOnline) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }

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
    // Applique la configuration de lecture par profil (tampon media3 + limite
    // de résolution) AVANT la création du contrôleur ExoPlayer.
    await PlayerProfileService.push(
      Media3PlaybackProfile.forProfile(ref.read(deviceProfileProvider)),
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

  /// Construit les en-têtes HTTP pour une URL de flux, en fusionnant :
  /// 1. Les headers de base (User-Agent rotation, etc.)
  /// 2. Les cookies Cloudflare globaux (session unique pour tout le fournisseur)
  /// 3. Les cookies Cloudflare spécifiques à l'hôte (CloudflareBypassService)
  Map<String, String> _resolvedHeaders(String url, int agentIndex) {
    final base = streamHeaders(url, userAgentIndex: agentIndex);

    // 1. Session Cloudflare globale (init au démarrage, unique pour tout le fournisseur)
    final globalCf = ref.read(cloudflareSessionProvider);
    if (globalCf.isReady) {
      base.addAll(globalCf.videoHeaders);
    }

    // 2. Cookies Cloudflare spécifiques à l'hôte (obtention à la demande via WebView)
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
    final circuitBreaker = ref.read(hostCircuitBreakerProvider);
    final host = Uri.tryParse(url)?.host ?? '';

    // Vérifier le circuit breaker avant de tenter
    if (host.isNotEmpty && circuitBreaker.isInCooldown(host)) {
      final remaining = circuitBreaker.remainingCooldown(host);
      debugPrint(
          'HostCircuitBreaker: $host in cooldown, ${remaining.inSeconds}s remaining');
      if (gen == _generation) {
        _setStatus(_PlayerStatus.error);
      }
      return false;
    }

    final userAgentOrder = _userAgentOrder();
    for (final agentIndex in userAgentOrder) {
      // Laisse un intervalle entre deux essais : marteler le panneau IPTV
      // déclenche son anti-leech (401 « indisponible » temporaire).
      if (agentIndex != userAgentOrder.first) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted || gen != _generation) return false;
      }
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
        if (host.isNotEmpty) {
          circuitBreaker.recordFailure(host);
        }
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
        if (host.isNotEmpty) {
          circuitBreaker.recordFailure(host);
        }
        _disposeController(controller);
        _controller = null;
        continue;
      }
      controller.play();
      if (!mounted || gen != _generation || _controller != controller) {
        _disposeController(controller);
        return true;
      }
      // Succès : reset le circuit breaker pour cet hôte
      if (host.isNotEmpty) {
        circuitBreaker.recordSuccess(host);
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
    // Nouvelle tentative tant que la position initiale n'a pas été appliquée
    // (la durée peut n'attendre qu'après le chargement des métadonnées).
    if (!_hasAppliedInitialPosition && widget.initialPositionMs != null) {
      _applyInitialPosition();
    }
    final playing = _controller?.value.isPlaying;
    if (playing != null && playing != _lastKnownPlaying) {
      _lastKnownPlaying = playing;
      setState(() {});
    }
    if (_status != _PlayerStatus.ready) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    _lastErrorDescription = controller.value.errorDescription;
    _handleActiveError();
  }

  /// Détecte une coupure d'anti-leech fournisseur (ExoPlayer: HTTP 401 /
  /// Source error), distincte d'une simple chaîne indisponible.
  static bool isProviderBlock(String? description) {
    if (description == null || description.isEmpty) return false;
    return description.contains('401') || description.contains('Source error');
  }

  /// Détecte si une erreur est liée à Cloudflare (challenge, 403, cookie expiré, etc.)
  bool _isCloudflareError(String? description) {
    if (description == null || description.isEmpty) return false;
    final msg = description.toLowerCase();
    return msg.contains('403') ||
        msg.contains('cloudflare') ||
        msg.contains('challenge') ||
        msg.contains('cf_clearance') ||
        msg.contains('blocked') ||
        msg.contains('access denied') ||
        msg.contains('forbidden');
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

    final errorDesc = _lastErrorDescription;
    final host = Uri.tryParse(_activeStreamUrl)?.host ?? '';
    final isProviderBlockError = isProviderBlock(errorDesc);

    // Enregistre l'échec dans le circuit breaker si c'est un blocage fournisseur
    if (isProviderBlockError && host.isNotEmpty) {
      ref.read(hostCircuitBreakerProvider).recordFailure(host);
    }

    if (!_autorecovered) {
      // Première tentative de récupération : si c'est une erreur Cloudflare,
      // on renouvelle la session avant de retenter.
      if (_isCloudflareError(errorDesc)) {
        debugPrint('☁️ Cloudflare error detected, renewing session...');
        ref.read(cloudflareSessionProvider).renewSession();
        _autorecovered = true;
        _handlingError = false;
        _startAttempt();
        return;
      }
      _autorecovered = true;
      _handlingError = false;
      _startAttempt();
      return;
    }
    _handlingError = false;
    _setStatus(_PlayerStatus.error);
  }

  void _goNext() {
    if (!_hasNext) return;
    _showFooterBar();
    _switchTo(_index + 1);
  }

  void _goPrevious() {
    if (!_hasPrevious) return;
    _showFooterBar();
    _switchTo(_index - 1);
  }

  /// Déplace la lecture de [delta] (boutons retour 10s / avance 30s).
  void _seekBy(Duration delta) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    var position = controller.value.position + delta;
    if (position < Duration.zero) position = Duration.zero;
    final duration = controller.value.duration;
    if (duration > Duration.zero && position > duration) {
      position = duration;
    }
    controller.seekTo(position);
    _showFooterBar();
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
    final wasReady = _status == _PlayerStatus.ready;
    setState(() => _status = status);
    _syncImmersive();

    // Démarre/arrête la détection de stall selon le statut
    if (status == _PlayerStatus.ready && !wasReady) {
      _startStallDetection();
    } else if (wasReady && status != _PlayerStatus.ready) {
      _stopStallDetection();
    }
  }

  void _startStallDetection() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      _stallDetector = ref.read(stallDetectorProvider);
      _stallDetector!.start(controller);
    }
  }

  void _stopStallDetection() {
    _stallDetector?.stop();
    _stallDetector = null;
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
    if (!mounted) return;
    _showFooterBar();
  }

  void _recordHistory() {
    try {
      final channel = _currentChannel;
      if (channel != null) {
        // Live : identité = chaîne courante (suit le zapping).
        ref.read(recentlyWatchedProvider.notifier).record(
              ContentType.live,
              channel.id,
              channel.name,
              posterUrl: channel.logoUrl,
              subtitle: channel.groupLabel,
              streamUrl: channel.streamUrl,
            );
        return;
      }
      final favorite = widget.favorite;
      if (favorite != null) {
        ref.read(recentlyWatchedProvider.notifier).record(
              favorite.type,
              favorite.id,
              favorite.title,
              posterUrl: favorite.posterUrl,
              subtitle: favorite.subtitle,
              streamUrl: favorite.streamUrl.isEmpty
                  ? widget.streamUrl
                  : favorite.streamUrl,
            );
      }
    } catch (_) {}
  }

  void _openAudioControls() {
    showAudioControlsSheet(context);
  }

  void _openPlayerEngineConfig() {
    showPlayerEngineConfigSheet(context);
  }

  void _openSettings() {
    if (!mounted) return;
    context.go('/settings');
  }

  /// Bascule directe du maître Night Focus (icône 🌙 de la footerbar).
  Future<void> _toggleNightFocus() async {
    final nf = ref.read(advancedSettingsProvider);
    final next = !nf.nightFocusEnabled;
    await ref.read(advancedSettingsProvider.notifier).setNightFocus(next);
    await NightFocusAudioService.push(
      next,
      dialogueBoostDb: nf.nightFocusDialogueBoost ? 4.0 : 0,
      bassKillerCutoffHz: nf.nightFocusBassKiller ? 120.0 : 0,
      vocalGainDb: nf.nightFocusDialogueBoost ? nf.nightFocusVocalGainDb : 0,
      audioDelayMs: nf.nightFocusAudioShiftMs,
    );
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    final playing = controller.value.isPlaying;
    debugPrint(
        'Orbit3D toggle: isPlaying=$playing pos=${controller.value.position}');
    setState(() {
      playing ? controller.pause() : controller.play();
    });
    _syncImmersive();
    _showFooterBar();
  }

  void _toggleVolumeZap() {
    setState(() => _volumeToZap = !_volumeToZap);
  }

  /// Sortie propre du lecteur : arrêt immédiat du flux (audio + vidéo),
  /// libération des contrôleurs, puis retour go_router.
  void _requestExit() {
    _cleanup();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// Nettoyage complet sans navigation (pour back handling système/geste).
  /// Appelé par WithBackHandling.custom() depuis la route.
  void cleanup() {
    _cleanup();
  }

  void _cleanup() {
    _generation++;
    _restoreSystemUi();
    _footerTimer?.cancel();
    _saveProgressTimer?.cancel();
    _saveProgress();
    _disposeActive();
    _disposeCachedNext();
    _disposeCachedPrev();
    _preloadTarget = null;
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
      _toggleFooter();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
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
                  title: isProviderBlock(_lastErrorDescription)
                      ? 'Flux verrouillé par le fournisseur'
                      : 'Flux indisponible',
                  message: isProviderBlock(_lastErrorDescription)
                      ? 'La lecture a été coupée par la protection anti-leech '
                          'du serveur. Patientez 3 à 5 minutes sans lecture, '
                          'puis relancez cette chaîne (sans zapper).'
                      : 'Impossible de lancer cette chaîne. '
                          'Vérifie ton abonnement ou réessaie.',
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
                      onKeyEvent: (_, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.numpadEnter)) {
                          _showFooterBar();
                        }
                        return KeyEventResult.ignored;
                      },
                      child: _ReadyPlayer(
                        controller: player!,
                        onTap: _showFooterBar,
                        streamUrl: _activeStreamUrl,
                        onRetry: _retry,
                      ),
                    ),
                    if (_footerVisible)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _ContentFooterBar(
                          child: _buildFooterContent(player),
                        ),
                      ),
                  ],
                ),
            },
          ),
        ),
      ),
    );
  }

  /// Construit le contenu de la footerbar selon le type de contenu en cours.
  Widget _buildFooterContent(VideoPlayerController player) {
    final isPlaying = player.value.isPlaying;
    final controlsMenu = _FooterControlsMenu(
      onOpened: () => _footerTimer?.cancel(),
      onClosed: _showFooterBar,
      onAudioControls: _openAudioControls,
      onPlayerEngine: _openPlayerEngineConfig,
      onToggleNightFocus: _toggleNightFocus,
      onSettings: _openSettings,
    );
    return switch (widget.contentType) {
      PlaybackContentType.live => _LiveFooterBar(
          channel: _currentChannel,
          fallbackTitle: widget.title ?? _currentChannel?.name ?? 'Live',
          index: _index,
          total: _channels.length,
          volumeToZap: _volumeToZap,
          isPlaying: isPlaying,
          showSeek: false,
          favoriteEntry: _favoriteEntry,
          onExit: _requestExit,
          onPrevious: _hasPrevious ? _goPrevious : null,
          onNext: _hasNext ? _goNext : null,
          onTogglePlayPause: _togglePlayPause,
          onSeekBack10: null,
          onSeekBack30: null,
          onSeekForward10: null,
          onSeekForward30: null,
          onToggleVolumeZap: _toggleVolumeZap,
          controlsMenu: controlsMenu,
          onToggleNightFocus: _toggleNightFocus,
        ),
      PlaybackContentType.replay => _LiveFooterBar(
          channel: _currentChannel,
          fallbackTitle: widget.title ?? 'Replay',
          subtitle: widget.subtitle,
          controller: player,
          index: _index,
          total: _channels.length,
          volumeToZap: _volumeToZap,
          isPlaying: isPlaying,
          showSeek: true,
          favoriteEntry: _favoriteEntry,
          onExit: _requestExit,
          onPrevious: _hasPrevious ? _goPrevious : null,
          onNext: _hasNext ? _goNext : null,
          onTogglePlayPause: _togglePlayPause,
          onSeekBack10: () => _seekBy(const Duration(seconds: -10)),
          onSeekBack30: () => _seekBy(const Duration(seconds: -30)),
          onSeekForward10: () => _seekBy(const Duration(seconds: 10)),
          onSeekForward30: () => _seekBy(const Duration(seconds: 30)),
          onToggleVolumeZap: _toggleVolumeZap,
          controlsMenu: controlsMenu,
          onToggleNightFocus: _toggleNightFocus,
        ),
      PlaybackContentType.vod || PlaybackContentType.series => _VodFooterBar(
          controller: player,
          title: widget.title ?? widget.seriesName ?? 'Lecture',
          rating: widget.rating,
          genre: widget.genre,
          subtitle: widget.subtitle,
          seriesName: widget.seriesName,
          episodeLabel: widget.episodeLabel,
          isPlaying: isPlaying,
          favoriteEntry: _favoriteEntry,
          onExit: _requestExit,
          onTogglePlayPause: _togglePlayPause,
          onSeekBack10: () => _seekBy(const Duration(seconds: -10)),
          onSeekBack30: () => _seekBy(const Duration(seconds: -30)),
          onSeekForward10: () => _seekBy(const Duration(seconds: 10)),
          onSeekForward30: () => _seekBy(const Duration(seconds: 30)),
          controlsMenu: controlsMenu,
          onToggleNightFocus: _toggleNightFocus,
        ),
    };
  }
}

/// Conteneur commun de la footerbar unifiée : barre basse translucide
/// arrondie, ancrée en bas (SafeArea), que l'on place en overlay du lecteur.
class _ContentFooterBar extends StatelessWidget {
  const _ContentFooterBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Icône compacte de la footerbar (blanche sur fond translucide).
Widget _fbIcon(
  IconData icon,
  VoidCallback? onPressed, {
  String? tooltip,
  Color color = Colors.white,
  double size = 22,
}) {
  return IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    onPressed: onPressed,
    icon: Icon(icon, color: color, size: size),
  );
}

/// Bouton pause/lecture proéminent de la footerbar.
Widget _fbPlayPause({
  required bool isPlaying,
  required VoidCallback onPressed,
}) {
  return IconButton(
    tooltip: isPlaying ? 'Pause' : 'Lecture',
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.22),
    ),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(minWidth: 46, minHeight: 44),
    onPressed: onPressed,
    icon: Icon(
      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      color: Colors.white,
      size: 28,
    ),
  );
}

/// Icône Night Focus de la footerbar : l'icône et la couleur changent selon
/// l'état ON/OFF du maître (toggle direct, sans ouvrir de sous-menu).
Widget _fbNightFocus({
  required VoidCallback onPressed,
  required WidgetRef ref,
}) {
  final enabled = ref.watch(
    advancedSettingsProvider.select((s) => s.nightFocusEnabled),
  );
  return IconButton(
    tooltip: enabled ? 'Night Focus (activé)' : 'Night Focus (désactivé)',
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    onPressed: onPressed,
    icon: Icon(
      enabled ? Icons.nightlight_round : Icons.nightlight_outlined,
      color: enabled ? const Color(0xFFFFC107) : Colors.white70,
      size: 22,
    ),
  );
}

/// Petit badge numéro de chaîne / étiquette genre (#num ou chip métadonnée).
class _ChannelBadge extends StatelessWidget {
  const _ChannelBadge({
    required this.label,
    this.color = const Color(0xFF4FC3F7),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Barre de progression du programme EPG en cours : (now - start)/(end - start).
class _LiveProgressBar extends StatelessWidget {
  const _LiveProgressBar({required this.program});

  final EPGProgram program;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalMs = program.end.difference(program.start).inMilliseconds;
    var ratio = 0.0;
    if (totalMs > 0) {
      ratio = now.difference(program.start).inMilliseconds / totalMs;
    }
    ratio = ratio.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
      ),
    );
  }
}

/// Rangée de contrôles de seek : 2x retour rapide / play-pause / 2x avance rapide.
/// Vitesses : -10s / -30s  |  play/pause  |  +10s / +30s
class _SeekActionsRow extends StatelessWidget {
  const _SeekActionsRow({
    required this.isPlaying,
    required this.onSeekBack10,
    required this.onSeekBack30,
    required this.onSeekForward10,
    required this.onSeekForward30,
    required this.onTogglePlayPause,
  });

  final bool isPlaying;
  final VoidCallback onSeekBack10;
  final VoidCallback onSeekBack30;
  final VoidCallback onSeekForward10;
  final VoidCallback onSeekForward30;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _fbIcon(Icons.replay_30, onSeekBack30, tooltip: 'Reculer 30s'),
        const SizedBox(width: 6),
        _fbIcon(Icons.replay_10, onSeekBack10, tooltip: 'Reculer 10s'),
        const SizedBox(width: 10),
        _fbPlayPause(isPlaying: isPlaying, onPressed: onTogglePlayPause),
        const SizedBox(width: 10),
        _fbIcon(Icons.forward_10, onSeekForward10, tooltip: 'Avancer 10s'),
        const SizedBox(width: 6),
        _fbIcon(Icons.forward_30, onSeekForward30, tooltip: 'Avancer 30s'),
      ],
    );
  }
}

/// Footerbar Live / Replay : nom de chaîne + #numéro + EPG (titre/horaires
/// + progression du programme) puis actions (zapping, pause/play, seek si
/// replay, volume-zap, menu, Night Focus, favori, retour) puis hints TV.
class _LiveFooterBar extends ConsumerWidget {
  const _LiveFooterBar({
    required this.channel,
    required this.fallbackTitle,
    this.subtitle,
    this.controller,
    required this.index,
    required this.total,
    required this.volumeToZap,
    required this.isPlaying,
    required this.showSeek,
    this.favoriteEntry,
    required this.onExit,
    this.onPrevious,
    this.onNext,
    required this.onTogglePlayPause,
    this.onSeekBack10,
    this.onSeekBack30,
    this.onSeekForward10,
    this.onSeekForward30,
    required this.onToggleVolumeZap,
    required this.controlsMenu,
    required this.onToggleNightFocus,
  });

  final Channel? channel;
  final String fallbackTitle;
  final String? subtitle;
  final VideoPlayerController? controller;
  final int index;
  final int total;
  final bool volumeToZap;
  final bool isPlaying;
  final bool showSeek;
  final FavoriteEntry? favoriteEntry;
  final VoidCallback onExit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onTogglePlayPause;
  final VoidCallback? onSeekBack10;
  final VoidCallback? onSeekBack30;
  final VoidCallback? onSeekForward10;
  final VoidCallback? onSeekForward30;
  final VoidCallback onToggleVolumeZap;
  final _FooterControlsMenu controlsMenu;
  final VoidCallback onToggleNightFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final currentChannel = channel;
    final epgAsync = currentChannel != null
        ? ref.watch(channelEpgProvider(currentChannel.epgChannelId))
        : null;
    final (nowProgram, nextProgram) = currentChannel != null && epgAsync != null
        ? _nowAndNext(epgAsync.value ?? const [])
        : (null, null);
    final channelName = currentChannel?.name ?? fallbackTitle;
    final canZap = total > 1;
    final hints = <String>[
      if (canZap) '▲▼ chaîne',
      if (volumeToZap) 'volume = chaîne',
      'OK pause',
      if (showSeek) '← → 10/30s',
      '← Retour',
    ].join(' · ');
    final player = controller;
    final hasEpg =
        currentChannel != null && (nowProgram != null || nextProgram != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (currentChannel != null)
              _ChannelBadge(
                label:
                    '#${currentChannel.orderNum > 0 ? currentChannel.orderNum : index + 1}',
              ),
            if (currentChannel != null) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canZap)
              Text(
                '${index + 1} / $total',
                style: const TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
          ],
        ),
        if (hasEpg) ...[
          const SizedBox(height: 8),
          _EpgRow(now: nowProgram, next: nextProgram),
          if (nowProgram != null) ...[
            const SizedBox(height: 8),
            _LiveProgressBar(program: nowProgram),
          ],
        ] else if (currentChannel != null &&
            epgAsync != null &&
            epgAsync.isLoading) ...[
          const SizedBox(height: 8),
          const Text(
            'Programme en cours de chargement…',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ] else if (showSeek && player != null) ...[
          const SizedBox(height: 8),
          VideoProgressIndicator(
            player,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          _SeekActionsRow(
            isPlaying: isPlaying,
            onSeekBack10: onSeekBack10!,
            onSeekBack30: onSeekBack30!,
            onSeekForward10: onSeekForward10!,
            onSeekForward30: onSeekForward30!,
            onTogglePlayPause: onTogglePlayPause,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            _fbIcon(Icons.arrow_back_rounded, onExit, tooltip: 'Retour'),
            if (favoriteEntry != null)
              FavoriteToggle.overlay(entry: favoriteEntry!),
            const Spacer(),
            if (canZap) ...[
              _fbIcon(
                volumeToZap ? Icons.tap_and_play : Icons.volume_up,
                onToggleVolumeZap,
                tooltip: volumeToZap
                    ? 'Volume normal'
                    : 'Changer de chaîne avec le volume',
                color: volumeToZap ? scheme.primary : Colors.white,
              ),
            ],
            if (onPrevious != null)
              _fbIcon(
                Icons.skip_previous_rounded,
                onPrevious,
                tooltip: 'Chaîne précédente',
              ),
            if (showSeek) ...[
              _fbIcon(
                Icons.replay_30,
                onSeekBack30,
                tooltip: 'Reculer 30s',
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              _fbIcon(
                Icons.replay_10,
                onSeekBack10,
                tooltip: 'Reculer 10s',
                color: Colors.white,
              ),
            ],
            _fbPlayPause(isPlaying: isPlaying, onPressed: onTogglePlayPause),
            if (showSeek) ...[
              _fbIcon(
                Icons.forward_10,
                onSeekForward10,
                tooltip: 'Avancer 10s',
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              _fbIcon(
                Icons.forward_30,
                onSeekForward30,
                tooltip: 'Avancer 30s',
                color: Colors.white,
              ),
            ],
            if (onNext != null)
              _fbIcon(
                Icons.skip_next_rounded,
                onNext,
                tooltip: 'Chaîne suivante',
              ),
            const SizedBox(width: 4),
            _fbNightFocus(onPressed: onToggleNightFocus, ref: ref),
            controlsMenu,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hints,
          style: const TextStyle(color: Colors.white60, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// Footerbar VOD / Séries : titre + note ★ + genre (+ épisode) puis barre de
/// progression de lecture + 2x retour / play-pause / 2x avance, puis menu /
/// Night Focus et hints TV.
class _VodFooterBar extends ConsumerWidget {
  const _VodFooterBar({
    required this.controller,
    required this.title,
    this.rating,
    this.genre,
    this.subtitle,
    this.seriesName,
    this.episodeLabel,
    required this.isPlaying,
    this.favoriteEntry,
    required this.onExit,
    required this.onTogglePlayPause,
    required this.onSeekBack10,
    required this.onSeekBack30,
    required this.onSeekForward10,
    required this.onSeekForward30,
    required this.controlsMenu,
    required this.onToggleNightFocus,
  });

  final VideoPlayerController controller;
  final String title;
  final double? rating;
  final String? genre;
  final String? subtitle;
  final String? seriesName;
  final String? episodeLabel;
  final bool isPlaying;
  final FavoriteEntry? favoriteEntry;
  final VoidCallback onExit;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSeekBack10;
  final VoidCallback onSeekBack30;
  final VoidCallback onSeekForward10;
  final VoidCallback onSeekForward30;
  final _FooterControlsMenu controlsMenu;
  final VoidCallback onToggleNightFocus;

  String? get _subLine {
    if (seriesName != null && episodeLabel != null) {
      return '$seriesName · $episodeLabel';
    }
    return episodeLabel ??
        (subtitle != null && subtitle!.isNotEmpty ? subtitle : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final showRating = rating != null && rating! > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_subLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showRating) ...[
              const Icon(Icons.star_rounded,
                  size: 16, color: Color(0xFFFFC107)),
              const SizedBox(width: 4),
              Text(
                rating!.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (genre != null && genre!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _ChannelBadge(label: genre!, color: scheme.tertiary),
            ],
          ],
        ),
        const SizedBox(height: 10),
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Colors.white,
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white24,
          ),
        ),
        const SizedBox(height: 8),
        _SeekActionsRow(
          isPlaying: isPlaying,
          onSeekBack10: onSeekBack10,
          onSeekBack30: onSeekBack30,
          onSeekForward10: onSeekForward10,
          onSeekForward30: onSeekForward30,
          onTogglePlayPause: onTogglePlayPause,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _fbIcon(Icons.arrow_back_rounded, onExit, tooltip: 'Retour'),
            if (favoriteEntry != null)
              FavoriteToggle.overlay(entry: favoriteEntry!),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'OK pause · ← → 10/30s · ← Retour',
                style: TextStyle(color: Colors.white60, fontSize: 10.5),
              ),
            ),
            _fbNightFocus(onPressed: onToggleNightFocus, ref: ref),
            controlsMenu,
          ],
        ),
      ],
    );
  }
}

enum _FooterMenuAction { audioSync, nightFocus, playerEngine, settings }

/// Ligne d'une entrée du menu contextuel (icône + libellé).
class _FbMenuItem extends StatelessWidget {
  const _FbMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

/// Menu contextuel de la footerbar (icône ⚙️) : Réglages audio & sync,
/// Night Focus (toggle), Qualité & lecteur, Réglages.
///
/// Tant que le popup est ouvert on gèle le timer d'auto-masquage (via
/// [onOpened]) et on le relance à la fermeture ([onClosed]).
class _FooterControlsMenu extends ConsumerWidget {
  const _FooterControlsMenu({
    required this.onOpened,
    required this.onClosed,
    required this.onAudioControls,
    required this.onPlayerEngine,
    required this.onToggleNightFocus,
    required this.onSettings,
  });

  final VoidCallback onOpened;
  final VoidCallback onClosed;
  final VoidCallback onAudioControls;
  final VoidCallback onPlayerEngine;
  final VoidCallback onToggleNightFocus;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nfEnabled = ref.watch(
      advancedSettingsProvider.select((s) => s.nightFocusEnabled),
    );
    return PopupMenuButton<_FooterMenuAction>(
      tooltip: 'Menu',
      icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
      onOpened: onOpened,
      onCanceled: onClosed,
      onSelected: (action) {
        onClosed();
        switch (action) {
          case _FooterMenuAction.audioSync:
            onAudioControls();
          case _FooterMenuAction.nightFocus:
            onToggleNightFocus();
          case _FooterMenuAction.playerEngine:
            onPlayerEngine();
          case _FooterMenuAction.settings:
            onSettings();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _FooterMenuAction.audioSync,
          child: _FbMenuItem(
            icon: Icons.tune_rounded,
            label: 'Réglages audio & sync',
          ),
        ),
        CheckedPopupMenuItem(
          value: _FooterMenuAction.nightFocus,
          checked: nfEnabled,
          child: const _FbMenuItem(
            icon: Icons.nightlight_round,
            label: 'Night Focus',
          ),
        ),
        const PopupMenuItem(
          value: _FooterMenuAction.playerEngine,
          child: _FbMenuItem(
            icon: Icons.hd_rounded,
            label: 'Qualité & lecteur',
          ),
        ),
        const PopupMenuItem(
          value: _FooterMenuAction.settings,
          child: _FbMenuItem(
            icon: Icons.settings_outlined,
            label: 'Réglages',
          ),
        ),
      ],
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
  const _ReadyPlayer({
    required this.controller,
    required this.onTap,
    required this.streamUrl,
    required this.onRetry,
  });

  final VideoPlayerController controller;
  final VoidCallback onTap;
  final String streamUrl;
  final VoidCallback onRetry;

  @override
  ConsumerState<_ReadyPlayer> createState() => _ReadyPlayerState();
}

class _ReadyPlayerState extends ConsumerState<_ReadyPlayer> {
  bool _showBuffering = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final isBuffering = widget.controller.value.isBuffering;
    if (isBuffering != _showBuffering) {
      setState(() => _showBuffering = isBuffering);
    }
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _togglePlayPause,
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
              // Monitoring overlay (réseau, stall, cooldown)
              PlayerMonitoringOverlay(
                streamUrl: widget.streamUrl,
                onRetry: widget.onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
