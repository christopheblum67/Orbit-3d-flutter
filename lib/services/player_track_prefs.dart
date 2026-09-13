import 'package:shared_preferences/shared_preferences.dart';

/// Mémoire de sélection des pistes audio par contenu.
///
/// Permet de ne choisir sa langue / sa piste audio qu'une seule fois par
/// programme (identifié par `mediaKey`, ex. `progressId` ou URL du flux) :
/// la piste retenue est ré-appliquée automatiquement à la lecture suivante.
class PlayerTrackPrefs {
  PlayerTrackPrefs._();

  static const String _audioPrefix = 'player_track.audio.';

  /// Piste audio mémorisée pour [mediaKey], ou `null` si jamais choisie.
  static Future<String?> audioTrackFor(String mediaKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_audioPrefix$mediaKey');
  }

  /// Mémorise [trackId] comme piste audio préférée pour [mediaKey].
  static Future<void> setAudioTrack(String mediaKey, String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_audioPrefix$mediaKey', trackId);
  }
}