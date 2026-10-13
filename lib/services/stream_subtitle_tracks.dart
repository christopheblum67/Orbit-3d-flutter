import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

/// Service pour récupérer les pistes de sous-titres **intégrées** d'un flux
/// (VOD/Série).
///
/// Contrairement à [StreamAudioTracksService] — qui lit `getAudioTracks()`,
/// renseigné dès l'`initialize()` — les pistes texte d'un flux adaptatif
/// (HLS/DASH) sont publiées par media3 **par vagues** : la première sonde, juste
/// après l'initialisation, ne voit souvent qu'une partie de la liste, parfois
/// rien. On sonde donc jusqu'à obtenir une liste non vide, dans un délai borné,
/// exactement comme le balayage du lecteur ([_startEmbeddedScan] côté écran).
///
/// Utilise un [VideoPlayerController] temporaire, disposé dans tous les cas.
class StreamSubtitleTracksService {
  StreamSubtitleTracksService._();

  /// Cadence de sondage : une sonde par seconde suffit (media3 ne publie pas
  /// plus vite) et laisse le player respirer.
  static const Duration _pollInterval = Duration(seconds: 1);

  /// Délai maximal d'attente. Aligné sur le comportement observé du panel
  /// (liste complète après ~30 s sur le lecteur) : on reste volontairement plus
  /// court ici, un sélecteur de réglages n'a pas à bloquer 30 s.
  static const Duration _deadline = Duration(seconds: 12);

  /// Récupère les langues de sous-titres intégrées disponibles pour [streamUrl].
  ///
  /// Retourne des paires `(codeLangue, nomAffichage)` uniques.
  /// Ex: `[('fr', 'Français'), ('en', 'Anglais')]`.
  static Future<List<(String, String)>> fetchSubtitleTracks(
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
          final tracks = await _probeTracks(controller);
          return _toLanguages(tracks);
        },
        context: 'StreamSubtitleTracksService.fetchSubtitleTracks',
      );

      if (result.isSuccess && result.valueOrNull != null) {
        return result.valueOrNull!;
      }
      return const [];
    } catch (_) {
      return const [];
    } finally {
      // Le contrôleur doit être libéré même en cas d'erreur : sans cela, une
      // texture média resterait allouée à chaque ouverture du sélecteur.
      try {
        controller.dispose();
      } catch (_) {}
    }
  }

  /// Sonde les pistes texte jusqu'à une liste non vide ou [_deadline].
  ///
  /// Canal natif indisponible (plateforme non Android, lecteur tiers) → liste
  /// vide, sans faire échouer le sélecteur.
  static Future<List<EmbeddedSubtitleTrack>> _probeTracks(
    VideoPlayerController controller,
  ) async {
    final bridge = EmbeddedSubtitleBridge(embeddedPlayerId(controller));
    var elapsed = Duration.zero;
    while (true) {
      try {
        final tracks = await bridge.getTracks();
        if (tracks.isNotEmpty) return tracks;
      } catch (_) {
        return const [];
      }
      if (elapsed >= _deadline) return const [];
      await Future<void>.delayed(_pollInterval);
      elapsed += _pollInterval;
    }
  }

  /// Réduit les pistes à des langues uniques, avec un libellé lisible.
  static List<(String, String)> _toLanguages(
    List<EmbeddedSubtitleTrack> tracks,
  ) {
    final languages = <String, String>{};
    for (final track in tracks) {
      final lang = track.language?.toLowerCase().trim();
      if (lang == null || lang.isEmpty || lang == 'und') continue;
      final label = track.label.trim();
      // Un label générique (« Sous-titres », « Subtitle ») n'apprend rien :
      // on préfère le nom de la langue traduit.
      final generic = label.isEmpty ||
          label == 'Sous-titres' ||
          label.toLowerCase() == 'subtitle';
      languages[lang] = generic ? LanguageLabel.of(lang) : label;
    }
    return languages.entries.map((e) => (e.key, e.value)).toList();
  }
}
