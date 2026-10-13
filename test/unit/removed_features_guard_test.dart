import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou de la suppression de la **recherche vocale** et des **notifications**.
///
/// Depuis cette suppression, l'application ne doit plus :
///  - demander le micro (`RECORD_AUDIO`) ni les notifications système
///    (`POST_NOTIFICATIONS`) ;
///  - embarquer `speech_to_text`, `firebase_messaging` ou
///    `flutter_local_notifications`.
///
/// ## Pourquoi un test sur les FICHIERS et pas sur le runtime
///
/// Une permission qui revient dans le manifeste, ou une dépendance ré-ajoutée
/// « au cas où », ne casse aucun build et n'échoue à l'exécution qu'après des
/// mois (prompt micro inattendu, nouvelle permission visible sur la fiche
/// Play Store). C'est exactement le genre de régression silencieuse qu'une
/// assertion sur le contenu des fichiers attrape immédiatement.
///
/// Ces contrôles **échouent sur l'état d'avant la suppression** : ils
/// verrouillent le changement.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('Manifeste Android', () {
    test('ne demande plus le micro (RECORD_AUDIO)', () {
      expect(
        manifest.contains('RECORD_AUDIO'),
        isFalse,
        reason: 'la recherche vocale a été supprimée : plus aucune raison '
            'de demander le micro',
      );
    });

    test('ne demande plus les notifications (POST_NOTIFICATIONS)', () {
      expect(
        manifest.contains('POST_NOTIFICATIONS'),
        isFalse,
        reason: 'aucune notification n\'est plus émise : la permission était '
            'inutile et visible par l\'utilisateur',
      );
    });

    test('ne déclare plus la messagerie Firebase', () {
      expect(manifest.contains('com.google.firebase.messaging'), isFalse);
      expect(manifest.contains('firebase_messaging'), isFalse);
    });

    test('conserve les permissions de lecture en arrière-plan', () {
      // La suppression des notifications ne doit PAS avoir emporté le service
      // de lecture : la lecture continue de fonctionner.
      expect(manifest.contains('android.permission.INTERNET'), isTrue);
      expect(manifest.contains('android.permission.WAKE_LOCK'), isTrue);
      expect(manifest.contains('android.permission.FOREGROUND_SERVICE'), isTrue);
      expect(
        manifest.contains('FOREGROUND_SERVICE_MEDIA_PLAYBACK'),
        isTrue,
      );
    });
  });

  group('Dépendances (pubspec.yaml)', () {
    test('plus de paquet speech_to_text', () {
      expect(pubspec.contains('speech_to_text'), isFalse);
    });

    test('plus de paquet firebase_messaging', () {
      expect(pubspec.contains('firebase_messaging'), isFalse);
    });

    test('plus de paquet flutter_local_notifications', () {
      expect(pubspec.contains('flutter_local_notifications'), isFalse);
    });
  });

  group('Code source', () {
    test('le service de notifications a été supprimé', () {
      expect(
        File('lib/services/notification_service.dart').existsSync(),
        isFalse,
      );
    });

    test('la recherche vocale a quitté l\'écran de recherche', () {
      final search = File(
        'lib/features/search/search_screen.dart',
      ).readAsStringSync();
      expect(search.contains('speech_to_text'), isFalse);
      expect(search.contains('_toggleListening'), isFalse);
      expect(search.contains('_requestMicPermission'), isFalse);
    });

    test('le préchauffage micro a quitté l\'onboarding', () {
      final onboarding = File(
        'lib/features/onboarding/onboarding_screen.dart',
      ).readAsStringSync();
      expect(onboarding.contains('speech_to_text'), isFalse);
      expect(onboarding.contains('_prewarmMicrophone'), isFalse);
    });
  });
}
