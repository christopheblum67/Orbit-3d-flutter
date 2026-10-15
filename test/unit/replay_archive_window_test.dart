import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

Channel _channel({int archiveDays = 0}) => Channel(
  id: '1234',
  name: 'TF1',
  logoUrl: '',
  streamUrl: '',
  group: 'Généralistes',
  archiveDays: archiveDays,
);

void main() {
  group('ApiService.archiveWindow', () {
    test('suit la durée annoncée par l\'abonnement (7 jours)', () {
      expect(
        ApiService.archiveWindow(_channel(archiveDays: 7)),
        const Duration(days: 7),
      );
    });

    test('suit la durée annoncée par l\'abonnement (14 jours)', () {
      expect(
        ApiService.archiveWindow(_channel(archiveDays: 14)),
        const Duration(days: 14),
      );
    });

    test('ne plafonne PAS un compte 7 jours à 48 h', () {
      // Non-régression : un plafond dur à 48 h bridait le Replay des comptes
      // 7/14 j alors que le serveur sert bel et bien l'historique.
      expect(
        ApiService.archiveWindow(_channel(archiveDays: 7)).inHours,
        greaterThan(48),
      );
      expect(
        ApiService.archiveWindow(_channel(archiveDays: 14)).inDays,
        greaterThan(2),
      );
    });

    test('repli à 14 j quand le panel ne déclare aucune durée', () {
      // Le repli unifié (fallbackArchiveDays = 14) remplace l'ancien 48 h.
      // Cela débloque les comptes 14 j dont le panel ne déclare pas la durée.
      expect(
        ApiService.archiveWindow(_channel(archiveDays: 0)),
        const Duration(days: 14),
      );
    });

    test('suit une durée d\'un seul jour', () {
      expect(
        ApiService.archiveWindow(_channel(archiveDays: 1)),
        const Duration(days: 1),
      );
    });
  });
}
