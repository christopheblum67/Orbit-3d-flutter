import 'package:shared_preferences/shared_preferences.dart';

/// Mémoire de sélection des pistes audio par contenu.
///
/// Permet de ne choisir sa langue / sa piste audio qu'une seule fois par
/// programme (identifié par `mediaKey`, ex. `progressId` ou URL du flux) :
/// la piste retenue est ré-appliquée automatiquement à la lecture suivante.
class PlayerTrackPrefs {
  PlayerTrackPrefs._();

  static const String _audioPrefix = 'player_track.audio.';
  static const String _seriesAudioPrefix = 'player_track.series_audio.';
  static const String _seriesForcedPrefix = 'player_track.series_forced.';

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

  /// Langue audio préférée pour une série (ex: 'fr', 'en').
  static Future<String?> seriesAudioLanguageFor(String seriesId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_seriesAudioPrefix$seriesId');
  }

  /// Définit la langue audio préférée pour une série (appliquée à tous les épisodes).
  static Future<void> setSeriesAudioLanguage(
      String seriesId, String language,) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_seriesAudioPrefix$seriesId', language);
  }

  /// Vérifie si la langue est forcée pour toute la série (ignore les préférences par épisode).
  static Future<bool> isSeriesAudioForced(String seriesId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_seriesForcedPrefix$seriesId') ?? false;
  }

  /// Force la langue audio pour tous les épisodes de la série.
  static Future<void> setSeriesAudioForced(String seriesId, bool forced) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_seriesForcedPrefix$seriesId', forced);
  }

  /// Supprime la préférence de langue pour une série.
  static Future<void> clearSeriesAudioPreference(String seriesId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_seriesAudioPrefix$seriesId');
    await prefs.remove('$_seriesForcedPrefix$seriesId');
  }
}
