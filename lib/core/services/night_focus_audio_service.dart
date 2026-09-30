import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Pont Dart -> natif du DSP « Night Focus ».
///
/// Transmet les réglages tonaux (master, dialogue boost, bass killer, gain
/// vocal, décalage audio) au processeur audio du renderer video_player
/// vendorisé, via le canal natif « orbit/night_focus ». Quand le master est
/// OFF, le natif bascule le processeur en mode by-pass (pipeline inchangé).
class NightFocusAudioService {
  NightFocusAudioService._();

  static const MethodChannel _channel = MethodChannel('orbit/night_focus');

  /// Dernière configuration réellement transmise au natif.
  ///
  /// Le zapping appelait `push` avant chaque création de contrôleur : deux
  /// allers-retours de plateforme sur le chemin critique, pour des réglages
  /// inchangés. On ne réémet donc que ce qui change réellement.
  static Map<String, Object?>? _lastPushed;

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
    final config = <String, Object?>{
      'enabled': enabled,
      'dialogueBoostDb': dialogueBoostDb,
      'bassKillerCutoffHz': bassKillerCutoffHz,
      'vocalGainDb': vocalGainDb,
      'audioDelayMs': audioDelayMs,
      'volumeNormalization': volumeNormalization,
    };
    if (_lastPushed != null && _sameConfig(_lastPushed!, config)) {
      return;
    }
    // Mémorisé avant l'envoi : un second `push` en cours de route ne doit pas
    // repartir sur les mêmes valeurs, et un échec natif ne doit pas bloquer les
    // Essais suivants (le prochain settings push réessaiera).
    _lastPushed = config;
    await safeAsync<void>(
      () async {
        await _channel.invokeMethod('configure', config);
      },
      context: 'NightFocusAudioService.push',
    );
  }

  /// Ouvre la config à une nouvelle session de lecture : le prochain `push`
  /// réémet même une configuration identique (le natif a pu être redémarré).
  static void invalidate() => _lastPushed = null;

  static bool _sameConfig(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
