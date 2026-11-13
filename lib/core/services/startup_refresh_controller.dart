import 'dart:async';
import 'package:orbit_3d_flutter/core/services/playback_refresh_gate.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/services/catalog_disk_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_fetch_service.dart';
import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

// L'enum et la comptabilité de progression vivent désormais dans
// `refresh_steps_controller.dart` (partagés avec le rafraîchissement à la
// demande). On ré-exporte `StartupStep` pour ne pas casser les imports
// existants qui font `show StartupStep`.
export 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart'
    show StartupStep;

/// Contrôleur des phases de chargement au démarrage. Les étapes sont exécutées
/// séquentiellement et peuvent être séparées autour de la sélection du profil.
///
/// La mécanique de progression (%, étape courante, étapes faites) est héritée
/// de [RefreshStepsController] : l'écran de démarrage et le rafraîchissement à
/// la demande partagent donc exactement le même affichage.
class StartupRefreshController extends RefreshStepsController {
  static bool get bypassCatalogCache => ApiService.bypassCatalogCache;

  static const initialSteps = {
    StartupStep.live,
    StartupStep.movies,
    StartupStep.series,
    StartupStep.epg,
    StartupStep.radio,
  };

  static const remainingSteps = <StartupStep>{};

  StartupRefreshController(
    this._api, {
    required Future<List<Channel>> Function() loadLiveChannels,
    required Future<List<Movie>> Function() loadMovies,
    required Future<List<Series>> Function() loadSeries,
    required Future<List<Channel>> Function() loadRadioChannels,
    Set<StartupStep>? steps,
    EPGDataCache? epgCache,
    bool Function()? deferredStillValid,
    PlaybackRefreshGate? playbackGate,
  })  : _epgCache = epgCache,
        _deferredStillValid = deferredStillValid,
        _playbackGate = playbackGate ?? PlaybackRefreshGate.instance,
        _loadLiveChannels = loadLiveChannels,
        _loadMovies = loadMovies,
        _loadSeries = loadSeries,
        _loadRadioChannels = loadRadioChannels,
        super(
          steps: steps ??
              {
                StartupStep.live,
                StartupStep.movies,
                StartupStep.series,
                StartupStep.radio,
                StartupStep.replay,
                StartupStep.epg,
                StartupStep.ai,
              },
        );

  final ApiService _api;
  final EPGDataCache? _epgCache;
  final bool Function()? _deferredStillValid;
  final PlaybackRefreshGate _playbackGate;
  final Future<List<Channel>> Function() _loadLiveChannels;
  final Future<List<Movie>> Function() _loadMovies;
  final Future<List<Series>> Function() _loadSeries;
  final Future<List<Channel>> Function() _loadRadioChannels;

  List<Movie> movies = const [];
  List<Series> series = const [];
  bool hasCatalogData = false;

  /// Avec un cache disque frais, aucun appel réseau n'est nécessaire : le
  /// démarrage n'attend pas le décodage des ~130 000 titres (lourd sur TV).
  /// Les écrans Films/Séries affichent « Chargement… » le temps que le
  /// provider finisse en arrière-plan.
  Future<bool> _canDeferCatalog(String kind) async {
    if (bypassCatalogCache) return false;
    final key = await _api.resolveSubscriptionCacheKey();
    return key != null &&
        await CatalogDiskCache.instance.hasFresh(kind, key,
            maxAgeLimit: CatalogFetchService.maxStaleAge);
  }

  final List<({String kind, Future<Object?> Function() load})> _deferred = [];

  void _deferInBackground(String kind, Future<Object?> Function() load) {
    logDiag('CATALOG kind=$kind step=deferred state=queued');
    _deferred.add((kind: kind, load: load));
  }

