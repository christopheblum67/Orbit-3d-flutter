import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
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
          return _toTrackChoices(tracks);
        },
        context: 'StreamSubtitleTracksService.fetchSubtitleTracks',
      );

      if (result.isSuccess && result.valueOrNull != null) {
        return result.valueOrNull!;
      }
      final error = result.errorOrNull;
      if (error != null) {
        LoggerService.instance.warning(
          'Impossible de lire les pistes de sous-titres intégrées',
          tag: 'subtitle-tracks',
          error: error.originalError ?? error,
        );
      }
      return const [];
    } catch (error) {
      LoggerService.instance.warning(
        'Échec inattendu lors de la lecture des pistes de sous-titres',
        tag: 'subtitle-tracks',
        error: error,
      );
      return const [];
    } finally {
      // Le contrôleur doit être libéré même en cas d'erreur : sans cela, une
      // texture média resterait allouée à chaque ouverture du sélecteur.
      try {
        controller.dispose();
      } catch (error) {
        LoggerService.instance.warning(
          'Impossible de libérer le contrôleur de sous-titres temporaire',
          tag: 'subtitle-tracks',
          error: error,
        );
      }
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
      } catch (error) {
        LoggerService.instance.debug(
          'Le pont natif des sous-titres intégrés n’est pas disponible: $error',
          tag: 'subtitle-tracks',
        );
        return const [];
      }
      if (elapsed >= _deadline) return const [];
      await Future<void>.delayed(_pollInterval);
      elapsed += _pollInterval;
    }
  }

  /// Construit une entrée PAR PISTE, comme le lecteur.
  ///
  /// L'ancienne version dédupliquait par code langue : sur un flux à cinq pistes
  /// (`fr`, `fr (CC)`, `fr (SDH)`, `en (CC)`, `en (SDH)`) le menu ne montrait
  /// plus que DEUX langues, et le libellé affiché était celui de la DERNIÈRE
  /// piste — l'utilisateur lisait « 3 options » là où le lecteur en offrait 6.
  /// On garde donc chaque piste, avec son libellé (repli sur le nom de langue
  /// traduit quand le panel n'en publie pas). La valeur mémorisée est le
  /// libellé, que [pickEmbeddedSubtitleTrackForPreference] sait reconnaître ;
  /// une Map déduplique les libellés identiques, car `DropdownButton` interdit
  /// deux items de même valeur.
  static List<(String, String)> _toTrackChoices(
    List<EmbeddedSubtitleTrack> tracks,
  ) {
    final choices = <String, String>{};
    for (final track in tracks) {
      final label = track.label.trim();
      final lang = track.language?.trim();
      // Un label générique (« Sous-titres », « Subtitle ») n'apprend rien : on
      // préfère le nom de la langue traduit.
      final generic = label.isEmpty ||
          label == 'Sous-titres' ||
          label.toLowerCase() == 'subtitle';
      final String display;
      if (!generic) {
        display = label;
      } else if (lang == null || lang.isEmpty || lang.toLowerCase() == 'und') {
        continue; // ni libellé ni langue exploitables
      } else {
        display = LanguageLabel.of(lang).trim();
      }
      if (display.isEmpty) continue;
      choices[display] = display;
    }
    return choices.entries.map((e) => (e.key, e.value)).toList();
  }
}
