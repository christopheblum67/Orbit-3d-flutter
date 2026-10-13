import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';

/// Choix de la piste intégrée pour une langue donnée.
///
/// C'est la règle qui décide QUEL sous-titre s'affiche quand une série a une
/// langue par défaut. Un flux porte souvent deux pistes pour la même langue
/// (la complète et la variante « forced ») : le test verrouille la préférence
/// pour la piste complète, sinon l'utilisateur ne verrait que les quelques
/// lignes forcées.
EmbeddedSubtitleTrack track({
  required String id,
  String? language,
  bool isForced = false,
  String label = 'Sous-titres',
}) =>
    EmbeddedSubtitleTrack(
      id: id,
      label: label,
      language: language,
      isSelected: false,
      isForced: isForced,
      mimeType: 'text/vtt',
    );

void main() {
  group('pickEmbeddedSubtitleTrackForLanguage', () {
    test('retourne null si aucune piste ou langue vide', () {
      expect(pickEmbeddedSubtitleTrackForLanguage(const [], 'fr'), isNull);
      expect(
        pickEmbeddedSubtitleTrackForLanguage(
          [track(id: '0_0', language: 'en')],
          '',
        ),
        isNull,
      );
    });

    test('sélectionne la langue demandée, casse et espaces ignorés', () {
      final tracks = [
        track(id: '0_0', language: 'EN'),
        track(id: '0_1', language: ' fr '),
      ];
      expect(pickEmbeddedSubtitleTrackForLanguage(tracks, 'Fr')!.id, '0_1');
    });

    test('préfère la piste complète à la variante forcée', () {
      final tracks = [
        track(id: '0_0', language: 'fr', isForced: true, label: 'VFF : Forced'),
        track(id: '0_1', language: 'fr', label: 'Français'),
      ];
      expect(pickEmbeddedSubtitleTrackForLanguage(tracks, 'fr')!.id, '0_1');
    });

    test('retombe sur la variante forcée si c\'est la seule', () {
      final tracks = [
        track(id: '0_0', language: 'fr', isForced: true),
      ];
      expect(pickEmbeddedSubtitleTrackForLanguage(tracks, 'fr')!.id, '0_0');
    });

    test('ignore les pistes sans code langue', () {
      final tracks = [
        track(id: '0_0'),
        track(id: '0_1', language: 'fr'),
      ];
      expect(pickEmbeddedSubtitleTrackForLanguage(tracks, 'fr')!.id, '0_1');
    });

    test('ne retourne rien pour une langue absente du flux', () {
      final tracks = [track(id: '0_0', language: 'en')];
      expect(pickEmbeddedSubtitleTrackForLanguage(tracks, 'de'), isNull);
    });
  });
}
