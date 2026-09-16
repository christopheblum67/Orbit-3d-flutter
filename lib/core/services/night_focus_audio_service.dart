import 'package:flutter/services.dart';

/// Pont Dart -> natif du DSP « Night Focus ».
///
/// Transmet les réglages tonaux (master, dialogue boost, bass killer, gain
/// vocal, décalage audio) au processeur audio du renderer video_player
/// vendorisé, via le canal natif « orbit/night_focus ». Quand le master est
/// OFF, le natif bascule le processeur en mode by-pass (pipeline inchangé).
class NightFocusAudioService {
  NightFocusAudioService._();

  static const MethodChannel _channel = MethodChannel('orbit/night_focus');

  /// Pousse la config courante vers le natif. À appeler avant la création
  /// d'un [VideoPlayerController] pour être prise en compte à la
  /// configuration du pipeline audio, ET à chaque changement de réglage :
  /// le natif incrémente la version de config, détectée à chaud par le
  /// processeur audio pendant la lecture (hot-reload).
  static Future<void> push(
    bool enabled, {
    double dialogueBoostDb = 0,
    double bassKillerCutoffHz = 0,
    double vocalGainDb = 0,
    int audioDelayMs = 0,
    bool volumeNormalization = true,
  }) async {
    try {
      await _channel.invokeMethod('configure', <String, Object?>{
        'enabled': enabled,
        'dialogueBoostDb': dialogueBoostDb,
        'bassKillerCutoffHz': bassKillerCutoffHz,
        'vocalGainDb': vocalGainDb,
        'audioDelayMs': audioDelayMs,
        'volumeNormalization': volumeNormalization,
      });
    } on PlatformException catch (_) {
      // Échec silencieux : le DSP natif n'est pas disponible (non-Android).
    } catch (_) {
      // Idem : on n'interrompt jamais la lecture pour un souci de canal.
    }
  }
}
