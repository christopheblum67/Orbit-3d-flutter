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

  group('pickEmbeddedSubtitleTrackForPreference', () {
    // Le menu série propose désormais une entrée PAR PISTE (comme le lecteur) :
    // la préférence mémorisée est le LIBELLÉ de la piste, pas un code langue.
    final tracks = [
      track(id: '4_0', language: 'fr', label: 'Français'),
      track(id: '5_0', language: 'fr', label: 'Français (CC)'),
      track(id: '6_0', language: 'fr', label: 'Français (SDH)'),
      track(id: '7_0', language: 'en', label: 'English [Original] (CC)'),
      track(id: '8_0', language: 'en', label: 'English [Original] (SDH)'),
    ];

    test('choisit la piste par son libellé exact', () {
      expect(
        pickEmbeddedSubtitleTrackForPreference(tracks, 'Français (SDH)')!.id,
        '6_0',
      );
    });

    test('libellé reconnu malgré casse et espaces', () {
      expect(
        pickEmbeddedSubtitleTrackForPreference(tracks, '  français (sdh) ')!.id,
        '6_0',
      );
    });

    test('accepte un code langue (préférences historiques)', () {
      expect(
        pickEmbeddedSubtitleTrackForPreference(tracks, 'fr')!.id,
        '4_0',
        reason: 'repli langue : on préfère la piste complète à une variante',
      );
    });

    test('accepte le nom de langue traduit', () {
      expect(
        pickEmbeddedSubtitleTrackForPreference(tracks, 'Anglais')!.id,
        '7_0',
      );
    });

    test('retourne null pour une préférence vide ou inconnue', () {
      expect(pickEmbeddedSubtitleTrackForPreference(tracks, '   '), isNull);
      expect(pickEmbeddedSubtitleTrackForPreference(tracks, 'Klingon'), isNull);
    });
  });
}
