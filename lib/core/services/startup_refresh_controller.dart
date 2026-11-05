import 'dart:async';
import 'package:orbit_3d_flutter/services/catalog_disk_cache.dart';
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
  })  : _epgCache = epgCache,
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
  final Future<List<Channel>> Function() _loadLiveChannels;
  final Future<List<Movie>> Function() _loadMovies;
  final Future<List<Series>> Function() _loadSeries;
  final Future<List<Channel>> Function() _loadRadioChannels;

  List<Movie> movies = const [];
  List<Series> series = const [];

  /// Avec un cache disque frais, aucun appel réseau n'est nécessaire : le
  /// démarrage n'attend pas le décodage des ~130 000 titres (lourd sur TV).
  /// Les écrans Films/Séries affichent « Chargement… » le temps que le
  /// provider finisse en arrière-plan.
  Future<bool> _canDeferCatalog(String kind) async {
    if (bypassCatalogCache) return false;
    final key = await _api.resolveSubscriptionCacheKey();
    return key != null && await CatalogDiskCache.instance.hasFresh(kind, key);
  }

  final List<Future<Object?> Function()> _deferred = [];

  void _deferInBackground(Future<Object?> Function() load) =>
      _deferred.add(load);

  /// Lance les catalogues différés une fois les étapes bloquantes terminées,
  /// pour ne pas se disputer le CPU avec l'accueil.
  void _startDeferred() {
    for (final load in _deferred) {
      unawaited(load().then((_) {}, onError: (_) {}));
    }
    _deferred.clear();
  }

  Future<void> start() {
    // Séquencement STRICT (voir [RefreshStepsController.run]) : les étapes
    // s'exécutent une à une. En lançant tout en parallèle (catalogues + EPG +
    // sondages replay), on fait saturer le rate-limit (429) du panel et
    // l'ENSEMBLE échoue (catégories/flux indisponibles à l'arrivée).
    return run((step) async {
      switch (step) {
        case StartupStep.live:
          await _loadLiveChannels();
        case StartupStep.movies:
          if (await _canDeferCatalog('vod')) {
            _deferInBackground(_loadMovies);
          } else {
            movies = await _loadMovies();
          }
        case StartupStep.series:
          if (await _canDeferCatalog('series')) {
            _deferInBackground(_loadSeries);
          } else {
            series = await _loadSeries();
          }
        case StartupStep.radio:
          if (bypassCatalogCache) {
            await _loadRadioChannels();
          } else {
            _deferInBackground(_loadRadioChannels);
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
          // Précharge le guide dans le cache partagé, une seule fois : la grille
          // EPG l'utilise ensuite sans re-télécharger le XMLTV.
          final cache = _epgCache;
          if (cache != null) {
            await cache.loadFull(_api);
          } else {
            await _api.fetchEpg();
          }
        case StartupStep.ai:
          // Étape purement indicative : marquée instantanément comme faite pour
          // que la progression reste fluide sans latence.
          break;
      }
    }).whenComplete(_startDeferred);
  }
}
