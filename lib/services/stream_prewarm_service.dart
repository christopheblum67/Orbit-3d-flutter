import 'package:video_player/video_player.dart';

/// Petit réservoir de [VideoPlayerController] pré-initialisés, sans lecture,
/// pour accélérer le premier démarrage d'une chaîne et le zapping.
///
/// La vue Live TV préchauffe la chaîne focalisée ou tapée ; l'écran de
/// lecture récupère le contrôleur via [take] (transfert de propriété) au
/// lieu de tout re-créer à froid.
class StreamPrewarmService {
  StreamPrewarmService._();

  static final StreamPrewarmService instance = StreamPrewarmService._();

  static const int _maxEntries = 2;
  static const Duration _initTimeout = Duration(seconds: 12);

  final Map<String, VideoPlayerController> _pool = {};
  VideoPlayerController? _inflight;
  String? _inflightUrl;

  bool get isEmpty => _pool.isEmpty && _inflight == null;

  void prewarm(String url, Map<String, String> httpHeaders) {
    if (url.isEmpty) return;
    if (_pool.containsKey(url) || _inflightUrl == url) return;
    _evictIfNeeded();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: httpHeaders,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    _inflight = controller;
    _inflightUrl = url;
    // Pas de lecture : on pré-initialise seulement pour enlever le temps de
    // démarrage à froid. Les erreurs passent inaperçues côté grille.
    controller.initialize().timeout(_initTimeout).then(
      (_) {
        if (!identical(_inflight, controller)) {
          // Propriété reprise (zapping) ou remplacée : on libère.
          controller.dispose();
          return;
        }
        _inflight = null;
        _inflightUrl = null;
        if (controller.value.hasError) {
          controller.dispose();
        } else {
          controller.pause();
          if (_pool.length >= _maxEntries) _disposeOldest();
          _pool[url] = controller;
        }
      },
      onError: (Object _) {
        if (identical(_inflight, controller)) {
          _inflight = null;
          _inflightUrl = null;
        }
        controller.dispose();
      },
    );
  }

  /// Récupère (et retire) le contrôleur préchauffé pour [url], en
  /// transférant la propriété à l'appelant. Les autres entrées du réservoir
  /// sont libérées : l'écran de lecture prend la main sur le streaming.
  VideoPlayerController? take(String url) {
    final ready = _pool.remove(url);
    // Un préchauffage en cours est annulé : le callback .then/onError se
    // charge de disposer, évitant ainsi tout double dispose.
    _inflight = null;
    _inflightUrl = null;
    for (final entry in _pool.values.toList()) {
      if (!identical(entry, ready)) entry.dispose();
    }
    _pool.clear();
    return ready;
  }

  void clear() {
    _inflight = null;
    _inflightUrl = null;
    for (final entry in _pool.values.toList()) {
      entry.dispose();
    }
    _pool.clear();
  }

  void _evictIfNeeded() {
    if (_pool.length < _maxEntries) return;
    _disposeOldest();
  }

  void _disposeOldest() {
    if (_pool.isEmpty) return;
    final firstKey = _pool.keys.first;
    _pool.remove(firstKey)?.dispose();
  }
}