  /// Lance les catalogues différés un par un, avec une pause entre chacun :
  /// décoder ~130 000 titres d'un coup monopolise le CPU et retarde l'écran de
  /// choix du profil. Chaque tâche cède la main au moteur avant la suivante.
  void _startDeferred() {
    final pending = List.of(_deferred);
    _deferred.clear();
    if (pending.isEmpty) return;
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      for (final item in pending) {
        await _playbackGate.waitUntilIdle();
        if (_deferredStillValid?.call() == false) return;
        try {
          await traceCatalogStep(item.kind, 'deferred', item.load);
          if (item.kind == 'epg' && _deferredStillValid?.call() != false) {
            _epgCache?.onRevalidated?.call();
          }
        } catch (_) {
          if (item.kind == 'epg') {
            await Future<void>.delayed(const Duration(seconds: 5));
            await _playbackGate.waitUntilIdle();
            if (_deferredStillValid?.call() == false) return;
            try {
              await traceCatalogStep(item.kind, 'retry', item.load);
              if (_deferredStillValid?.call() != false) {
                _epgCache?.onRevalidated?.call();
              }
            } catch (_) {
              // traceCatalogStep records the failure without exposing its contents.
            }
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }());
  }

  Future<void> start() {
    // Séquencement STRICT (voir [RefreshStepsController.run]) : les étapes
    // s'exécutent une à une. En lançant tout en parallèle (catalogues + EPG +
    // sondages replay), on fait saturer le rate-limit (429) du panel et
    // l'ENSEMBLE échoue (catégories/flux indisponibles à l'arrivée).
    final startupWatch = Stopwatch()..start();
    return run((step) async {
      final stepWatch = Stopwatch()..start();
      try {
        await _runStep(step);
      } finally {
        logDiag(
          'STARTUP step=${step.name} durationMs=${stepWatch.elapsedMilliseconds} '
          'sinceStartMs=${startupWatch.elapsedMilliseconds} '
          'deferredQueue=${_deferred.length}',
        );
      }
    }).whenComplete(() {
      logDiag('STARTUP total=${startupWatch.elapsedMilliseconds}ms');
      _startDeferred();
    });
  }

  Future<void> _runStep(StartupStep step) {
    return () async {
      switch (step) {
        case StartupStep.live:
          hasCatalogData = (await _loadLiveChannels()).isNotEmpty;
        case StartupStep.movies:
          if (await _canDeferCatalog('vod')) {
            hasCatalogData = true;
            _deferInBackground('vod', _loadMovies);
          } else {
            movies = await _loadMovies();
            hasCatalogData = hasCatalogData || movies.isNotEmpty;
          }
        case StartupStep.series:
          if (await _canDeferCatalog('series')) {
            hasCatalogData = true;
            _deferInBackground('series', _loadSeries);
          } else {
            series = await _loadSeries();
            hasCatalogData = hasCatalogData || series.isNotEmpty;
          }
        case StartupStep.radio:
          if (bypassCatalogCache) {
            await _loadRadioChannels();
          } else {
            _deferInBackground('radio', _loadRadioChannels);
          }
        case StartupStep.replay:
          // Aucun appel. Le Replay se charge chaîne par chaîne, à la demande,
          // quand l'utilisateur ouvre une chaîne (voir `channelReplaysProvider`).
          //
          // Cet appel sondait 40 chaînes au DÉMARRAGE : le panel répondait 429,
          // et la tempête hammering qui suivait faisait échouer l'EPG, les Films
          // et le Live TV au même moment. Le Replay était la cause de pannes
          // générales, pour un écran que presque personne n'ouvre.
          break;
        case StartupStep.epg:
          // Le guide ne doit jamais retarder le choix du profil, même sans cache.
          final cache = _epgCache;
          _deferInBackground(
            'epg',
            cache == null ? _api.fetchEpg : () => cache.loadFull(_api),
          );
        case StartupStep.ai:
          // Étape purement indicative : marquée instantanément comme faite pour
          // que la progression reste fluide sans latence.
          break;
      }
    }();
  }
}
