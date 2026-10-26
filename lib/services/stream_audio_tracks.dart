import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

/// Service pour récupérer les pistes audio réelles d'un flux.
///
/// Utilise un [VideoPlayerController] temporaire pour charger le flux
/// et récupérer les pistes audio disponibles via ExoPlayer.
class StreamAudioTracksService {
  StreamAudioTracksService._();

  /// Récupère les pistes audio disponibles pour un flux donné.
  ///
  /// Retourne une liste de paires (codeLangue, nomAffichage) uniques.
  /// Ex: [('fr', 'Français'), ('en', 'English')]
  static Future<List<(String, String)>> fetchAudioTracks(
    String streamUrl,
  ) async {
    if (!isLikelyStreamUrl(streamUrl)) return const [];

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(streamUrl),
      httpHeaders: streamHeaders(streamUrl),
    );

    try {
      final result = await safeAsync(
        () async {
          await controller.initialize();
          final tracks = await controller.getAudioTracks();
          controller.dispose();

          final languages = <String, String>{};
          for (final track in tracks) {
            final lang = track.language?.toLowerCase().trim();
            final label = track.label?.trim();
            if (lang != null && lang.isNotEmpty && lang != 'und') {
              // Utiliser le label si dispo, sinon le code langue
              languages[lang] =
                  (label != null && label.isNotEmpty && label != 'Audio')
                      ? label
                      : _languageDisplayName(lang);
            }
          }
          return languages.entries.map((e) => (e.key, e.value)).toList();
        },
        context: 'StreamAudioTracksService.fetchAudioTracks',
      );

      if (result.isSuccess && result.valueOrNull != null) {
        return result.valueOrNull!;
      }
      final error = result.errorOrNull;
      if (error != null) {
        LoggerService.instance.warning(
          'Impossible de lire les pistes audio du flux',
          tag: 'audio-tracks',
          error: error.originalError ?? error,
        );
      }
      return const [];
    } catch (error) {
      LoggerService.instance.warning(
        'Échec inattendu lors de la lecture des pistes audio',
        tag: 'audio-tracks',
        error: error,
      );
      return const [];
    } finally {
      // S'assurer que le controller est disposé même en cas d'erreur
      try {
        controller.dispose();
      } catch (error) {
        LoggerService.instance.warning(
          'Impossible de libérer le contrôleur audio temporaire',
          tag: 'audio-tracks',
          error: error,
        );
      }
    }
  }

  /// Nom d'affichage lisible pour un code langue ISO 639-1.
  static String _languageDisplayName(String code) {
    const names = {
      'fr': 'Français',
      'en': 'English',
      'es': 'Español',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ja': '日本語',
      'ko': '한국어',
      'zh': '中文',
      'ru': 'Русский',
      'ar': 'العربية',
      'nl': 'Nederlands',
      'pl': 'Polski',
      'tr': 'Türkçe',
      'hi': 'हिन्दी',
      'sv': 'Svenska',
      'da': 'Dansk',
      'no': 'Norsk',
      'fi': 'Suomi',
      'cs': 'Čeština',
      'hu': 'Magyar',
      'ro': 'Română',
      'he': 'עברית',
      'th': 'ไทย',
      'vi': 'Tiếng Việt',
      'id': 'Bahasa Indonesia',
      'ms': 'Bahasa Melayu',
    };
    return names[code.toLowerCase()] ?? code.toUpperCase();
  }
}
