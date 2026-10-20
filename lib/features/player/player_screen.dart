import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_monitoring_overlay.dart';
import 'package:orbit_3d_flutter/features/player/widgets/stream_details_sheet.dart';
import 'package:orbit_3d_flutter/features/player/widgets/cast_button.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/features/player/widgets/time_progress_bar.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/watched_episodes_provider.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/stream_prewarm_service.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:orbit_3d_flutter/services/pip_service.dart';
import 'package:orbit_3d_flutter/services/background_playback_service.dart';
import 'package:orbit_3d_flutter/services/cloudflare_bypass_service.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:orbit_3d_flutter/features/player/widgets/subtitle_overlay.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

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
    this.series,
    this.episode,
    this.vodId,
    this.isLocalFile = false,
    this.headers,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int index;
  final String? progressId;
  final int? initialPositionMs;

  /// Identifiant VOD du film (`stream_id`), utilisé pour découvrir les
  /// sous-titres publiés par le panel. `null` pour un flux live ou une série.
  final String? vodId;
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

  /// Contexte série (lecture d'un épisode) : permet au player de poser le
  /// statut « vu » quand l'épisode atteint 80 % de progression.
  final Series? series;
  final Episode? episode;

  /// Si true, `streamUrl` est un chemin de fichier local (hors-ligne).
  final bool isLocalFile;

  /// Headers HTTP optionnels (pour flux protégés ou fichiers locaux avec auth).
  final Map<String, String>? headers;
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
    this.series,
    this.episode,
    this.vodId,
    this.isLocalFile = false,
    this.headers,
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

  /// Si true, `streamUrl` est un chemin de fichier local (hors-ligne).
  final bool isLocalFile;

  /// Headers HTTP optionnels (pour flux protégés ou fichiers locaux avec auth).
  final Map<String, String>? headers;

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

/// Seuil (fraction lue) au-delà duquel un épisode de série est posé « vu ».
const double _seriesWatchedThreshold = 0.8;

/// Bornes du back-off appliqué après un 401 du panneau.
///
/// Qui arbitre le rythme, et pourquoi.
///
/// Le NATIF est l'autorité du rythme : `LoggingDataSource` espace les
/// ouvertures avec un verrou GLOBAL partagé par tous les contrôleurs de la
/// processus (lecture, préchauffage, préchargement) et réessaie 3 fois avec
/// 3/8/20 s. C'est le seul étage qui voit les contrôleurs que cet écran ne
/// connaît pas, donc le seul qui puisse empêcher la rafale de requêtes
/// « quasi simultanées » que l'anti-leech sanctionne.
///
/// Ces bornes Dart ne sont donc PAS une seconde barrière anti-leech à
/// empiler : elles n'espacent que les tentatives déclenchées depuis cet
/// écran (relance manuelle, zapping), le temps que le verrou natif fasse son
/// office. D'où des valeurs volontairement courtes : le refus que le natif a
/// déjà payé (jusqu'à 31 s) ne doit pas être doublé d'une pénalité de 4 à
/// 60 s d'écran noir. Le cumul des deux était la source des dizaines de
/// secondes d'attente sans que le CDN y gagne quoi que ce soit.
///
/// Measured sur draap.online : 4 requêtes quasi simultanées en boucle → 0 % de
/// réussite, alors qu'une requête isolée réussit une fois sur deux. Marteler
/// l'endpoint garantit donc de rester bloqué.
const List<Duration> _rateLimitBackoffs = [
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 20),
];

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
/// Les caches `_cachedPrev`/`_cachedNext` redeviennent sûrs.
final VideoPlayerOptions _exclusivePlayback = VideoPlayerOptions(
  mixWithOthers: false,
  allowBackgroundPlayback: false,
);

class PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  List<Channel> _channels = const [];
  late int _index;
  VideoPlayerController? _controller;
  VideoPlayerController? _cachedNext;
  int? _cachedNextIndex;
  VideoPlayerController? _cachedPrev;

  /// Nombre de 401 consécutifs et fin du délai de refroidissement courant.
  int _rateLimitStrikes = 0;
  DateTime? _rateLimitUntil;

  /// La dernière tentative a essuyé un refus anti-leech : inutile d'enchaîner
  /// sur les autres variantes d'URL, elles seront refusées aussi.
  bool _rateLimitedOnLastAttempt = false;

  /// Piste audio préférée ré-appliquée après l'initialisation du contrôleur.
  bool _appliedAudioPref = false;

  /// Génération pour laquelle la préférence de sous-titres d'une série a déjà
  /// été appliquée (`-1` = jamais). Évite de rejouer la sélection à chaque
  /// vague de découverte — et donc de reprendre la main sur un choix manuel.
  int _appliedSeriesSubtitleGeneration = -1;

  /// Balayage des sous-titres intégrés.
  ///
  /// Un flux adaptatif (HLS/DASH) n'annonce pas ses pistes texte d'un coup :
  /// media3 publie d'abord quelques pistes, puis les autres au fil du
  /// chargement — sur le panel mesuré, la liste complète n'arrive qu'après
  /// ~30 s. Un unique appel juste après `isInitialized` ne captait donc que la
  /// première vague (une piste sur cinq). On rejoue la sonde tant que la liste
  /// évolue, jusqu'à un délai borné.
  Timer? _embeddedScanTimer;
  VideoPlayerController? _embeddedScanController;

  String _embeddedSig = kEmbeddedSigUnset;
  bool _embeddedScanRunning = false;
  int? _cachedPrevIndex;
  int? _preloadTarget;
  _PlayerStatus _status = _PlayerStatus.loading;
  bool _handlingError = false;
  bool _autorecovered = false;
  bool _retrying = false;
  DateTime? _lastRetryTime;
  String? _lastErrorDescription;
  int _generation = 0;
  bool _footerVisible = false;
  Timer? _footerTimer;
  Timer? _saveProgressTimer;
  bool _immersive = false;
  bool _hasAppliedInitialPosition = false;
  bool? _lastKnownPlaying;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerScreen');
  /// FocusNode du bouton Play/Pause de la footerbar TV : reçoit le focus
  /// dès que la barre apparaît, pour que la télécommande pilote directement
  /// la lecture sans devoir naviguer manuellement.
  final FocusNode _footerPlayFocus =
      FocusNode(debugLabel: 'FooterPlayPause');

  // Picture-in-Picture & lecture en arrière-plan
  final _pipService = PipService();
  final _bgService = BackgroundPlaybackService();
  StreamSubscription<String>? _remoteCommandSub;
  bool? _pipSupported;

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
    WidgetsBinding.instance.addObserver(this);
    // Commandes de la MediaSession native (télécommande TV, casque, contrôles
    // de la notification) : reçues quand l'app n'a plus le focus clavier.
    _remoteCommandSub = _bgService.commands.listen(_handleRemoteCommand);
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
    LoggerService.instance.info(
      'PLAYER_INIT channels=${_channels.length} index=$_index '
      'url=${widget.streamUrl}',
    );
    // Nouvelle lecture (nouvelle PlayerScreen) : le contrôleur de sous-titres
    // est partagé par toute l'app — sans ce reset, la piste externe choisie
    // sur le contenu précédent restait active et son texte s'affichait sur
    // le nouveau contenu.
    ref.read(subtitleControllerProvider).resetForNewContent();
    _initializePlayer();
    _startSaveProgressTimer();
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
    WidgetsBinding.instance.removeObserver(this);
    _restoreSystemUi();
    _footerTimer?.cancel();
    _saveProgressTimer?.cancel();
    _monitoringTimer?.cancel();
    _stallDetector?.stop();
    _remoteCommandSub?.cancel();
    _remoteCommandSub = null;
    _bgService.stop();
    _saveProgress();
    _focusNode.dispose();
    _footerPlayFocus.dispose();
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
      _bgService.stop();
    } else {
      _restoreSystemUi();
      // Lecture active + app non au premier plan (PiP, home, écran éteint) :
      // le foreground service mediaPlayback garde le process vivant (Android 14+).
      if (_controller?.value.isPlaying == true &&
          _status == _PlayerStatus.ready) {
        _bgService.start(
          title: _playbackTitle,
          subtitle: _playbackSubtitle,
          playing: true,
        );
      }
    }
  }

  /// Passe en plein écran immersif (masque status bar + navbar Android)
  /// quand la vidéo joue. Si la footerbar est visible (tap/OK), on attend sa
  /// disparition (timer ~5s) puis on repasse en immersive via _syncImmersive().
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
    if (mounted && firstShow) {
      setState(() {});
      // En mode TV, poser le focus sur Play/Pause dès l'apparition de la
      // barre : la télécommande pilote directement la lecture.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _footerVisible) _footerPlayFocus.requestFocus();
      });
    }
    // Synchroniser l'état : on sort de l'immersif avant de passer en edgeToEdge,
    // sinon _syncImmersive() ne remettra jamais en immersive (garde !immersive).
    _immersive = false;
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

    // Épisode de série : dès que 80 % sont regardés, l'épisode est posé
    // comme « vu » pour le profil courant (tout en restant reprenable).
    final fraction = durationMs > 0 ? positionMs / durationMs : 0.0;
    if (fraction >= _seriesWatchedThreshold) {
      final series = widget.series;
      final episode = widget.episode;
      if (series != null && episode != null) {
        ref.read(watchedEpisodesProvider.notifier).record(series, episode);
      }
    }

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
    LoggerService.instance.info(
      'ZAPPING_ATTEMPT start: url=$_activeStreamUrl gen=$gen rateLimitUntil=$_rateLimitUntil',
    );

    // Refroidissement après un 401 anti-leech : on laisse l'endpoint avant de
    // repartir, sinon on accumulate les refus et le blocage s'allonge.
    await _awaitRateLimitCooldown();
    if (!mounted || gen != _generation) {
      LoggerService.instance.info(
        'ZAPPING_ATTEMPT aborted after cooldown: gen=$gen cur=$_generation',
      );
      return;
    }

    // Attendre que la session Cloudflare soit prete (Xtream) AVANT la 1ere
    // tentative. Pas de cap externe : CloudflareSessionManager borne lui-meme
    // chaque tentative (20/30/45s). Un cap externe plus court abandonnait le
    // challenge en cours puis demarrait la lecture sans cookies, ce qui
    // produisait systematiquement le 403 "flux indisponible" au premier
    // chargement. safeAsync absorbe l'echec pour ne pas bloquer la lecture.
    final sub = ref.read(activeSubscriptionProvider);
    if (sub != null && sub.type == SubscriptionType.xtream) {
      final cf = ref.read(cloudflareSessionProvider);
      if (!cf.isReady) {
        debugPrint('☁️ Waiting for Cloudflare session before first play...');
        if (mounted) _setStatus(_PlayerStatus.loading);
        await safeAsync(
          () => cf.initialize(baseUrl: _getPanelBaseUrl()),
          context: '_startAttempt cloudflareSession.initialize',
        );
        if (!cf.isReady) {
          debugPrint('☁️ Cloudflare session unavailable; manual unlock will '
              'be offered by the error screen.');
        }
      }
    }

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
      Media3PlaybackProfile.forProfile(ref.read(deviceProfileProvider)),
    );
    if (!isLikelyStreamUrl(_activeStreamUrl)) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }
    // Flux préchauffé par la grille Live TV : zapping sans démarrage à froid.
    final prewarmed = StreamPrewarmService.instance.take(_activeStreamUrl);
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
    var rateLimitedAttempts = 0;
    for (final attemptUrl in variants) {
      final found = await _tryPlay(gen, attemptUrl);
      if (found) return;
      if (!mounted || gen != _generation) return;
      if (_rateLimitedOnLastAttempt) {
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
    final result = await safeAsync<bool>(
      () async {
        final url = _activeStreamUrl;
        final uri = engine == PlayerEngine.vlc
            ? Uri.parse('vlc://$url')
            : Uri.parse(url);
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
      },
      context: '_launchFallbackExternal',
      fallbackValue: false,
    );
    return result.valueOrNull ?? false;
  }

  /// Retourne l'URL de base du panel IPTV (pour headers Referer/Cloudflare).
  String _getPanelBaseUrl() {
    final sub = ref.read(activeSubscriptionProvider);
    if (sub == null || sub.baseUrl == null) return 'https://example.com';
    final uri = Uri.tryParse(sub.baseUrl!);
    if (uri == null) return 'https://example.com';
    return '${uri.scheme}://${uri.host}';
  }

  /// Ordre des User-Agents à tenter à la lecture. Quand l'impersonation TLS
  /// est active (réglage avancé), on privilégie l'User-Agent navigateur
  /// (index 0) qui imite le trafic d'un navigateur moderne pour contourner
  /// Cloudflare ; sinon on tente d'abord l'Agent natif ExoPlayer.
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

  /// Construit les en-têtes HTTP pour une URL de flux, en fusionnant :
  /// 1. Les headers de base (User-Agent rotation, etc.)
  /// 2. Les cookies Cloudflare globaux (session unique pour tout le fournisseur)
  /// 3. Les cookies Cloudflare spécifiques à l'hôte (CloudflareBypassService)
  Map<String, String> _resolvedHeaders(String url, int agentIndex) {
    // Get panel URL from active subscription for Xtream Referer
    final activeSub = ref.read(activeSubscriptionProvider);
    final panelUrl = activeSub?.baseUrl;

    final base =
        streamHeaders(url, userAgentIndex: agentIndex, panelUrl: panelUrl);

    // 1. Session Cloudflare globale (init au démarrage, unique pour tout le fournisseur)
    final globalCf = ref.read(cloudflareSessionProvider);
    if (globalCf.isReady) {
      // Arme le renouvellement préventif si les cookies sont périmés
      // (fire-and-forget : le vrai blocage est géré dans _handleActiveError).
      globalCf.getFreshHeaders();
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
    final result = await safeAsync<bool>(
      () async {
        final url = _activeStreamUrl;
        // Pour VLC on préfère le schéma vlc:// ; sinon intent https générique.
        final uri = engine == PlayerEngine.vlc
            ? Uri.parse('vlc://$url')
            : Uri.parse(url);
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
      },
      context: '_launchExternal',
      fallbackValue: false,
    );
    return result.valueOrNull ?? false;
  }

  /// Vrai si l'erreur vient d'un refus HTTP du panneau/CDN (401/403).
  ///
  /// Un 401 n'a rien à voir avec l'User-Agent : c'est l'anti-leech en aval du
  /// 302 qui refuse la connexion. Insister avec d'autres User-Agents ne peut
  /// qu'augmenter le nombre de requêtes et allonger le refus.
  static bool _isRateLimitedError(Object? error) {
    if (error == null) return false;
    final text = error.toString();
    return text.contains('Response code: 401') ||
        text.contains('Response code: 403') ||
        text.contains('InvalidResponseCodeException');
  }

  /// Enregistre un refus et arme le prochain refroidissement.
  void _registerRateLimit() {
    final index = _rateLimitStrikes.clamp(0, _rateLimitBackoffs.length - 1);
    final backoff = _rateLimitBackoffs[index];
    _rateLimitStrikes++;
    _rateLimitUntil = DateTime.now().add(backoff);
    // Le refus porte sur le serveur, pas sur l'URL : les autres variantes
    // d'URL seront refusées identiquement, autant ne pas les payer.
    _rateLimitedOnLastAttempt = true;
    debugPrint(
      'Orbit3D 401 throttle: strike=$_rateLimitStrikes pause=${backoff.inSeconds}s',
    );
  }

  /// Attente le refroidissement en cours avant de repartir (borne à [_rateLimitUntil]).
  Future<void> _awaitRateLimitCooldown() async {
    final until = _rateLimitUntil;
    if (until == null) return;
    final wait = until.difference(DateTime.now());
    if (wait.isNegative || wait.inMilliseconds <= 0) return;
    debugPrint('Orbit3D throttle: attente ${wait.inMilliseconds}ms');
    await Future<void>.delayed(wait);
  }

  Future<bool> _tryPlay(int gen, String url) async {
    // Chaque tentative repart d'un état de refus neutre : le drapeau est
    // réarmé par `_registerRateLimit` si, et seulement si, ce nouvel essai
    // est lui aussi refusé.
    _rateLimitedOnLastAttempt = false;
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

    // Attendre que la session Cloudflare soit prete (cookie cf_clearance) avant
    // la premiere tentative. Meme rationale que dans _startAttempt : aucun cap
    // externe, le manager borne lui-meme ses tentatives.
    final cf = ref.read(cloudflareSessionProvider);
    if (!cf.isReady) {
      debugPrint('☁️ Waiting for Cloudflare session before first play...');
      await safeAsync(
        () => cf.initialize(baseUrl: _getPanelBaseUrl()),
        context: '_tryPlay cloudflareSession.initialize',
      );
    }

    final userAgentOrder = _userAgentOrder();
    // La config media3 est lue à la CONSTRUCTION de l'ExoPlayer : ce `push`
    // garantit que la relance applique bien le profil de l'appareil, même
    // appelée depuis un chemin qui n'a pas déjà poussé (_startAttempt, prewarm).
    // Sans effet si le profil est inchangé (dedup dans PlayerProfileService).
    await PlayerProfileService.pushForDevice(
      ref.read(deviceProfileProvider),
    );
    VideoPlayerController createController(String url, int agentIndex) {
      if (widget.isLocalFile) {
        // Pour les fichiers locaux, utiliser `VideoPlayerController.file`.
        // Le chemin peut être absolu ou un URI `file://`.
        final filePath = widget.streamUrl.startsWith('file://')
            ? widget.streamUrl.substring(7)
            : widget.streamUrl;
        return VideoPlayerController.file(
          File(filePath),
          videoPlayerOptions: _exclusivePlayback,
        );
      }
      // Pour les flux réseau, utiliser `VideoPlayerController.networkUrl`.
      final headers = _resolvedHeaders(url, agentIndex);
      if (widget.headers != null) {
        headers.addAll(widget.headers!);
      }
      return VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
        videoPlayerOptions: _exclusivePlayback,
      );
    }

    for (final agentIndex in userAgentOrder) {
      // Laisse un intervalle entre deux essais : marteler le panneau IPTV
      // déclenche son anti-leech (401 « indisponible » temporaire).
      if (agentIndex != userAgentOrder.first) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted || gen != _generation) return false;
      }
      final controller = createController(url, agentIndex);
      _controller = controller;
      controller.addListener(_onControllerUpdate);
      _appliedAudioPref = false;
      final initResult = await safeAsync(
        () => controller.initialize().timeout(_probTimeout),
        context: '_tryPlay controller.initialize',
      );
      if (initResult.isFailure) {
        debugPrint('Orbit3D video error ($url): ${initResult.errorOrNull}');
        if (host.isNotEmpty) {
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
        if (_isRateLimitedError(initResult.errorOrNull)) {
          _registerRateLimit();
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
      _rateLimitStrikes = 0;
      _rateLimitUntil = null;
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
    // Nouvelle tentative tant que la position initiale n'a pas été appliquée
    // (la durée peut n'attendre qu'après le chargement des métadonnées).
    if (!_hasAppliedInitialPosition && widget.initialPositionMs != null) {
      _applyInitialPosition();
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
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    _lastErrorDescription = controller.value.errorDescription;
    _handleActiveError();
  }

  /// Ré-applique la piste audio choisie précédemment pour ce contenu
  /// (préférence mémorisée via [PlayerTrackPrefs]). Best-effort.
  /// Gère aussi les préférences au niveau série (langue forcée pour tous les épisodes).
  Future<void> _applySavedAudioTrack(VideoPlayerController controller) async {
    final mediaKey = widget.progressId ?? widget.streamUrl;
    await safeAsync(
      () async {
        // 1. Préférence spécifique à cet épisode/flux
        final pref = await PlayerTrackPrefs.audioTrackFor(mediaKey);
        if (pref != null && pref.isEmpty) return;

        if (!mounted || _controller != controller) return;
        final tracks = await controller.getAudioTracks();
        if (tracks.isEmpty) return;

        // 2. Si c'est un épisode de série, vérifier la préférence série
        String? trackIdToApply = pref;
        if (trackIdToApply == null &&
            widget.series != null &&
            widget.episode != null) {
          final seriesId = widget.series!.id;
          final forced = await PlayerTrackPrefs.isSeriesAudioForced(seriesId);
          final lang = await PlayerTrackPrefs.seriesAudioLanguageFor(seriesId);
          if (lang != null && lang.isNotEmpty) {
            // Chercher une piste correspondant à la langue
            final matchingTrack = tracks.firstWhereOrNull(
              (t) =>
                  t.language != null &&
                  t.language!.toLowerCase() == lang.toLowerCase(),
            );
            if (matchingTrack != null) {
              trackIdToApply = matchingTrack.id;
            } else if (!forced) {
              // Si pas forcé et langue pas trouvée, on ne fait rien (langue par défaut du flux)
              return;
            }
            // Si forcé mais langue pas trouvée, on ne force pas (évite silence)
          }
        }

        if (trackIdToApply == null) return;
        if (!mounted || _controller != controller) return;
        final known = tracks.any((t) => t.id == trackIdToApply);
        if (!known) return;
        await controller.selectAudioTrack(trackIdToApply);
      },
      context: '_applySavedAudioTrack',
    );
  }

  /// Applique, UNE fois par contenu, la langue de sous-titres choisie pour la
  /// série à laquelle appartient l'épisode en cours.
  ///
  /// Les pistes intégrées arrivant par vagues, cette méthode est appelée à
  /// chaque découverte : tant qu'aucune piste ne correspond à la langue choisie,
  /// elle ne marque rien — une vague ultérieure peut l'apporter. Dès qu'elle
  /// applique, elle mémorise la génération pour ne plus reprendre la main sur la
  /// sélection (éventuellement manuelle) de l'utilisateur.
  Future<void> _applySeriesSubtitlePreference(
    SubtitleController ctrl,
    int generation,
  ) async {
    if (widget.series == null || widget.episode == null) return;
    if (_appliedSeriesSubtitleGeneration == generation) return;

    final seriesId = widget.series!.id;
    // La préférence est soit un code langue (« fr », formats historiques), soit
    // le libellé d'une piste (« Français (SDH) », choix « une entrée par
    // piste ») : le sélecteur tranche (cf. pickEmbeddedSubtitleTrackForPreference).
    final preference =
        await PlayerTrackPrefs.seriesSubtitleLanguageFor(seriesId);
    if (preference == null || preference.isEmpty) return;
    if (!mounted || generation != _generation) return;

    final track = pickEmbeddedSubtitleTrackForPreference(
      ctrl.embeddedTracks,
      preference,
    );
    if (track == null) {
      // Pas de sous-titre correspondante ou sélection "aucun" : forcer
      // la désactivation au lieu de laisser le flux appliquer sa piste par défaut.
      ctrl.disable();
      return;
    }

    await ctrl.selectEmbeddedTrack(track.id);
    if (!mounted || generation != _generation) return;
    _appliedSeriesSubtitleGeneration = generation;
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
    _embeddedScanTimer?.cancel();
    _embeddedScanController = controller;
    // Chaque lecteur repart d'un état neuf : c'est ce qui autorise la première
    // sonde à conclure « ce contenu n'a pas de piste intégrée » — décision
    // légitime ici, illegitimate plus tard (cf. [_discoverEmbeddedSubtitles]).
    _embeddedSig = kEmbeddedSigUnset;
    const period = Duration(seconds: 1);
    const deadline = Duration(seconds: 60);
    var elapsed = Duration.zero;
    _embeddedScanTimer = Timer.periodic(period, (timer) {
      if (!mounted || _controller != controller) {
        timer.cancel();
        _embeddedScanTimer = null;
        return;
      }
      elapsed += period;
      unawaited(_discoverEmbeddedSubtitles(controller));
      if (elapsed >= deadline) {
        timer.cancel();
        _embeddedScanTimer = null;
      }
    });
    unawaited(_discoverEmbeddedSubtitles(controller));
  }

  /// Sonde les sous-titres intégrés du flux et les expose au contrôleur.
  ///
  /// Best-effort : un échec du canal natif (ou une absence de pistes) ne doit
  /// jamais perturber la lecture.
  ///
  /// ## Trois garde-fous, chacun mesurable
  ///
  /// 1. **Réponse périmée ignorée.** La sonde capture `_generation` et
  ///    l'identifiant du lecteur. Un changement de source entre l'appel et la
  ///    réponse (zapping, préchauffage, bascule de chaîne) invalide le résultat :
  ///    sans ce contrôle, une liste non vide venue de l'ANCIEN lecteur
  ///    remplacerait les pistes du nouveau — l'erreur inverse de celle
  ///    corrigée, et tout aussi silencieuse.
  /// 2. **Liste vide non destructive.** Media3 reconstruit ses groupes à chaque
  ///    adaptation du flux : entre deux `onTracksChanged`, `getCurrentTracks()`
  ///    peut rendre une liste vide alors que le contenu en contient six.
  ///    Propager cet état effaçait la section « Sous-titres intégrés » déjà
  ///    affichée — l'utilisateur voyait les pistes disparaître sans rien faire.
  /// 3. **Pas de mise à jour redondante.** Une signature identique n'est pas
  ///    repropagée : évite de notifier des reconstructions inutiles et de
  ///    voler la piste choisie par l'utilisateur.
  Future<void> _discoverEmbeddedSubtitles(
    VideoPlayerController controller,
  ) async {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) return;
    if (_embeddedScanRunning) return;
    _embeddedScanRunning = true;
    final ctrl = ref.read(subtitleControllerProvider);
    // Identité capturée AVANT l'appel asynchrone.
    final probeGeneration = _generation;
    final probeController = controller;
    try {
      final bridge = EmbeddedSubtitleBridge(embeddedPlayerId(controller));
      final tracks = await bridge.getTracks();
      if (!mounted) return;
      // (1) Réponse périmée : le lecteur ou la génération a changé pendant
      // l'appel. Elle ne décrit plus l'écran affiché.
      if (_controller != probeController) return;
      if (probeGeneration != _generation) return;
      if (!identical(_embeddedScanController, probeController)) return;
      // (2) Liste vide : seulement acceptable si rien n'a encore été vu pour
      // CE lecteur (cf. [shouldPropagateEmbeddedTracks]).
      if (!shouldPropagateEmbeddedTracks(
        tracks: tracks,
        previousSignature: _embeddedSig,
      )) {
        return;
      }
      // (3) Signature identique : rien à annoncer.
      final sig = embeddedTracksSignature(tracks);
      if (sig == _embeddedSig) return;
      _embeddedSig = sig;
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
      // Applique la langue de sous-titres choisie pour la série (une fois par
      // contenu). Les vagues suivantes peuvent l'apporter après coup : tant
      // qu'aucune piste ne correspond, la préférence reste « non appliquée ».
      await _applySeriesSubtitlePreference(ctrl, probeGeneration);
    } catch (_) {
      // Canal natif indisponible (lecture RTSP, plugin tiers…) : on ignore.
    } finally {
      _embeddedScanRunning = false;
    }
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

  Future<void> _handleActiveError() async {
    if (!mounted || _handlingError) return;
    final gen = _generation;
    _handlingError = true;
    _disposeActive();
    if (!mounted || gen != _generation) {
      _handlingError = false;
      return;
    }
    // `_controller` est maintenant null mais `_status` vaut encore `ready` :
    // le build construit `_ReadyPlayer(controller: player!)` et n'importe quel
    // rebuild (auto-masquage du footer ~5 s après un tap, listener du lecteur)
    // crashe sur le null-check tant que la reprise n'a pas abouti. On force
    // l'affichage « chargement » dès ici ; `_startAttempt` (ou `_setStatus`
    // error) prendra le relais ensuite.
    if (mounted) _setStatus(_PlayerStatus.loading);

    final errorDesc = _lastErrorDescription;
    final host = Uri.tryParse(_activeStreamUrl)?.host ?? '';
    final isProviderBlockError = isProviderBlock(errorDesc);

    // Enregistre l'échec dans le circuit breaker si c'est un blocage fournisseur
    if (isProviderBlockError && host.isNotEmpty) {
      ref.read(hostCircuitBreakerProvider).recordFailure(host);
    }

    if (!_autorecovered) {
      _autorecovered = true;
      _handlingError = false;
      // Première tentative de récupération : si c'est une erreur Cloudflare,
      // on ATTEND la fin du challenge avant de retenter (sinon le 2e essai
      // repart avec des cookies vides et échoue aussi — « ça marche au 2e
      // chargement »). Borné en durée : on ne bloque jamais la lecture.
      if (_isCloudflareError(errorDesc)) {
        debugPrint(
          '☁️ Cloudflare error detected, refreshing session before retry...',
        );
        final cf = ref.read(cloudflareSessionProvider);
        await safeAsync(
          () => cf.renewSession(),
          context: '_handleActiveError cloudflareSession.renewSession',
        );
        // Challenge en échec : on retente quand même avec les cookies
        // éventuellement présents ; l'UI proposera le bouton de relance
        // explicite si le flux reste bloqué.
      }
      if (!mounted || gen != _generation) return;
      _startAttempt();
      return;
    }
    _handlingError = false;
    _setStatus(_PlayerStatus.error);
  }

  void _goNext() {
    if (!_hasNext) {
      LoggerService.instance.info(
        'ZAPPING_BLOCKED next: hasNext=false index=$_index channels=${_channels.length}',
      );
      return;
    }
    LoggerService.instance.info('ZAPPING_START: cleaning caches before switch');
    _cachedNext = null;
    _cachedNextIndex = null;
    _cachedPrev = null;
    _cachedPrevIndex = null;
    _preloadTarget = null;
    LoggerService.instance.info('ZAPPING_START next channel');
    _showFooterBar();
    // `_switchTo` incremente `_generation` de facon synchrone avant son
    // premier `await`, donc un zapping rapide reste correctement ordonne :
    // chaque appel voit l'_index deja change et les appels obsoletes sont
    // abandonnes par la garde de generation.
    unawaited(_switchTo(_index + 1));
  }

  void _goPrevious() {
    if (!_hasPrevious) {
      LoggerService.instance.info(
        'ZAPPING_BLOCKED previous: hasPrevious=false index=$_index channels=${_channels.length}',
      );
      return;
    }
    LoggerService.instance.info('ZAPPING_START previous channel');
    _showFooterBar();
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
      LoggerService.instance.info(
        'ZAPPING_ABORT _switchTo: target=$target index=$_index channels=${_channels.length} mounted=$mounted',
      );
      return;
    }
    LoggerService.instance.info(
      'ZAPPING_SWITCH target=$target from=$_index gen=$_generation',
    );
    // Ordre important : INCREMENTER puis capturer. Dans l'ordre inverse
    // (capture puis increment), `gen` valait `_generation - 1` pour tout le
    // reste de l'execution : la garde `gen != _generation` apres le premier
    // `await` était donc VRAIE par construction et chaque bascule s'abandonnait
    // elle-meme — l'ancien lecteur etait pause puis libere, `_index` avancait,
    // `_controller` restait null : le zapping ne fonctionnait plus du tout.
    _generation++;
    final gen = _generation;
    _autorecovered = false;
    _handlingError = false;
    // Nouveau contenu (zapping) : la piste externe du flux précédent ne doit
    // pas continuer de s'afficher. Le contrôleur est partagé et le player
    // (re)joue le même média sur `_retry` : le reset n'a lieu qu'ici, au vrai
    // changement de contenu.
    ref.read(subtitleControllerProvider).resetForNewContent();
    // Invalidate EPG cache on zap to free memory
    ref.read(epgDataCacheProvider).invalidate();
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
    _appliedAudioPref = false;
    if (oldActive != null) {
      oldActive.removeListener(_onControllerUpdate);
      if (oldActive.value.isInitialized && !oldActive.value.hasError) {
        // `await` avant toute decision : tant que la commande plateforme n'est
        // pas passee, l'ancien decodeur audio tourne encore.
        await oldActive.pause();
        if (!mounted || gen != _generation) {
          LoggerService.instance.info(
            'ZAPPING_ABORT _switchTo (pause old): gen=$gen cur=$_generation',
          );
          // Un autre zapping a pris la main pendant l'attente : cet ancien
          // controleur n'appartient plus a personne. On ne le remet surtout
          // pas en cache, on le libere.
          _disposeController(oldActive);
          return;
        }
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
    if (!mounted || gen != _generation) {
      LoggerService.instance.info(
        'ZAPPING_ABORT _switchTo (post-pause guard): gen=$gen cur=$_generation',
      );
      return;
    }
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
      LoggerService.instance.info(
        'ZAPPING_SWITCH_DONE target=$_index (cached controller)',
      );
    } else {
      LoggerService.instance.info(
        'ZAPPING_SWITCH_COLD target=$_index -> _startAttempt',
      );
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
    LoggerService.instance.info('ZAPPING_PRELOAD start');
    final gen = _generation;
    if (!mounted || _channels.isEmpty) return;
    if (!ref.read(advancedSettingsProvider).zeroLagPrefetch) {
      LoggerService.instance.info('ZAPPING_PRELOAD blocked: zeroLagPrefetch=false');
      return;
    }
    final target = _index + 1;
    if (target >= _channels.length) return;
    if (_cachedNext != null || _preloadTarget == target) return;
    final channelUrl = _channels[target].streamUrl;
    if (!isLikelyStreamUrl(channelUrl)) return;
    _preloadTarget = target;
    // Préchargement relais : on passe par le proxy local si celui-ci est prêt
    // et que la chaîne cible est un candidat au relais.
    LoggerService.instance.info('ZAPPING_PRELOAD target=$target url=$channelUrl');
    final targetUrl = maybeRebaseThroughProxy(
      channelUrl,
      proxyReady: ref.read(rustProxyManagerProvider).isReady,
    );
    // Ne pas precharger pendant que la lecture courante se bat encore : le
    // panneau limite les connexions simultanees et un prechargement en echec
    // aggrave les 401 de la chaine en cours.
    // Precharger uniquement quand la lecture courante est CONFIRMEE en cours.
    // Sinon (controleur absent, pas encore initialise, ou fige) le
    // prechargement consomme le budget de connexions du panneau et affame le
    // flux en cours : on observait 4 x 401 en cascade toutes les 4 s pendant
    // que la position du flux principal restait bloquee.
    final current = _controller;
    if (current == null ||
        !current.value.isInitialized ||
        !current.value.isPlaying) {
      return;
    }
    for (final attempt in _userAgentOrder()) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(targetUrl),
        httpHeaders: _resolvedHeaders(targetUrl, attempt),
        videoPlayerOptions: _exclusivePlayback,
      );
      final initResult = await safeAsync(
        () => controller.initialize().timeout(_probTimeout),
        context: '_startPreload controller.initialize',
      );
      if (initResult.isFailure) {
        debugPrint('Orbit3D preload error: ${initResult.errorOrNull}');
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
    // Coupe le pont sous-titres intégrés de CE lecteur avant de libérer la
    // texture : le polling s'arrête et l'état est vidé sans toucher à un
    // éventuel autre lecteur (préchauffage).
    ref
        .read(subtitleControllerProvider)
        .detachEmbedded(embeddedPlayerId(controller));
    // Arrête le balayage s'il visait CE lecteur (le timer se neutralise sinon
    // au tick suivant, mais autant le libérer tout de suite).
    if (identical(_embeddedScanController, controller)) {
      _embeddedScanTimer?.cancel();
      _embeddedScanTimer = null;
      _embeddedScanController = null;
      // L'état appartient à CE lecteur : le libérer évite qu'une texture
      // suivante hérite des pistes de l'ancienne.
      _embeddedSig = kEmbeddedSigUnset;
    }
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

  /// Relance la lecture. Regarde l'etat Cloudflare avant de rejouer afin de ne
  /// pas repartir avec des cookies vides.
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
      _handlingError = false;
      _autorecovered = false;
      _disposeCachedNext();
      _disposeCachedPrev();

      // Leaving a subscription open: the cookie can be expired. We wait for the
      // headless challenge to finish instead of capping it, otherwise the
      // playback restarts without cookies and fails again.
      final sub = ref.read(activeSubscriptionProvider);
      if (sub != null && sub.type == SubscriptionType.xtream) {
        final cf = ref.read(cloudflareSessionProvider);
        if (!cf.isReady) {
          debugPrint('☁️ Waiting for Cloudflare session before retry...');
          if (mounted) _setStatus(_PlayerStatus.loading);
          await safeAsync(
            () => cf.initialize(baseUrl: _getPanelBaseUrl()),
            context: '_retry cloudflareSession.initialize',
          );
        }
      }

      _startAttempt();
      _startPreload();
    } finally {
      _retrying = false;
      if (mounted) setState(() {});
    }
  }

  /// `true` si on peut proposer le déblocage Cloudflare pour le flux courant.
  bool get _canCloudflare {
    final host = Uri.tryParse(_activeStreamUrl)?.host;
    if (host == null || host.isEmpty) return false;
    // Pour les abonnements Xtream, on assume Cloudflare (quasi systématique).
    final sub = ref.read(activeSubscriptionProvider);
    if (sub != null && sub.type == SubscriptionType.xtream) return true;
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

  Future<void> _recordHistory() async {
    await safeAsync(
      () async {
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
          // Also record to history service
          ref.read(historyServiceProvider).addEntry(
                'live',
                channel.name,
                channel.streamUrl,
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
          // Also record to history service
          ref.read(historyServiceProvider).addEntry(
                favorite.type.name,
                favorite.title,
                favorite.streamUrl.isEmpty
                    ? widget.streamUrl
                    : favorite.streamUrl,
              );
        }
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

  /// Applique une commande issue de la MediaSession native (notification,
  /// télécommande TV, casque Bluetooth). Le natif ne connaît pas l'état réel du
  /// lecteur : le traitement est donc idempotent (« play » alors qu'on joue
  /// déjà ne relance rien).
  void _handleRemoteCommand(String command) {
    if (!mounted) return;
    switch (command) {
      case 'play':
        {
          final controller = _controller;
          if (controller != null && !controller.value.isPlaying) {
            setState(() => controller.play());
            _syncImmersive();
          }
        }
      case 'pause':
        {
          final controller = _controller;
          if (controller != null && controller.value.isPlaying) {
            setState(() => controller.pause());
            _syncImmersive();
          }
        }
      case 'stop':
        {
          final controller = _controller;
          if (controller != null && controller.value.isPlaying) {
            setState(() => controller.pause());
            _syncImmersive();
          }
          _bgService.stop();
        }
      case 'next':
        _goNext();
      case 'previous':
        _goPrevious();
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    LoggerService.instance.info(
      'ZAPPING_KEY received: ${event.logicalKey.debugName} '
      '(hasFocus=${node.hasFocus})',
    );
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
    if (key == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _toggleFooter();
      return KeyEventResult.handled;
    }
    // Touches média émises par les télécommandes TV et les casques
    // Bluetooth : arrivées ici comme événements clavier tant que la
    // MediaSession native n'est pas active (app au premier plan). Une fois
    // la session active (arrière-plan), les mêmes intentions passent par le
    // MethodChannel « orbit/playback_service » (voir _handleRemoteCommand).
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaStop) {
      final controller = _controller;
      if (controller != null && controller.value.isPlaying) {
        setState(() => controller.pause());
        _bgService.stop();
        _syncImmersive();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      _goNext();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      _goPrevious();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
            padding: const EdgeInsets.all(16),
            child: switch (_status) {
              _PlayerStatus.loading => const VideoLoadingState(),
              _PlayerStatus.error => VideoErrorState(
                  title: isProviderBlock(_lastErrorDescription) ||
                          _isCloudflareError(_lastErrorDescription)
                      ? 'Flux verrouillé par le fournisseur'
                      : 'Flux indisponible',
                  message: isProviderBlock(_lastErrorDescription) ||
                          _isCloudflareError(_lastErrorDescription)
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
              _PlayerStatus.ready => player != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Focus(
                          autofocus: true,
                          onKeyEvent: (_, event) {
                            if (event is KeyDownEvent &&
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
                          child: _ReadyPlayer(
                            controller: player,
                            onTap: _showFooterBar,
                            streamUrl: _activeStreamUrl,
                            onRetry: _retry,
                          ),
                        ),
                        // Overlay sous-titres (au-dessus vidéo, sous footerbar)
                        //
                        // C'est l'overlay qui s'abonne à la position du lecteur :
                        // le passer en paramètre figeait le cue à l'instant du
                        // choix de la piste, et rien ne se rejouait ensuite.
                        Consumer(
                          builder: (_, ref, __) {
                            final subtitleCtrl =
                                ref.watch(subtitleControllerProvider);
                            // Les sous-titres intégrés passent d'abord : le
                            // rendu suit le flux du pipeline (polling 300 ms),
                            // alors que la piste externe est recalee sur la
                            // position.
                            if (subtitleCtrl.hasActiveEmbedded) {
                              return EmbeddedSubtitleOverlay(
                                cues: subtitleCtrl.liveEmbeddedCues,
                                bottomPadding: 100, // au-dessus footerbar
                              );
                            }
                            return VideoSubtitleOverlay(
                              controller: player,
                              track: subtitleCtrl.activeTrack,
                              bottomPadding: 100, // au-dessus footerbar
                            );
                          },
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
                    )
                  : const VideoLoadingState(),
            },
          ),
        ),
      ),
    );
  }

  /// Construit le contenu de la footerbar selon le type de contenu en cours.
  Widget _buildFooterContent(VideoPlayerController player) {
    final isPlaying = player.value.isPlaying;
    final castButton = CastButton(
      streamUrl: widget.streamUrl,
      isLive: widget.contentType == PlaybackContentType.live,
    );
    final streamDetails = _FooterStreamDetails(
      controller: player,
      mediaKey: widget.progressId ?? widget.streamUrl,
      onOpened: () => _footerTimer?.cancel(),
      onClosed: _showFooterBar,
    );
    final onPip = _pipSupported == true ? _enterPip : null;
    return switch (widget.contentType) {
      PlaybackContentType.live => _LiveFooterBar(
          channel: _currentChannel,
          fallbackTitle: widget.title ?? _currentChannel?.name ?? 'Live',
          index: _index,
          total: _channels.length,
          isPlaying: isPlaying,
          showSeek: false,
          onExit: _requestExit,
          onPrevious: _hasPrevious ? _goPrevious : null,
          onNext: _hasNext ? _goNext : null,
          onTogglePlayPause: _togglePlayPause,
          onPip: onPip,
          onSeekBack30: null,
          onSeekForward30: null,
          castButton: castButton,
          streamDetails: streamDetails,
          onToggleNightFocus: _toggleNightFocus,
          playPauseFocusNode: _footerPlayFocus,
        ),
      PlaybackContentType.replay => _LiveFooterBar(
          channel: _currentChannel,
          fallbackTitle: widget.title ?? 'Replay',
          subtitle: widget.subtitle,
          controller: player,
          index: _index,
          total: _channels.length,
          isPlaying: isPlaying,
          showSeek: true,
          onExit: _requestExit,
          onPrevious: _hasPrevious ? _goPrevious : null,
          onNext: _hasNext ? _goNext : null,
          onTogglePlayPause: _togglePlayPause,
          onPip: onPip,
          onSeekBack30: () => _seekBy(const Duration(seconds: -30)),
          onSeekForward30: () => _seekBy(const Duration(seconds: 30)),
          castButton: castButton,
          streamDetails: streamDetails,
          onToggleNightFocus: _toggleNightFocus,
          playPauseFocusNode: _footerPlayFocus,
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
          onExit: _requestExit,
          onTogglePlayPause: _togglePlayPause,
          onPip: onPip,
          onSeekBack30: () => _seekBy(const Duration(seconds: -30)),
          onSeekForward30: () => _seekBy(const Duration(seconds: 30)),
          castButton: castButton,
          streamDetails: streamDetails,
          onToggleNightFocus: _toggleNightFocus,
          playPauseFocusNode: _footerPlayFocus,
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
/// Wrappée dans [TvFocus] pour être navigable au D-pad sur TV.
Widget _fbIcon(
  IconData icon,
  VoidCallback? onPressed, {
  String? tooltip,
  Color color = Colors.white,
  double size = 22,
}) {
  final button = IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
    onPressed: onPressed,
    icon: Icon(icon, color: color, size: size),
  );
  if (onPressed == null) return button;
  return TvFocus(onActivate: onPressed, child: button);
}

/// Bouton pause/lecture proéminent de la footerbar.
/// Wrappé dans [TvFocus] pour être navigable au D-pad sur TV.
Widget _fbPlayPause({
  required bool isPlaying,
  required VoidCallback onPressed,
  FocusNode? focusNode,
}) {
  final button = IconButton(
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
  return TvFocus(onActivate: onPressed, focusNode: focusNode, child: button);
}

/// Icône Night Focus de la footerbar : l'icône et la couleur changent selon
/// l'état ON/OFF du maître (toggle direct, sans ouvrir de sous-menu).
/// Wrappée dans [TvFocus] pour être navigable au D-pad sur TV.
Widget _fbNightFocus({
  required VoidCallback onPressed,
  required WidgetRef ref,
}) {
  final enabled = ref.watch(
    advancedSettingsProvider.select((s) => s.nightFocusEnabled),
  );
  final button = IconButton(
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
  return TvFocus(onActivate: onPressed, child: button);
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
/// Footerbar Live / Replay : nom de chaîne + #numéro + EPG (titre/horaires
/// + progression du programme) puis actions (zapping, pause/play, seek si
/// replay, menu détails du flux, Night Focus, retour).
class _LiveFooterBar extends ConsumerWidget {
  const _LiveFooterBar({
    required this.channel,
    required this.fallbackTitle,
    this.subtitle,
    this.controller,
    required this.index,
    required this.total,
    required this.isPlaying,
    required this.showSeek,
    required this.onExit,
    this.onPrevious,
    this.onNext,
    required this.onTogglePlayPause,
    this.onPip,
    this.onSeekBack30,
    this.onSeekForward30,
    this.castButton,
    required this.streamDetails,
    required this.onToggleNightFocus,
    this.playPauseFocusNode,
  });

  final Channel? channel;
  final String fallbackTitle;
  final String? subtitle;
  final VideoPlayerController? controller;
  final int index;
  final int total;
  final bool isPlaying;
  final bool showSeek;
  final VoidCallback onExit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onTogglePlayPause;
  final VoidCallback? onPip;
  final VoidCallback? onSeekBack30;
  final VoidCallback? onSeekForward30;
  final Widget? castButton;
  final _FooterStreamDetails streamDetails;
  final VoidCallback onToggleNightFocus;
  final FocusNode? playPauseFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final currentChannel = channel;
    final epgAsync = currentChannel != null
        ? ref.watch(channelEpgProvider(currentChannel.primaryEpgChannelId))
        : null;
    final (nowProgram, nextProgram) = currentChannel != null && epgAsync != null
        ? _nowAndNext(epgAsync.value ?? const [])
        : (null, null);
    final channelName = currentChannel?.name ?? fallbackTitle;
    final canZap = total > 1;
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
          TimeProgressBar(
            controller: player,
            allowScrubbing: true,
          ),
        ],
        const SizedBox(height: 10),
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: [
              _fbIcon(Icons.arrow_back_rounded, onExit, tooltip: 'Retour'),
              const Spacer(),
              if (onPrevious != null)
                _fbIcon(
                  Icons.skip_previous_rounded,
                  onPrevious,
                  tooltip: l.previousChannel,
                ),
              if (showSeek)
                _fbIcon(
                  Icons.replay_30,
                  onSeekBack30,
                  tooltip: l.rewind30s,
                  color: Colors.white,
                ),
              _fbPlayPause(
                isPlaying: isPlaying,
                onPressed: onTogglePlayPause,
                focusNode: playPauseFocusNode,
              ),
              if (showSeek) ...[
                _fbIcon(
                  Icons.forward_30,
                  onSeekForward30,
                  tooltip: l.forward30s,
                  color: Colors.white,
                ),
              ],
              if (onNext != null)
                _fbIcon(
                  Icons.skip_next_rounded,
                  onNext,
                  tooltip: l.nextChannel,
                ),
              const SizedBox(width: 8),
              _fbNightFocus(onPressed: onToggleNightFocus, ref: ref),
              if (onPip != null)
                _fbIcon(
                  Icons.picture_in_picture_alt_rounded,
                  onPip,
                  tooltip: l.pip,
                ),
              if (castButton != null) castButton!,
              streamDetails,
            ],
          ),
        ),
      ],
    );
  }
}

/// Footerbar VOD / Séries : titre + note ★ + genre (+ épisode), barre de
/// progression de lecture puis 2x retour / play-pause / 2x avance, et menu
/// détails du flux / Night Focus.
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
    required this.onExit,
    required this.onTogglePlayPause,
    required this.onSeekBack30,
    required this.onSeekForward30,
    this.onPip,
    this.castButton,
    required this.streamDetails,
    required this.onToggleNightFocus,
    this.playPauseFocusNode,
  });

  final VideoPlayerController controller;
  final String title;
  final double? rating;
  final String? genre;
  final String? subtitle;
  final String? seriesName;
  final String? episodeLabel;
  final bool isPlaying;
  final VoidCallback onExit;
  final VoidCallback onTogglePlayPause;
  final VoidCallback? onPip;
  final VoidCallback onSeekBack30;
  final VoidCallback onSeekForward30;
  final Widget? castButton;
  final _FooterStreamDetails streamDetails;
  final VoidCallback onToggleNightFocus;
  final FocusNode? playPauseFocusNode;

  String? get _subLine {
    if (seriesName != null && episodeLabel != null) {
      return '$seriesName · $episodeLabel';
    }
    return episodeLabel ??
        (subtitle != null && subtitle!.isNotEmpty ? subtitle : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
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
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFFFC107),
              ),
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
        TimeProgressBar(
          controller: controller,
          allowScrubbing: true,
        ),
        const SizedBox(height: 8),
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: [
              _fbIcon(Icons.arrow_back_rounded, onExit, tooltip: 'Retour'),
              const Spacer(),
              _fbIcon(
                Icons.replay_30,
                onSeekBack30,
                tooltip: l.rewind30s,
                color: Colors.white,
              ),
              _fbPlayPause(
                isPlaying: isPlaying,
                onPressed: onTogglePlayPause,
                focusNode: playPauseFocusNode,
              ),
              _fbIcon(
                Icons.forward_30,
                onSeekForward30,
                tooltip: l.forward30s,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              _fbNightFocus(onPressed: onToggleNightFocus, ref: ref),
              if (onPip != null)
                _fbIcon(
                  Icons.picture_in_picture_alt_rounded,
                  onPip,
                  tooltip: l.pip,
                ),
              if (castButton != null) castButton!,
              streamDetails,
            ],
          ),
        ),
      ],
    );
  }
}

/// Icône ⚙️ de la footerbar : ouvre le panneau « Détails du flux » (pistes
/// audio / qualité vidéo / sous-titres).
///
/// Tant que la sous-fenêtre est ouverte on gèle le timer d'auto-masquage (via
/// [onOpened]) et on le relance à la fermeture ([onClosed]).
class _FooterStreamDetails extends StatelessWidget {
  const _FooterStreamDetails({
    required this.controller,
    required this.mediaKey,
    required this.onOpened,
    required this.onClosed,
  });

  final VideoPlayerController controller;
  final String? mediaKey;
  final VoidCallback onOpened;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void open() async {
      onOpened();
      await showStreamDetailsSheet(context, controller, mediaKey ?? '');
      if (context.mounted) onClosed();
    }

    final button = IconButton(
      tooltip: l.streamDetails,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      onPressed: open,
      icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
    );
    return TvFocus(onActivate: open, child: button);
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

(EPGProgram?, EPGProgram?) _nowAndNext(List<EPGProgram> programs) =>
    epgCurrentAndNext(programs, DateTime.now());

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
      setState(() {
        _showBuffering = isBuffering;
      });
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
