import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/replay/replay_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';
import 'package:orbit_3d_flutter/models/channel.dart';

/// Badge « fenêtre de replay » affiché sous le nom de chaîne.
///
/// Le badge doit refléter la **source unique** [ApiService.effectiveArchiveDays]
/// (comme l'écran Replay et `channelCatchUpProvider`) et rester exprimé en
/// jours. L'ancienne version retombait sur `archiveWindow(...).inHours` quand
/// le panel ne déclarait aucune durée : elle affichait « Replay 336 h » au lieu
/// de « Replay 14 j ».
Channel _channel({int archiveDays = 0}) => Channel(
  id: '1234',
  name: 'TF1',
  logoUrl: '',
  streamUrl: '',
  group: 'Généralistes',
  archiveDays: archiveDays,
);

void main() {
  final l = AppLocalizationsFr();

  group('replayWindowBadgeLabel', () {
    test('suit la durée annoncée par l\'abonnement (7 j)', () {
      expect(
        replayWindowBadgeLabel(l, _channel(archiveDays: 7)),
        'Replay 7 j',
      );
    });

    test('suit la durée annoncée par l\'abonnement (14 j)', () {
      expect(
        replayWindowBadgeLabel(l, _channel(archiveDays: 14)),
        'Replay 14 j',
      );
    });

    test('retombe sur 14 j (et non 336 h) si le panel ne déclare rien', () {
      // Non-régression : repli unifié à 14 jours, jamais la conversion en
      // heures qui faisait diverger le badge du reste de l'application.
      expect(
        replayWindowBadgeLabel(l, _channel(archiveDays: 0)),
        'Replay 14 j',
      );
    });

    test('n\'affiche jamais une valeur en heures', () {
      expect(
        replayWindowBadgeLabel(l, _channel(archiveDays: 0)),
        isNot(contains(' h')),
      );
    });
  });
}
