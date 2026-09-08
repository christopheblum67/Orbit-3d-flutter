import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';

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
  /// - Eco : tampon long (20 s) pour les appareils faiblement dotés, plafonné
  ///   à 1080p (les flux 4K satureraient le décodage).
  /// - Standard : tampon intermédiaire (10 s), rendu 3D et multi-vue X2.
  /// - Ultra : tampon court (3 s) pour un zapping immédiat, 4K HDR possible.
  static Media3PlaybackProfile forProfile(DeviceProfile profile) {
    return switch (profile) {
      DeviceProfile.eco => const Media3PlaybackProfile(
          minBufferMs: 20000,
          maxBufferMs: 60000,
          bufferForPlaybackMs: 15000,
          bufferForPlaybackAfterRebufferMs: 10000,
          maxVideoHeight: 1080,
        ),
      DeviceProfile.standard => const Media3PlaybackProfile(
          minBufferMs: 10000,
          maxBufferMs: 50000,
          bufferForPlaybackMs: 8000,
          bufferForPlaybackAfterRebufferMs: 5000,
        ),
      DeviceProfile.ultra => const Media3PlaybackProfile(
          minBufferMs: 3000,
          maxBufferMs: 15000,
          bufferForPlaybackMs: 2000,
          bufferForPlaybackAfterRebufferMs: 1000,
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

  static Future<void> push(Media3PlaybackProfile profile) async {
    try {
      await _channel.invokeMethod('configure', profile.toMethodArguments());
    } on PlatformException catch (_) {
      // Échec silencieux : le canal natif n'est pas disponible.
    } catch (_) {
      // Idem : la lecture ne doit jamais être interrompue pour un réglage.
    }
  }

  /// Remet le lecteur en configuration d'usine (ExoPlayer par défaut).
  static Future<void> reset() => push(Media3PlaybackProfile.unset);
}
