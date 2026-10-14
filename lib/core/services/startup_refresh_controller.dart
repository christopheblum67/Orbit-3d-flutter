import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
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

/// Contrôleur de l'écran de démarrage : régénère tous les flux en parallèle
/// et expose une progression en %, ainsi que les contenus récupérés qui
/// serviront aux recommandations personnalisées.
///
/// La mécanique de progression (%, étape courante, étapes faites) est héritée
/// de [RefreshStepsController] : l'écran de démarrage et le rafraîchissement à
/// la demande partagent donc exactement le même affichage.
class StartupRefreshController extends RefreshStepsController {
  StartupRefreshController(
    this._api, {
    Set<StartupStep>? steps,
    EPGDataCache? epgCache,
  })  : _epgCache = epgCache,
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

  List<Movie> movies = const [];
  List<Series> series = const [];

  Future<void> start() {
    // Séquencement STRICT (voir [RefreshStepsController.run]) : les étapes
    // s'exécutent une à une. En lançant tout en parallèle (catalogues + EPG +
    // sondages replay), on fait saturer le rate-limit (429) du panel et
    // l'ENSEMBLE échoue (catégories/flux indisponibles à l'arrivée).
    return run((step) async {
      switch (step) {
        case StartupStep.live:
          await _api.fetchLiveChannels();
        case StartupStep.movies:
          final list = await _api.fetchMovies();
          movies = list;
        case StartupStep.series:
          final list = await _api.fetchSeries();
          series = list;
        case StartupStep.radio:
          await _api.fetchRadioChannels();
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
    });
  }
}
