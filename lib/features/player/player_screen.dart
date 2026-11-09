import 'dart:async';
import 'package:orbit_3d_flutter/core/services/playback_refresh_gate.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/services/video_decoder_prefs.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart' show tvModeNotifierProvider;
import 'package:orbit_3d_flutter/features/player/widgets/delayed_playback_loading.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_footer_bars.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_footer_content.dart';
import 'package:orbit_3d_flutter/features/player/widgets/ready_player.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_error_view.dart';
import 'package:orbit_3d_flutter/features/player/widgets/provider_verification_dialog.dart';
import 'package:orbit_3d_flutter/features/player/widgets/stream_details_sheet.dart';
import 'package:orbit_3d_flutter/features/player/player_route_data.dart';
import 'package:orbit_3d_flutter/features/player/adjacent_player_cache.dart';
import 'package:orbit_3d_flutter/features/player/player_key_policy.dart';
import 'package:orbit_3d_flutter/features/player/playback_checkpoint.dart';
import 'package:orbit_3d_flutter/features/player/playback_error_policy.dart';
import 'package:orbit_3d_flutter/features/player/external_playback.dart';
import 'package:orbit_3d_flutter/features/player/playback_history_writer.dart';
import 'package:orbit_3d_flutter/features/player/preload_candidate.dart';
import 'package:orbit_3d_flutter/features/player/player_preloader.dart';
import 'package:orbit_3d_flutter/features/player/playback_progress_writer.dart';
import 'package:orbit_3d_flutter/features/player/playback_rate_limit.dart';
import 'package:orbit_3d_flutter/features/player/saved_audio_track.dart';
import 'package:orbit_3d_flutter/features/player/subtitle_preferences.dart';
import 'package:orbit_3d_flutter/features/player/embedded_subtitle_scanner.dart';
import 'package:orbit_3d_flutter/features/player/decoder_recovery.dart';
import 'package:orbit_3d_flutter/features/player/next_episode.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/stream_prewarm_service.dart';
import 'package:orbit_3d_flutter/services/player_crash_guard.dart';
import 'package:orbit_3d_flutter/services/pip_service.dart';
import 'package:orbit_3d_flutter/services/background_playback_service.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';
import 'package:orbit_3d_flutter/services/local_video_proxy.dart';
import 'package:orbit_3d_flutter/services/video_cache_manager.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_subtitle_overlay.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

export 'player_route_data.dart';

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
    this.series,
    this.episode,
    this.vodId,
    this.consecutiveEpisodes = 1,
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
  final Series? series;
  final Episode? episode;

  /// Identifiant VOD du film (`stream_id`), utilisé pour découvrir les
  /// sous-titres publiés par le panel. `null` pour un flux live ou une série.
  final String? vodId;
  final int consecutiveEpisodes;

  @override
  ConsumerState<PlayerScreen> createState() => PlayerScreenState();
}

enum _PlayerStatus { loading, error, ready }

/// Durée maximale accordée à initialise() avant de basculer sur le
/// prochain User-Agent : évite de bloquer le zapping sur un flux muet.
///
/// Doit rester > somme des back-offs natifs de LoggingDataSource
/// (3 s + 8 s + 20 s = 31 s) : sinon le timeout Dart détruit le contrôleur
/// pendant que le retry natif travaille encore, et le flux est perdu alors
/// que la requête suivante aurait abouti.
const _probTimeout = Duration(seconds: 45);

/// Durée d'affichage de la footerbar avant masquage automatique.
const _footerBarDuration = Duration(seconds: 5);

/// Nombre de variantes d'URL tolérées après un refus anti-leech avant
/// d'abandonner la tentative courante.
const int _maxRateLimitedVariants = 2;

/// Options communes à tous les lecteurs de l'écran.
///
/// `mixWithOthers: false` est la correction du doublage audio au zapping.
///
/// Le plugin natif traduit ce booléen en
/// `exoPlayer.setAudioAttributes(attrs, handleAudioFocus: !isMixMode)`
/// (`third_party/video_player_android/.../VideoPlayer.java:260`). Avec
/// `true`, `handleAudioFocus` vaut `false` : ExoPlayer ne demande **ni**
/// n'abandonne le focus audio. Conséquence mesurée sur le S20 : le
/// `dumpsys audio` ne montrait qu'une entrée `orbit.app`, et surtout aucun
/// `abandonAudioFocus` entre deux zappings — rien n'extinguait donc le lecteur
/// précédent. Comme `_switchTo` met l'ancien contrôleur en cache au lieu de
/// le libérer, et que le réservoir de préchauffage peut conserver un lecteur
/// en cours d'initialisation, deux ExoPlayer de la même chaîne coexistent et
/// leur audio se superpose.
///
/// En passant à `false`, chaque nouveau lecteur prend le focus et fait taire
/// le précédent au niveau du système, même si un contrôleur survit en cache.
/// Les caches des lecteurs adjacents redeviennent sûrs.
final VideoPlayerOptions _exclusivePlayback = VideoPlayerOptions(
  mixWithOthers: false,
  allowBackgroundPlayback: false,
);

class PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  List<Channel> _channels = const [];
  late int _index;
  VideoPlayerController? _controller;
  LocalVideoProxy? _localVideoProxy;
  final _proxySessions = <VideoPlayerController, LocalVideoProxySession>{};
  late final _adjacentPlayers = AdjacentPlayerCache<VideoPlayerController>(
    disposePlayer: (player) => unawaited(_disposeController(player)),
  );

  final PlaybackRateLimit _rateLimit = PlaybackRateLimit();

  /// Piste audio préférée ré-appliquée après l'initialisation du contrôleur.
  bool _appliedAudioPref = false;

  final SubtitlePreferences _subtitlePreferences = SubtitlePreferences();

  final EmbeddedSubtitleScanner<VideoPlayerController> _embeddedScanner =
      EmbeddedSubtitleScanner(
    fetchTracks: (player) =>
        EmbeddedSubtitleBridge(embeddedPlayerId(player)).getTracks(),
  );
  final _preloader = PlayerPreloader<VideoPlayerController>();
  // Un zapping ultérieur doit aussi attendre la pause encore en cours.
  Future<void>? _pendingZapPause;
  _PlayerStatus _status = _PlayerStatus.loading;
  bool _handlingError = false;
  bool _externalPlaybackLaunched = false;
  late final PlaybackProgressWriter _progressWriter;
  late final SubtitleController _subtitleController;
  late final WatchedEpisodesNotifier _watchedEpisodes;
  int _autoRecoveryAttempts = 0;
  bool _retrying = false;
  bool _decoderInitializationError = false;
  int? _decoderModeOverride;
  DateTime? _lastRetryTime;
  String? _lastErrorDescription;
  int _generation = 0;
  bool _footerVisible = false;
  Timer? _footerTimer;
  Timer? _nextEpisodeTimer;
  Episode? _nextEpisode;
  int _nextEpisodeSeconds = 15;
  bool _completionHandled = false;
  Timer? _saveProgressTimer;
  bool _immersive = false;
  late final PlaybackCheckpoint _checkpoint;
  bool _resumePlaying = true;
  bool? _lastKnownPlaying;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerScreen');
  final FocusNode _nextEpisodeFocus = FocusNode(debugLabel: 'NextEpisode');
  final FocusScopeNode _footerScope = FocusScopeNode(debugLabel: 'PlayerFooter');
  final FocusScopeNode _playerErrorScope = FocusScopeNode(debugLabel: 'PlayerErrors');

  // Picture-in-Picture & lecture en arrière-plan
  final _pipService = PipService();
  final _bgService = BackgroundPlaybackService();
  bool? _pipSupported;
  late final PlaybackRefreshLease _refreshLease;

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

  /// Titre affiché dans la notification de lecture en arrière-plan.
  String get _playbackTitle => widget.title ?? _currentChannel?.name ?? 'Orbit';

  /// Sous-titre de la notification de lecture en arrière-plan.
  String get _playbackSubtitle {
    if (widget.contentType == PlaybackContentType.live) {
      return 'Lecture live en cours';
    }
    return widget.seriesName ?? widget.episodeLabel ?? 'Lecture en cours';
  }

  @override
  void initState() {
    super.initState();
    _refreshLease = PlaybackRefreshGate.instance.acquire();
    _progressWriter =
        PlaybackProgressWriter(ref.read(playbackProgressServiceProvider));
    _subtitleController = ref.read(subtitleControllerProvider);
    _watchedEpisodes = ref.read(watchedEpisodesProvider.notifier);
    _checkpoint = PlaybackCheckpoint(widget.initialPositionMs);
    WidgetsBinding.instance.addObserver(this);
    // Contexte de découverte des sous-titres pour le contenu lu. Renseigné
    // ici (et non au moment de l'appui sur l'icône) pour que la feuille puisse
    // interroger le panel dès son ouverture.
    //
    // `id` n'est renseigné qu'au tout premier cadre : le provider n'est lu
    // qu'à l'ouverture de la feuille, bien après.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final seriesId = widget.series?.id;
      final contentId = seriesId ?? widget.vodId;
      // On écrase TOUJOURS le contexte, y compris par `null`.
      //
      // Sans cela le contexte d'une lecture précédente survivait : lire un
      // film puis ouvrir un flux live (aucun identifiant) faisait interroger
      // le panel pour le film précédent, et la feuille affichait les
      // sous-titres du mauvais contenu. Le retour à `null` est donc la valeur
      // par défaut, pas une casquette.
      if (contentId == null || contentId.isEmpty) {
        ref.read(activeSubtitleContextProvider.notifier).set(null);
        return;
      }
      ref.read(activeSubtitleContextProvider.notifier).set(
            SubtitleContext(
              contentId: contentId,
              isSeries: seriesId != null,
              // Pour un épisode, la découverte a besoin du stream id brut de
              // l'épisode : `series_id` ne permet pas de synthétiser l'URL d'une
              // piste, et l'écran finissait par n'en proposer aucune.
              streamId:
                  seriesId != null ? (widget.episode?.streamId ?? '') : '',
              // Titre et saison/épisode servent à la recherche EN LIGNE : sans
              // identifiant TMDB, OpenSubtitles ne peut pas être interrogé.
              title: widget.episode?.title ?? _playbackTitle,
              season: widget.episode?.season ?? 0,
              episode: widget.episode?.episodeNumber ?? 0,
            ),
          );
    });
    _channels = widget.channels;
    _index = widget.initialIndex;
    if (_channels.isNotEmpty) {
      if (_index < 0) _index = 0;
      if (_index >= _channels.length) _index = _channels.length - 1;
    }
    // Nouvelle lecture (nouvelle PlayerScreen) : le contrôleur de sous-titres
    // est partagé par toute l'app — sans ce reset, la piste externe choisie
    // sur le contenu précédent restait active et son texte s'affichait sur
    // le nouveau contenu.
    ref.read(subtitleControllerProvider).resetForNewContent();
    _initializePlayer();
    _startSaveProgressTimer();
    unawaited(PlayerCrashGuard.begin());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supported = await _pipService.isSupported;
      if (mounted) {
        setState(() {
          _pipSupported = supported;
        });
      }
    });
  }

  @override
  void dispose() {
    _embeddedScanner.stop();
    _refreshLease.release();
    WidgetsBinding.instance.removeObserver(this);
    _restoreSystemUi();
    _footerTimer?.cancel();
    _nextEpisodeTimer?.cancel();
    _saveProgressTimer?.cancel();
    _monitoringTimer?.cancel();
    _stallDetector?.stop();
    _bgService.stop();
    _saveProgress(
      preserveOnError: _handlingError ||
          _status == _PlayerStatus.error ||
          (_autoRecoveryAttempts > 0 && _status != _PlayerStatus.ready),
    );
    _focusNode.dispose();
    _nextEpisodeFocus.dispose();
    _footerScope.dispose();
    _playerErrorScope.dispose();
    final disposal = _disposeActive();
    final localProxy = _localVideoProxy;
    if (localProxy != null) {
      unawaited(disposal.whenComplete(localProxy.close));
    }
    _adjacentPlayers.clear();
    _preloader.cancel();
    unawaited(PlayerCrashGuard.end());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncImmersive();
      _bgService.stop();
    } else {
      if (_nextEpisodeTimer?.isActive == true) {
        _nextEpisodeTimer?.cancel();
        if (mounted) setState(() {});
      }
      _restoreSystemUi();
      // Lecture active + app non au premier plan (PiP, home, écran éteint) :
      // le foreground service mediaPlayback garde le process vivant (Android 14+).
      if (_controller?.value.isPlaying == true &&
          _status == _PlayerStatus.ready) {
        _bgService.start(title: _playbackTitle, subtitle: _playbackSubtitle);
      }
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
  void _showFooterBar({
    Duration duration = _footerBarDuration,
    bool focusControls = true,
  }) {
    _footerTimer?.cancel();
    final firstShow = !_footerVisible;
    _footerVisible = true;
    if (mounted && firstShow) {
      setState(() {});
    }
    if (mounted && focusControls && !_footerScope.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_footerVisible || _footerScope.hasFocus ||
            _status != _PlayerStatus.ready || _playerErrorScope.hasFocus) return;
        final targets = _footerScope.traversalDescendants
            .where((n) => n.canRequestFocus && !n.skipTraversal);
        if (targets.isNotEmpty) targets.first.requestFocus();
      });
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _footerTimer = Timer(duration, () {
      if (!mounted) return;
      _footerVisible = false;
      _footerTimer = null;
      setState(() {});
      if (_status == _PlayerStatus.ready && !_playerErrorScope.hasFocus) {
        _focusNode.requestFocus();
      }
      _syncImmersive(); // repasse en immersive si lecture en cours
    });
  }

  /// Masque immédiatement la footerbar (interaction utilisateur explicite).
  void _hideFooterBar() {
    _footerTimer?.cancel();
    _footerTimer = null;
    if (!_footerVisible) return;
    _footerVisible = false;
    _focusNode.requestFocus();
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
  void _saveProgress({bool preserveOnError = false}) {
    final id = widget.progressId;
    if (id == null) return;
    final controller = _controller;
    if (widget.contentType == PlaybackContentType.live) return;
    if (controller != null) _checkpoint.observe(controller.value);
    if (!_checkpoint.hasPosition) return;
    final position = _checkpoint.position;
    final duration = _checkpoint.duration;
    final positionMs = position.inMilliseconds;
    final durationMs = duration.inMilliseconds;

    final series = widget.series;
    final episode = widget.episode;
    _progressWriter.save(
      id: id,
      positionMs: positionMs,
      durationMs: durationMs,
      preserveOnError: preserveOnError,
      markWatched: series != null && episode != null
          ? () => _watchedEpisodes.record(series, episode)
          : null,
    );
  }

  void _initializePlayer() {
    _generation++;
    _handlingError = false;
    _autoRecoveryAttempts = 0;
    _externalPlaybackLaunched = false;
    _lastErrorDescription = null;
    _startAttempt();
    _startPreload();
  }

  /// Attend que le moniteur de connectivite confirme le reseau, sans bloquer
  /// plus de [budget]. Evite de condamner la lecture sur un etat `none` encore
  /// en cours de resolution au demarrage de l'ecran.
  Future<void> _waitForOnline(Duration budget) async {
    final connectivity = ref.read(connectivityMonitorProvider);
    final deadline = DateTime.now().add(budget);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      if (connectivity.isOnline) {
        debugPrint('📶 Network confirmed after ${budget.inSeconds}s budget.');
        return;
      }
    }
  }

  Future<void> _startAttempt() async {
    final gen = _generation;
    if (!mounted) return;

    // Refroidissement après un 401 anti-leech : on laisse l'endpoint avant de
    // repartir, sinon on accumulate les refus et le blocage s'allonge.
    await _rateLimit.wait();
    if (!mounted || gen != _generation) return;

    // Connectivite au demarrage. ConnectivityMonitor demarre a
    // ConnectivityResult.none et resout son etat initial de facon asynchrone :
    // un refus immediat affichait "flux indisponible" alors que le reseau
    // revenait quelques dizaines de millisecondes plus tard, sans qu'aucune
    // reprise ne soit declenchee. On patiente donc brievement avant d'echouer.
    final connectivity = ref.read(connectivityMonitorProvider);
    if (!connectivity.isOnline) {
      debugPrint('📶 Network not confirmed yet, waiting before failing...');
      await _waitForOnline(const Duration(seconds: 6));
    }
    if (!mounted || gen != _generation) return;
    if (!connectivity.isOnline) {
      debugPrint('📶 Still offline after grace period.');
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
      volumeNormalization: nf.nightFocusVolumeNormalization,
    );
    // Applique la configuration de lecture par profil (tampon media3 + limite
    // de résolution) AVANT la création du contrôleur ExoPlayer.
    await PlayerProfileService.push(
      Media3PlaybackProfile.forProfile(
        ref.read(deviceProfileProvider),
        live: widget.contentType == PlaybackContentType.live,
      ),
      decoderModeOverride: _decoderModeOverride,
    );
    if (!mounted || gen != _generation) return;
    if (!isLikelyStreamUrl(_activeStreamUrl)) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }
    // Flux préchauffé par la grille Live TV : zapping sans démarrage à froid.
    final prewarmed = widget.contentType == PlaybackContentType.live &&
            _autoRecoveryAttempts == 0
        ? StreamPrewarmService.instance.take(_activeStreamUrl)
        : null;
    if (prewarmed != null) {
      // Force l'arrêt de l'ancien contrôleur AVANT d'assigner le nouveau
      // pour éviter le chevauchement audio (doublage).
      if (_controller != null && _controller!.value.isPlaying) {
        await _controller!.pause();
      }
      _disposeActive();
      _controller = prewarmed;
      prewarmed.addListener(_onControllerUpdate);
      _appliedAudioPref = false;
      // Configurer l'audio AVANT de jouer
      await _applySavedAudioTrack(prewarmed);
      prewarmed.play();
      if (!mounted || gen != _generation || _controller != prewarmed) {
        _disposeController(prewarmed);
        return;
      }
      _setStatus(_PlayerStatus.ready);
      _showInfoBrief();
      unawaited(_recordHistory());
      return;
    }
    _setStatus(_PlayerStatus.loading);
    // Si le moteur principal du type de contenu est une application externe
    // (VLC / MX), on tente d'abord de diriger la lecture vers celle-ci.
    if (_engineConfig.primary.isExternal) {
      final external = await _launchExternal();
      if (!mounted || gen != _generation) return;
      if (external) {
        _showExternalPlaybackState();
        return;
      }
      // Échec du lecteur externe : on retombe sur le moteur interne.
    }
    // Priorité : sur les serveurs hybrides, l'URL « style live » /u/p/{id}
    // (redirigée vers un CDN signé) fonctionne pour le VOD tandis que le
    // chemin /movie/{id} renvoie 401. On tente donc les variantes dans
    // l'ordre, en complétant par les User-Agents si toutes échouent.
    final variants = await _resolvedVariants();
    _decoderInitializationError = false;
    var rateLimitedAttempts = 0;
    for (final attemptUrl in variants) {
      final found = await _tryPlay(gen, attemptUrl);
      if (found) return;
      if (!mounted || gen != _generation) return;
      if (_decoderInitializationError) {
        await _handleActiveError();
        return;
      }
      if (_rateLimit.lastAttemptLimited) {
        rateLimitedAttempts++;
        // Un refus isolé reste toléré : sur les serveurs hybrides, le chemin
        // /movie/{id} renvoie 401 alors que /u/p/{id} fonctionne, et l'ordre
        // des variantes n'est pas garanti. Au-delà de
        // [_maxRateLimitedVariants] refus, le blocage est celui du serveur :
        // continuer n'y achetera qu'un refus de plus, chaque variante
        // repayant au passage toute la séquence de backoff native.
        if (rateLimitedAttempts >= _maxRateLimitedVariants) break;
      }
    }
    if (gen == _generation) {
      // Échec du moteur interne : si le moteur de secours est externe, on
      // bascule sur le fallback (ex. libVLC) avant de déclarer une erreur.
      if (_engineConfig.fallback.isExternal) {
        final external = await _launchFallbackExternal();
        if (!mounted || gen != _generation) return;
        if (external) {
          _showExternalPlaybackState();
          return;
        }
      }
      _setStatus(_PlayerStatus.error);
    }
  }

  /// Tente de diriger la lecture vers le moteur de secours externe (fallback,
  /// ex. libVLC) en cas d'échec du moteur principal interne.
  Future<bool> _launchFallbackExternal() async {
    final engine = _engineConfig.fallback;
    return _launchConfiguredExternal(engine);
  }

  Future<void> _openProviderWebsite() async {
    final uri = providerVerificationUri(
      ref.read(activeSubscriptionProvider)?.baseUrl,
    );
    if (uri == null) {
      _showProviderWebsiteError();
      return;
    }

    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => Dialog.fullscreen(
        child: ProviderVerificationDialog(
          uri: uri,
          title: l.openProviderWebsite,
          instructions: l.cloudflareChallengeHelp,
          closeLabel: l.close,
        ),
      ),
    );
  }

  void _showProviderWebsiteError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).providerWebsiteUnavailable),
      ),
    );
  }

  /// Ordre des User-Agents à tenter à la lecture. Quand l'impersonation TLS
  /// est active (réglage avancé), on privilégie l'User-Agent navigateur
  /// (index 0) ; sinon on tente d'abord l'Agent natif ExoPlayer.
  List<int> _userAgentOrder() {
    return playbackUserAgentOrder(
      tlsImpersonation: ref.read(advancedSettingsProvider).useTlsImpersonation,
    );
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

  /// Construit les en-têtes HTTP standards du lecteur pour une URL de flux.
  Map<String, String> _resolvedHeaders(String url, int agentIndex) {
    // Get panel URL from active subscription for Xtream Referer
    final activeSub = ref.read(activeSubscriptionProvider);
    final panelUrl = activeSub?.baseUrl;

    final base =
        streamHeaders(url, userAgentIndex: agentIndex, panelUrl: panelUrl);

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
    return _launchConfiguredExternal(engine);
  }

  Future<bool> _launchConfiguredExternal(PlayerEngine engine) async {
    return launchExternalPlayback(
      engine: engine,
      url: _activeStreamUrl,
    );
  }

  void _showExternalPlaybackState() {
    _externalPlaybackLaunched = true;
    _setStatus(_PlayerStatus.error);
  }

  Future<bool> _tryPlay(int gen, String url) async {
    // Chaque tentative repart d'un état de refus neutre : le drapeau est
    // réarmé par le limiteur si, et seulement si, ce nouvel essai
    // est lui aussi refusé.
    _rateLimit.startAttempt();
    final circuitBreaker = ref.read(hostCircuitBreakerProvider);
    final host = Uri.tryParse(url)?.host ?? '';

    // Vérifier le circuit breaker avant de tenter
    if (host.isNotEmpty && circuitBreaker.isInCooldown(host)) {
      final remaining = circuitBreaker.remainingCooldown(host);
      debugPrint(
        'HostCircuitBreaker: $host in cooldown, ${remaining.inSeconds}s remaining',
      );
      if (gen == _generation) {
        _setStatus(_PlayerStatus.error);
      }
      return false;
    }

    final userAgentOrder = _userAgentOrder();
    // La config media3 est lue à la CONSTRUCTION de l'ExoPlayer : ce `push`
    // garantit que la relance applique bien le profil de l'appareil, même
    // appelée depuis un chemin qui n'a pas déjà poussé (_startAttempt, prewarm).
    // Sans effet si le profil est inchangé (dedup dans PlayerProfileService).
    await PlayerProfileService.pushForDevice(
      ref.read(deviceProfileProvider),
      decoderModeOverride: _decoderModeOverride,
      live: widget.contentType == PlaybackContentType.live,
    );
    if (!mounted || gen != _generation) return false;
    for (final agentIndex in userAgentOrder) {
      // Laisse un intervalle entre deux essais : marteler le panneau IPTV
      // déclenche son anti-leech (401 « indisponible » temporaire).
      if (agentIndex != userAgentOrder.first) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted || gen != _generation) return false;
      }
      final headers = _resolvedHeaders(url, agentIndex);
      var playbackUri = Uri.parse(url);
      LocalVideoProxySession? proxySession;
      final useProxy = ref.read(advancedSettingsProvider).localVideoProxy &&
          (widget.contentType == PlaybackContentType.vod ||
              widget.contentType == PlaybackContentType.series) &&
          !(playbackUri.host == kRustProxyHost &&
              playbackUri.port == kRustProxyPort) &&
          !playbackUri.path.toLowerCase().endsWith('.mpd');
      if (useProxy) {
        try {
          if (_localVideoProxy == null) {
            try {
              final cache = await VideoCacheManager.instance;
              if (!mounted || gen != _generation) return false;
              _localVideoProxy = LocalVideoProxy(
                cache: cache,
                onError: () => debugPrint('Erreur du relais vidéo local'),
              );
            } catch (_) {
              debugPrint('Cache vidéo indisponible : relais sans cache');
              if (!mounted || gen != _generation) return false;
              _localVideoProxy = LocalVideoProxy(
                onError: () => debugPrint('Erreur du relais vidéo local'),
              );
            }
          }
          final proxy = _localVideoProxy!;
          await proxy.start();
          if (!mounted || gen != _generation) return false;
          proxySession = proxy.openSession(playbackUri, headers: headers);
          playbackUri = proxySession.url;
        } catch (_) {
          debugPrint('Impossible de démarrer le relais vidéo local');
          if (mounted && gen == _generation) {
            _lastErrorDescription = 'Local video proxy unavailable';
          }
          return false;
        }
      }
      final controller = VideoPlayerController.networkUrl(
        playbackUri,
        httpHeaders: proxySession == null ? headers : const {},
        videoPlayerOptions: _exclusivePlayback,
      );
      if (proxySession != null) _proxySessions[controller] = proxySession;
      if (widget.contentType != PlaybackContentType.live) {
        _checkpoint.restoring = true;
      }
      _controller = controller;
      controller.addListener(_onControllerUpdate);
      _appliedAudioPref = false;
      final initResult = await safeAsync(
        () => controller.initialize().timeout(_probTimeout),
        context: '_tryPlay controller.initialize',
      );
      if (!mounted || gen != _generation || _controller != controller) {
        return true;
      }
      if (initResult.isFailure) {
        final description = controller.value.errorDescription ??
            initResult.errorOrNull?.message;
        if (isPlaybackDecoderError(description)) {
          _lastErrorDescription = description;
          _decoderInitializationError = true;
          _controller = null;
          await _disposeController(controller);
          return false;
        }
        if (host.isNotEmpty && !isPlaybackDecoderError(initResult.errorOrNull)) {
          circuitBreaker.recordFailure(host);
        }
        if (_controller == controller) {
          _disposeController(controller);
          _controller = null;
        } else {
          _disposeController(controller);
        }
        // 401/403 = refus anti-leech, pas un mauvais User-Agent : tourner les
        // agents quadruplerait le volume de requêtes et aggraverait le refus.
        if (PlaybackRateLimit.isRateLimited(initResult.errorOrNull)) {
          _rateLimit.register();
          return false;
        }
        continue;
      }
      if (!mounted || gen != _generation || _controller != controller) {
        _disposeController(controller);
        return true;
      }
      if (controller.value.hasError) {
        debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
        if (isPlaybackDecoderError(controller.value.errorDescription)) {
          _lastErrorDescription = controller.value.errorDescription;
          _decoderInitializationError = true;
          _controller = null;
          await _disposeController(controller);
          return false;
        }
        if (host.isNotEmpty &&
            !isPlaybackDecoderError(controller.value.errorDescription)) {
          circuitBreaker.recordFailure(host);
        }
        _disposeController(controller);
        _controller = null;
        continue;
      }
      if (widget.contentType != PlaybackContentType.live) {
        final position = _checkpoint.position;
        if (position > Duration.zero) {
          final duration = controller.value.duration;
          if (duration > Duration.zero && position >= duration) {
            _lastErrorDescription = 'Saved position exceeds media duration';
            _disposeController(controller);
            _controller = null;
            return false;
          }
          final result = await safeAsync(
            () => controller.seekTo(position),
            context: 'PlayerScreen.restoreCheckpoint',
          );
          if (!mounted || gen != _generation || _controller != controller) {
            return true;
          }
          if (result.isFailure || controller.value.hasError) {
            _lastErrorDescription = 'Could not restore playback position';
            _disposeController(controller);
            _controller = null;
            return false;
          }
        }
        _checkpoint.restoring = false;
      }
      if (_resumePlaying || widget.contentType == PlaybackContentType.live) {
        final played = await safeAsync(
          () => controller.play(),
          context: 'PlayerScreen.playAfterRestore',
        );
        if (!mounted || gen != _generation || _controller != controller) {
          return true;
        }
        if (played.isFailure || controller.value.hasError) {
          _lastErrorDescription = controller.value.errorDescription ??
              played.errorOrNull?.message;
          _decoderInitializationError = isPlaybackDecoderError(_lastErrorDescription);
          _controller = null;
          await _disposeController(controller);
          return false;
        }
      }
      if (!mounted || gen != _generation || _controller != controller) {
        _disposeController(controller);
        return true;
      }
      // Succès : reset le circuit breaker pour cet hôte
      if (host.isNotEmpty) {
        circuitBreaker.recordSuccess(host);
      }
      _rateLimit.resetAfterSuccess();
      _setStatus(_PlayerStatus.ready);
      _showInfoBrief();
      unawaited(_recordHistory());
      return true;
    }
    return false;
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    _syncImmersive();
    // Ré-applique la piste audio mémorisée une fois le flux initialisé (ne
    // bloque pas la lecture : la sélection est best-effort).
    final active = _controller;
    if (active != null && active.value.isInitialized && !_appliedAudioPref) {
      _appliedAudioPref = true;
      _applySavedAudioTrack(active);
      // Découverte des sous-titres intégrés : la liste des pistes texte arrive
      // par vagues, donc on la rejoue (voir [_startEmbeddedScan]).
      _startEmbeddedScan(active);
    }
    if (active != null && _status == _PlayerStatus.ready &&
        widget.contentType != PlaybackContentType.live) {
      _checkpoint.observe(active.value);
      if (active.value.isInitialized && !active.value.hasError) {
        _resumePlaying = active.value.isPlaying;
      }
    }
    final playing = _controller?.value.isPlaying;
    if (playing != null && playing != _lastKnownPlaying) {
      _lastKnownPlaying = playing;
      if (playing) {
        // Prechauffage de la chaine suivante declenche ici, et non au lancement :
        // c'est le premier instant ou la lecture courante est reellement etablie.
        unawaited(_startPreload());
      }
      setState(() {});
    }
    if (_status != _PlayerStatus.ready) return;
    final controller = _controller;
    if (controller != null && !controller.value.isCompleted && _completionHandled) {
      _nextEpisodeTimer?.cancel();
      _nextEpisode = null;
      _completionHandled = false;
      if (mounted) setState(() {});
    }
    if (controller != null && !controller.value.hasError &&
        controller.value.isCompleted &&
        !_completionHandled && widget.contentType == PlaybackContentType.series) {
      _completionHandled = true;
      _offerNextEpisode();
    }
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    _lastErrorDescription = controller.value.errorDescription;
    _handleActiveError();
  }

  void _offerNextEpisode() {
    final series = widget.series;
    final episode = widget.episode;
    if (series == null || episode == null || widget.consecutiveEpisodes >= 3) return;
    final next = nextPlayableEpisode(series, episode);
    if (next == null) return;
    _nextEpisode = next;
    _nextEpisodeSeconds = 15;
    _nextEpisodeTimer?.cancel();
    _nextEpisodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_nextEpisodeSeconds <= 1) {
        timer.cancel();
        _playNextEpisode();
      } else {
        setState(() => _nextEpisodeSeconds--);
      }
    });
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nextEpisode == next) _nextEpisodeFocus.requestFocus();
    });
  }

  Future<void> _playNextEpisode() async {
    final next = _nextEpisode;
    final series = widget.series;
    if (next == null || series == null || !mounted) return;
    _nextEpisodeTimer?.cancel();
    _nextEpisode = null;
    final profileId = ref.read(currentProfileProvider)?.id ?? '';
    final disposal = _cleanup();
    final generation = _generation;
    try {
      await disposal.timeout(const Duration(seconds: 5));
      await _progressWriter.pending;
    } catch (error, stackTrace) {
      debugPrint('Impossible de libérer le lecteur précédent : $error\n$stackTrace');
      if (mounted && generation == _generation) {
        _lastErrorDescription = 'Impossible de libérer le lecteur précédent.';
        _setStatus(_PlayerStatus.error);
      }
      return;
    }
    if (!mounted || generation != _generation ||
        ModalRoute.of(context)?.isCurrent != true) return;
    context.pushReplacement(
      '/player',
      extra: PlayerRouteData(
        streamUrl: next.streamUrl,
        title: next.title,
        progressId: PlaybackProgressService.idForProfile(profileId, 'episode-${next.id}'),
        contentType: PlaybackContentType.series,
        posterUrl: series.coverUrl,
        subtitle: series.genre,
        rating: series.rating > 0 ? series.rating : null,
        genre: series.genre.isNotEmpty ? series.genre : null,
        year: series.year,
        seriesName: series.title,
        episodeLabel: next.title,
        series: series,
        episode: next,
        consecutiveEpisodes: widget.consecutiveEpisodes + 1,
      ),
    );
  }

  /// Ré-applique la piste audio choisie précédemment pour ce contenu
  /// (préférence mémorisée par contenu). Best-effort.
  /// Gère aussi les préférences au niveau série (langue forcée pour tous les épisodes).
  Future<void> _applySavedAudioTrack(VideoPlayerController controller) async {
    await applySavedAudioTrack(
      controller: controller,
      mediaKey: widget.progressId ?? widget.streamUrl,
      seriesId: widget.episode != null ? widget.series?.id : null,
      isCurrent: () => mounted && _controller == controller,
    );
  }

  /// Démarre le balayage des sous-titres intégrés du flux.
  ///
  /// Un contenu adaptatif publie ses pistes texte progressivement : la première
  /// sonde, juste après `isInitialized`, ne voit souvent qu'une partie de la
  /// liste (le manifeste) alors que les autres arrivent bien plus tard. On
  /// rejoue donc la sonde chaque seconde, en ne propageant
  /// que lorsque la liste change, jusqu'à un délai borné qui couvre le
  /// chargement observé.
  void _startEmbeddedScan(VideoPlayerController controller) {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) return;
    final probeGeneration = _generation;
    final ctrl = ref.read(subtitleControllerProvider);
    _subtitlePreferences.startScan(ctrl);
    bool isCurrent() =>
        mounted && probeGeneration == _generation && _controller == controller;
    _embeddedScanner.start(
      player: controller,
      isCurrent: isCurrent,
      onTracks: (tracks, scanIsCurrent) async {
        ctrl.setEmbeddedContext(
          playerId: embeddedPlayerId(controller),
          tracks: tracks,
        );
        if (tracks.isNotEmpty) {
          LoggerService.instance.info(
            'sous-titres intégrés détectés: '
            '${tracks.map((t) => '${t.id}:${t.label}').join(', ')}',
          );
        }
        await _subtitlePreferences.applyVod(
          controller: ctrl,
          tracks: tracks,
          contentType: widget.contentType,
          generation: probeGeneration,
          readMode: () => ref.read(advancedSettingsProvider).vodSubtitleMode,
          isCurrent: scanIsCurrent,
        );
        if (!scanIsCurrent()) return;
        await _subtitlePreferences.applySeries(
          controller: ctrl,
          seriesId: widget.episode != null ? widget.series?.id : null,
          generation: probeGeneration,
          isCurrent: scanIsCurrent,
        );
      },
    );
  }

  /// Détecte une coupure d'anti-leech fournisseur (ExoPlayer: HTTP 401 /
  /// Source error), distincte d'une simple chaîne indisponible.
  static bool isProviderBlock(String? description) {
    return isPlaybackProviderBlock(description);
  }

  Future<void> _handleActiveError() async {
    if (!mounted || _handlingError) return;
    final gen = _generation;
    _handlingError = true;
    _saveProgress(preserveOnError: true);
    final failingController = _controller;
    _controller = null;
    failingController?.removeListener(_onControllerUpdate);
    if (!mounted || gen != _generation) {
      _handlingError = false;
      return;
    }
    // `_controller` est maintenant null mais `_status` vaut encore `ready` :
    // le build construit `ReadyPlayer(controller: player!)` et n'importe quel
    // rebuild (auto-masquage du footer ~5 s après un tap, listener du lecteur)
    // crashe sur le null-check tant que la reprise n'a pas abouti. On force
    // l'affichage « chargement » dès ici ; `_startAttempt` (ou `_setStatus`
    // error) prendra le relais ensuite.
    if (mounted) _setStatus(_PlayerStatus.loading);
    // Let the platform error callback finish before cancelling its event stream.
    await Future<void>.delayed(Duration.zero);
    if (failingController != null) {
      final disposal = await safeAsync(
        () => _disposeController(failingController)
            .timeout(const Duration(seconds: 5)),
        context: 'PlayerScreen.disposeAfterError',
      );
      if (disposal.isFailure) {
        await _progressWriter.pending;
        if (mounted && gen == _generation) {
          _handlingError = false;
          _setStatus(_PlayerStatus.error);
        }
        return;
      }
    }
    await _progressWriter.pending;
    if (!mounted || gen != _generation) return;
    final errorDesc = _lastErrorDescription;
    final host = Uri.tryParse(_activeStreamUrl)?.host ?? '';
    final isProviderBlockError = isProviderBlock(errorDesc);

    // Enregistre l'échec dans le circuit breaker si c'est un blocage fournisseur
    if (isProviderBlockError && host.isNotEmpty) {
      ref.read(hostCircuitBreakerProvider).recordFailure(host);
    }

    final recovery = playbackRecoveryAction(
      description: errorDesc,
      attempts: _autoRecoveryAttempts,
    );
    if (recovery == PlaybackRecoveryAction.showError) {
      _handlingError = false;
      _setStatus(_PlayerStatus.error);
      return;
    }

    if (recovery == PlaybackRecoveryAction.retry) {
      _autoRecoveryAttempts++;
      if (isPlaybackDecoderError(errorDesc)) {
        _decoderModeOverride = decoderRecoveryMode(
              errorDesc,
              VideoDecoderPrefs.mode,
            ) ??
            _decoderModeOverride;
      }
      _handlingError = false;
      if (!mounted || gen != _generation) return;
      _startAttempt();
      return;
    }
    _handlingError = false;
    _setStatus(_PlayerStatus.error);
    if (_engineConfig.fallback.isExternal) {
      final launched = await _launchFallbackExternal();
      if (launched && mounted && gen == _generation) {
        _showExternalPlaybackState();
      }
    }
  }

  void _goNext({bool focusControls = true}) {
    if (!_hasNext) return;
    _showFooterBar(focusControls: focusControls);
    // `_switchTo` incremente `_generation` de facon synchrone avant son
    // premier `await`, donc un zapping rapide reste correctement ordonne :
    // chaque appel voit l'_index deja change et les appels obsoletes sont
    // abandonnes par la garde de generation.
    unawaited(_switchTo(_index + 1));
  }

  void _goPrevious({bool focusControls = true}) {
    if (!_hasPrevious) return;
    _showFooterBar(focusControls: focusControls);
    unawaited(_switchTo(_index - 1));
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

  /// Bascule sur [target].
  ///
  /// Asynchrone a dessein : `pause()` est une commande plateforme. Sans
  /// `await`, l'ancien lecteur restait branche quelques centaines de ms apres
  /// que le nouveau eut commence, ce qui suffisait a faire cohabiter deux
  /// decodeurs audio sur la meme chaine. Le zapping etant pilote par une
  /// succession d'appuis sur `_goNext`/`_goPrevious`, chaque appel incremente
  /// `_generation` : une bascule annulee entre-temps est abandonnee sans
  /// toucher au controleur, qui reste la propriete du lecteur en cours.
  Future<void> _switchTo(int target) async {
    if (!mounted ||
        target == _index ||
        target < 0 ||
        target >= _channels.length) {
      return;
    }
    final gen = ++_generation;
    _autoRecoveryAttempts = 0;
    _externalPlaybackLaunched = false;
    _decoderModeOverride = null;
    _checkpoint.reset();
    _resumePlaying = true;
    _handlingError = false;
    // Nouveau contenu (zapping) : la piste externe du flux précédent ne doit
    // pas continuer de s'afficher. Le contrôleur est partagé et le player
    // (re)joue le même média sur `_retry` : le reset n'a lieu qu'ici, au vrai
    // changement de contenu.
    ref.read(subtitleControllerProvider).resetForNewContent();
    final forward = target > _index;
    final oldActive = _controller;
    final newActive = _takeCachedFor(target);
    if (forward) {
      _adjacentPlayers.clearPrevious();
    } else {
      _adjacentPlayers.clearNext();
    }
    _index = target;
    _preloader.cancel();
    _controller = newActive;
    _lastKnownPlaying = null;
    _appliedAudioPref = false;
    if (oldActive != null) {
      oldActive.removeListener(_onControllerUpdate);
      if (oldActive.value.isInitialized &&
          !oldActive.value.hasError &&
          !PlayerCrashGuard.safeMode &&
          !ref.read(tvModeNotifierProvider).enabled) {
        // `await` avant toute decision : tant que la commande plateforme n'est
        // pas passee, l'ancien decodeur audio tourne encore.
        final precedingPause = _pendingZapPause;
        final pause = () async {
          if (precedingPause != null) await precedingPause;
          await oldActive.pause();
        }();
        _pendingZapPause = pause;
        try {
          await pause;
        } finally {
          if (identical(_pendingZapPause, pause)) _pendingZapPause = null;
        }
        if (!mounted || gen != _generation) {
          // Un autre zapping a pris la main pendant l'attente : cet ancien
          // controleur n'appartient plus a personne. On ne le remet surtout
          // pas en cache, on le libere.
          _disposeController(oldActive);
          return;
        }
        if (forward) {
          _adjacentPlayers.setPrevious(target - 1, oldActive);
        } else {
          _adjacentPlayers.setNext(target + 1, oldActive);
        }
      } else {
        oldActive.dispose();
      }
    }
    final pendingPause = _pendingZapPause;
    if (pendingPause != null) await pendingPause;
    if (!mounted || gen != _generation) return;
    if (newActive != null) {
      newActive.addListener(_onControllerUpdate);
      // Le focus audio est pris ICI, apres la pause confirmee de l'ancien
      // lecteur : c'est cet ordre qui supprime le recouvrement, pas le flag.
      newActive.play();
      _setStatus(_PlayerStatus.ready);
      // Réattache la détection de stall au NOUVEAU contrôleur : avant ce
      // rappel, elle continuait de surveiller l'ancien (mis en pause ou
      // disposé par _switchTo) — la détection morte l'heure suivante, ou un
      // tick sur un contrôleur disposé si l'ancien était en erreur.
      _startStallDetection();
      _showInfoBrief();
    } else {
      _startAttempt();
    }
    _startPreload();
  }

  VideoPlayerController? _takeCachedFor(int target) {
    final cached = _adjacentPlayers.take(target);
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
    // Sur TV ou en mode sûr, éviter un second lecteur et son décodeur.
    if (ref.read(tvModeNotifierProvider).enabled ||
        PlayerCrashGuard.safeMode) {
      return;
    }
    // Ne pas precharger pendant que la lecture courante se bat encore : le
    // panneau limite les connexions simultanees et un prechargement en echec
    // aggrave les 401 de la chaine en cours.
    // Precharger uniquement quand la lecture courante est CONFIRMEE en cours.
    // Sinon (controleur absent, pas encore initialise, ou fige) le
    // prechargement consomme le budget de connexions du panneau et affame le
    // flux en cours : on observait 4 x 401 en cascade toutes les 4 s pendant
    // que la position du flux principal restait bloquee.
    final current = _controller;
    final candidate = preloadCandidate(
      channels: _channels,
      currentIndex: _index,
      hasCachedNext: _adjacentPlayers.hasNext,
      pendingIndex: _preloader.pendingIndex,
      currentInitialized: current?.value.isInitialized ?? false,
      currentPlaying: current?.value.isPlaying ?? false,
    );
    if (candidate == null) return;
    final target = candidate.index;
    // Préchargement relais uniquement si le proxy est prêt.
    final targetUrl = maybeRebaseThroughProxy(
      candidate.url,
      proxyReady: ref.read(rustProxyManagerProvider).isReady,
    );
    await _preloader.start(
      index: target,
      attempts: _userAgentOrder(),
      isCurrent: () => mounted && gen == _generation,
      create: (attempt) => VideoPlayerController.networkUrl(
        Uri.parse(targetUrl),
        httpHeaders: _resolvedHeaders(targetUrl, attempt),
        videoPlayerOptions: _exclusivePlayback,
      ),
      initialize: (controller) async {
        final result = await safeAsync(
          () => controller.initialize().timeout(_probTimeout),
          context: '_startPreload controller.initialize',
        );
        if (result.isFailure) {
          debugPrint('Orbit3D preload error: ${result.errorOrNull}');
        }
        return !result.isFailure;
      },
      isUsable: (controller) => !controller.value.hasError,
      pause: (controller) => unawaited(controller.pause()),
      canAccept: () => !_adjacentPlayers.hasNext,
      accept: _adjacentPlayers.setNext,
      dispose: (controller) => unawaited(_disposeController(controller)),
    );
  }

  Future<void> _disposeController(VideoPlayerController controller) async {
    // Coupe le pont sous-titres intégrés de CE lecteur avant de libérer la
    // texture : le polling s'arrête et l'état est vidé sans toucher à un
    // éventuel autre lecteur (préchauffage).
    _subtitleController.detachEmbedded(embeddedPlayerId(controller));
    // Arrête le balayage s'il visait CE lecteur (le timer se neutralise sinon
    // au tick suivant, mais autant le libérer tout de suite).
    _embeddedScanner.stopPlayer(controller);
    controller.removeListener(_onControllerUpdate);
    final session = _proxySessions.remove(controller);
    try {
      await controller.dispose();
    } finally {
      session?.close();
    }
  }

  Future<void> _disposeActive() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return Future<void>.value();
    return _disposeController(controller);
  }

  void _setStatus(_PlayerStatus status) {
    if (!mounted) return;
    final wasReady = _status == _PlayerStatus.ready;
    setState(() {
      _status = status;
    });
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
      final detector = ref.read(stallDetectorProvider);
      final watched = VideoPlayerWatchable(controller);
      // Ne redémarre pas un détecteur déjà attaché au MÊME contrôleur : les
      // transitions ready->ready (zapping sur cache) relancent plusieurs fois
      // la détection dans la même frame, on économise le restart inutile.
      if (detector.isRunning && detector.isAttachedTo(watched)) {
        return;
      }
      _stallDetector = detector;
      detector.start(watched);
    }
  }

  void _stopStallDetection() {
    _stallDetector?.stop();
    _stallDetector = null;
  }

  /// Relance explicitement la lecture après l'action de l'utilisateur.
  Future<void> _retry() async {
    final now = DateTime.now();
    if (_retrying ||
        (_lastRetryTime != null &&
            now.difference(_lastRetryTime!) < const Duration(seconds: 2))) {
      return; // debounce : une relance au plus toutes les 2 s
    }
    _lastRetryTime = now;
    _retrying = true;
    if (mounted) setState(() {});

    try {
      _generation++;
      _preloader.cancel();
      _handlingError = false;
      _autoRecoveryAttempts = 0;
      _externalPlaybackLaunched = false;
      _adjacentPlayers.clear();
      _disposeActive();
      _setStatus(_PlayerStatus.loading);

      _startAttempt();
      _startPreload();
    } finally {
      _retrying = false;
      if (mounted) setState(() {});
    }
  }

  void _showInfoBrief() {
    if (!mounted) return;
    _showFooterBar();
  }

  Future<void> _recordHistory() async {
    await safeAsync<void>(
      () async {
        final entry = playbackHistoryEntry(
          channel: _currentChannel,
          favorite: widget.favorite,
          fallbackStreamUrl: widget.streamUrl,
        );
        if (entry == null) return;
        final recentlyWatched = ref.read(recentlyWatchedProvider.notifier);
        final history = ref.read(historyServiceProvider);
        await writePlaybackHistory(
          entry: entry,
          writeRecent: (value) => recentlyWatched.record(
            value.type,
            value.id,
            value.title,
            posterUrl: value.posterUrl,
            subtitle: value.subtitle,
            streamUrl: value.streamUrl,
          ),
          writeHistory: (value) =>
              history.addEntry(value.type.name, value.title, value.streamUrl),
        );
      },
      context: '_recordHistory',
    );
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
      volumeNormalization: nf.nightFocusVolumeNormalization,
    );
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    final playing = controller.value.isPlaying;
    debugPrint(
      'Orbit3D toggle: isPlaying=$playing pos=${controller.value.position}',
    );
    setState(() {
      playing ? controller.pause() : controller.play();
    });
    if (playing) _bgService.stop();
    _syncImmersive();
    _showFooterBar();
  }

  /// Bascule en fenêtre flottante Picture-in-Picture avec le ratio de la vidéo.
  Future<void> _enterPip() async {
    final size = _controller?.value.size;
    var width = size?.width.round() ?? 16;
    var height = size?.height.round() ?? 9;
    if (width <= 0 || height <= 0) {
      width = 16;
      height = 9;
    }
    final entered = await _pipService.enter(width: width, height: height);
    if (!entered && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.pipUnavailable),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

  Future<void> _cleanup() {
    _generation++;
    _embeddedScanner.stop();
    _restoreSystemUi();
    _footerTimer?.cancel();
    _nextEpisodeTimer?.cancel();
    _saveProgressTimer?.cancel();
    _saveProgress();
    final disposal = _disposeActive();
    _adjacentPlayers.clear();
    _preloader.cancel();
    return disposal;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_status != _PlayerStatus.ready || _playerErrorScope.hasFocus) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final decision = resolvePlayerKey(
      key: event.logicalKey,
      repeat: event is KeyRepeatEvent,
      isLive: widget.contentType == PlaybackContentType.live,
      footerVisible: _footerVisible,
      footerHasFocus: _footerScope.hasFocus,
      nextEpisodeHasFocus: _nextEpisodeFocus.hasFocus,
      isPlaying: event.logicalKey == LogicalKeyboardKey.mediaPlay ||
              event.logicalKey == LogicalKeyboardKey.mediaPause
          ? _controller?.value.isPlaying ?? false
          : false,
    );
    if (decision.refreshFooter) _showFooterBar();
    switch (decision.action) {
      case PlayerKeyAction.ignored:
        return KeyEventResult.ignored;
      case PlayerKeyAction.handled:
        break;
      case PlayerKeyAction.nextEpisode:
        unawaited(_playNextEpisode());
      case PlayerKeyAction.previousUnfocused:
        _goPrevious(focusControls: false);
      case PlayerKeyAction.nextUnfocused:
        _goNext(focusControls: false);
      case PlayerKeyAction.showFooter:
        _showFooterBar();
      case PlayerKeyAction.previous:
        _goPrevious();
      case PlayerKeyAction.next:
        _goNext();
      case PlayerKeyAction.togglePlayback:
        _togglePlayPause();
      case PlayerKeyAction.showDetails:
        final player = _controller;
        if (player != null) {
          _footerTimer?.cancel();
          showStreamDetailsSheet(
            context,
            player,
            widget.progressId ?? widget.streamUrl,
            isLive: widget.contentType == PlaybackContentType.live,
          ).whenComplete(() {
            if (mounted) _showFooterBar();
          });
        }
      case PlayerKeyAction.seekForward:
        _seekBy(const Duration(seconds: 30));
        _showFooterBar();
      case PlayerKeyAction.seekBackward:
        _seekBy(const Duration(seconds: -30));
        _showFooterBar();
      case PlayerKeyAction.toggleFooter:
        _toggleFooter();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    // Peut être null pendant une reprise d'erreur (`_handleActiveError` dispose
    // le contrôleur avant de rebasculer le statut) : un `!` ici transformait le
    // zapping en « Null check operator used on a null value » dès qu'un rebuild
    // (auto-masquage du footer, listener) survenait dans cette fenêtre. Le
    // status `ready` sans contrôleur devient un état de chargement silencieux.
    final player = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: Padding(
            padding: _status == _PlayerStatus.ready && player != null
                ? EdgeInsets.zero
                : const EdgeInsets.all(16),
            child: switch (_status) {
              _PlayerStatus.loading => widget.contentType == PlaybackContentType.live
                  ? const VideoLoadingState()
                  : DelayedPlaybackLoading(
                      key: ValueKey(_generation),
                      onRetry: _retry,
                    ),
              _PlayerStatus.error => PlayerErrorView(
                  externalPlaybackLaunched: _externalPlaybackLaunched,
                  errorDescription: _lastErrorDescription,
                  contentType: widget.contentType,
                  onRetry: _retry,
                  onProviderWebsite: _openProviderWebsite,
                ),
              _PlayerStatus.ready => player != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Focus(
                          canRequestFocus: false,
                          skipTraversal: true,
                          onKeyEvent: (_, event) {
                            if (!_playerErrorScope.hasFocus &&
                                event is KeyDownEvent &&
                                (event.logicalKey ==
                                        LogicalKeyboardKey.select ||
                                    event.logicalKey ==
                                        LogicalKeyboardKey.enter ||
                                    event.logicalKey ==
                                        LogicalKeyboardKey.numpadEnter)) {
                              _showFooterBar();
                            }
                            return KeyEventResult.ignored;
                          },
                          child: FocusScope(
                            node: _playerErrorScope,
                            child: ReadyPlayer(
                              controller: player,
                              onTap: _showFooterBar,
                              streamUrl: _activeStreamUrl,
                              onRetry: _retry,
                              watchBuffering:
                                  widget.contentType != PlaybackContentType.live,
                            ),
                          ),
                        ),
                        PlayerSubtitleOverlay(controller: player),
                        if (_footerVisible)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: FocusScope(
                              node: _footerScope,
                              onKeyEvent: (_, event) {
                                if (event is KeyDownEvent) _showFooterBar();
                                return KeyEventResult.ignored;
                              },
                              child: ContentFooterBar(
                                child: PlayerFooterContent(
                                  controller: player,
                                  contentType: widget.contentType,
                                  streamUrl: widget.streamUrl,
                                  progressId: widget.progressId,
                                  channel: _currentChannel,
                                  title: widget.title,
                                  subtitle: widget.subtitle,
                                  seriesName: widget.seriesName,
                                  episodeLabel: widget.episodeLabel,
                                  rating: widget.rating,
                                  genre: widget.genre,
                                  index: _index,
                                  total: _channels.length,
                                  onExit: _requestExit,
                                  onPrevious: _hasPrevious ? _goPrevious : null,
                                  onNext: _hasNext ? _goNext : null,
                                  onTogglePlayPause: _togglePlayPause,
                                  onPip: _pipSupported == true ? _enterPip : null,
                                  onSeekBack30: () =>
                                      _seekBy(const Duration(seconds: -30)),
                                  onSeekForward30: () =>
                                      _seekBy(const Duration(seconds: 30)),
                                  onToggleNightFocus: _toggleNightFocus,
                                  onDetailsOpened: () => _footerTimer?.cancel(),
                                  onDetailsClosed: _showFooterBar,
                                  onProgressInteraction: () =>
                                      _showFooterBar(focusControls: false),
                                ),
                              ),
                            ),
                          ),
                        if (_nextEpisode != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: _footerVisible ? 130 : 24,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: FilledButton(
                                focusNode: _nextEpisodeFocus,
                                onPressed: () => _playNextEpisode(),
                                child: Text(
                                  'Épisode suivant : ${_nextEpisode!.title} '
                                  '${_nextEpisodeTimer?.isActive == true ? "($_nextEpisodeSeconds s)" : ""}',
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const VideoLoadingState(),
            },
          ),
        ),
      ),
    );
  }

}
