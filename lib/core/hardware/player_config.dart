import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Paramètres media3 appliqués au lecteur natif (fork video_player_android)
/// via le canal « orbit/player_config », lus au moment de la construction de
/// l'ExoPlayer (DefaultLoadControl + limite de hauteur via TrackSelector).
class Media3PlaybackProfile {
  const Media3PlaybackProfile({
    required this.minBufferMs,
    required this.maxBufferMs,
    required this.bufferForPlaybackMs,
    required this.bufferForPlaybackAfterRebufferMs,
    this.maxVideoWidth = 0,
    this.maxVideoHeight = 0,
  });

  final int minBufferMs;
  final int maxBufferMs;
  final int bufferForPlaybackMs;
  final int bufferForPlaybackAfterRebufferMs;

  /// 0 = aucune contrainte de piste vidéo (résolution native autorisée).
  final int maxVideoWidth;
  final int maxVideoHeight;

  bool get hasLoadControl => minBufferMs > 0 && maxBufferMs > 0;
  bool get hasVideoCap => maxVideoHeight > 0;

  static const Media3PlaybackProfile unset = Media3PlaybackProfile(
    minBufferMs: 0,
    maxBufferMs: 0,
    bufferForPlaybackMs: 0,
    bufferForPlaybackAfterRebufferMs: 0,
  );

  /// Mapping profil de l'appareil -> réglages media3.
  ///
  /// Media3 impose `minBufferMs >= bufferForPlaybackMs` et
  /// `minBufferMs >= bufferForPlaybackAfterRebufferMs` (sinon
  /// `IllegalArgumentException: minBufferMs cannot be less than
  /// bufferForPlaybackMs`, qui fait échouer toute la lecture). Les valeurs
  /// ci-dessous respectent ces bornes.
  ///
  /// - Eco : tampon long (8 s) pour les appareils faiblement dotés, plafonné
  ///   à 1080p (les flux 4K satureraient le décodage).
  /// - Standard : tampon intermédiaire (4 s), rendu 3D et multi-vue X2.
  /// - Ultra : tampon court (1,5 s) pour un zapping immédiat, 4K HDR possible.
  ///
  /// `bufferForPlaybackMs` est le **seul** réglage qui gouverne la latence de
  /// démarrage à froid : Media3 ne fait passer le player en `STATE_READY` qu'une
  /// fois ce volume de données téléchargé. Les anciennes valeurs (15 s / 8 s)
  /// rendaient le zapping à froid inutilisable — 15 s d'attente avant la
  /// première image. On garde un minimum de 1,2 s : en dessous, un flux
  /// instable (Wi-Fi domestique, 4G) reboucle sans arrêt.
  static Media3PlaybackProfile forProfile(DeviceProfile profile) {
    return switch (profile) {
      DeviceProfile.eco => const Media3PlaybackProfile(
          minBufferMs: 8000,
          maxBufferMs: 40000,
          bufferForPlaybackMs: 2500,
          bufferForPlaybackAfterRebufferMs: 4000,
          maxVideoHeight: 1080,
        ),
      DeviceProfile.standard => const Media3PlaybackProfile(
          minBufferMs: 4000,
          maxBufferMs: 25000,
          bufferForPlaybackMs: 1500,
          bufferForPlaybackAfterRebufferMs: 2500,
        ),
      DeviceProfile.ultra => const Media3PlaybackProfile(
          minBufferMs: 1500,
          maxBufferMs: 10000,
          bufferForPlaybackMs: 800,
          bufferForPlaybackAfterRebufferMs: 1200,
          // Plafond à 1440p, malgré le nom du profil. Sans plafond, ExoPlayer
          // négocie une piste 4K (3840×2160) sur des sources IPTV HEVC dont le
          // décodage dépasse ce que le matériel sustained : le tampon se
          // remplissait (28 s relevés) et la position restait bloquée à 0 s, ce
          // qui se manifestait comme une fausse « connexion instable » alors
          // que le flux arrivait très bien. 1440p passe sans saccade sur les
          // appareils de cette gamme.
          maxVideoHeight: 1440,
        ),
    };
  }

  Map<String, Object?> toMethodArguments() => {
        'minBufferMs': minBufferMs,
        'maxBufferMs': maxBufferMs,
        'bufferForPlaybackMs': bufferForPlaybackMs,
        'bufferForPlaybackAfterRebufferMs': bufferForPlaybackAfterRebufferMs,
        'maxVideoWidth': maxVideoWidth,
        'maxVideoHeight': maxVideoHeight,
      };
}

/// Pont Dart -> natif de la configuration de lecture par profil.
///
/// Doit être appelé AVANT la création d'un [VideoPlayerController] pour être
/// pris en compte à la construction de l'ExoPlayer (même principe que
/// NightFocusAudioService).
class PlayerProfileService {
  PlayerProfileService._();

  static const MethodChannel _channel = MethodChannel('orbit/player_config');

  /// Dernier profil réellement transmis : évite un aller-retour de plateforme
  /// par zapping quand le profil n'a pas changé.
  static Map<String, Object?>? _lastPushed;

  static Future<void> push(Media3PlaybackProfile profile) async {
    final config = profile.toMethodArguments();
    if (_lastPushed != null && _sameConfig(_lastPushed!, config)) {
      return;
    }
    _lastPushed = config;
    await safeAsync<void>(
      () async {
        await _channel.invokeMethod('configure', config);
      },
      context: 'PlayerProfileService.push',
    );
  }

  /// Ouvre la config à une nouvelle session de lecture : le prochain `push`
  /// réémet même un profil identique.
  static void invalidate() => _lastPushed = null;

  /// Pousse le profil media3 du profil d'appareil donné.
  ///
  /// À appeler AVANT toute création d'un [VideoPlayerController] : la config
  /// est lue à la construction de l'ExoPlayer, donc un contrôleur créé avant
  /// le `push` conserve les seuils par défaut d'ExoPlayer (tampons de 50 s,
  /// aucune limite de résolution) pour toute sa durée de vie, et le `push`
  /// ne rattrape rien. C'est notamment le cas des contrôleurs préchauffés
  /// depuis la grille Live TV, dont celui que l'écran de lecture récupère
  /// ensuite : sans ce `push`, la première chaîne regardée après un
  /// démarrage d'application ignorait le profil de l'appareil.
  static Future<void> pushForDevice(DeviceProfile profile) =>
      push(Media3PlaybackProfile.forProfile(profile));

  static bool _sameConfig(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Remet le lecteur en configuration d'usine (ExoPlayer par défaut).
  static Future<void> reset() => push(Media3PlaybackProfile.unset);
}
