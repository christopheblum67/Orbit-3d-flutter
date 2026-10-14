import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_credentials_store.dart';
import 'package:orbit_3d_flutter/services/secret_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exactitude des identifiants du compte OpenSubtitles.
///
/// Deux règles distinctes pour deux champs distincts :
///
/// - l'IDENTIFIANT subit le même nettoyage que la clé API (les invisibles d'un
///   copier-coller le rendent invalide sans que rien ne se voie) ;
/// - le MOT DE PASSE ne perd QUE ses espaces de bord : un mot de passe peut
///   légitimement contenir des espaces internes, les retirer en changerait la
///   valeur et produirait un 401 inexplicable.
///
/// Depuis la migration S1, le MOT DE PASSE vit dans [SecretStore] (Keystore) ;
/// seul l'identifiant — non sensible — reste dans SharedPreferences.
void main() {
  const usernameKey = 'opensubtitles_username';
  const passwordKey = 'opensubtitles_password';

  String ch(int rune) => String.fromCharCode(rune);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OpenSubtitlesCredentialsStore.instance.reset();
    overrideSecretStoreForTesting(InMemorySecretStore());
  });

  tearDown(restoreSecretStoreForTesting);

  Future<String?> storedUsername() async =>
      (await SharedPreferences.getInstance()).getString(usernameKey);

  Future<String?> storedPassword() async => secretStore.read(passwordKey);

  group('OpenSubtitlesCredentials', () {
    test('isEmpty exige identifiant ET mot de passe', () {
      expect(const OpenSubtitlesCredentials().isEmpty, isTrue);
      expect(const OpenSubtitlesCredentials(username: 'u').isEmpty, isTrue);
      expect(const OpenSubtitlesCredentials(password: 'p').isEmpty, isTrue);
      expect(
        const OpenSubtitlesCredentials(username: ' u ', password: 'p').isEmpty,
        isFalse,
      );
    });

    test('égalité par valeur', () {
      expect(
        const OpenSubtitlesCredentials(username: 'u', password: 'p'),
        const OpenSubtitlesCredentials(username: 'u', password: 'p'),
      );
      expect(
        const OpenSubtitlesCredentials(username: 'u', password: 'p'),
        isNot(const OpenSubtitlesCredentials(username: 'u', password: 'x')),
      );
    });
  });

  group('persistance', () {
    test('set puis get, sans redémarrage', () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        const OpenSubtitlesCredentials(username: 'mon-compte', password: 'p'),
      );

      expect(
        OpenSubtitlesCredentialsStore.instance.credentials,
        const OpenSubtitlesCredentials(username: 'mon-compte', password: 'p'),
      );
      expect(OpenSubtitlesCredentialsStore.instance.hasCredentials, isTrue);
    });

    test('ce qui est écrit est exactement l\'identifiant et le mot de passe',
        () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        const OpenSubtitlesCredentials(
          username: 'alice',
          password: 's3cret avec espaces',
        ),
      );

      expect(await storedUsername(), 'alice');
      expect(await storedPassword(), 's3cret avec espaces');
    });

    test('survit à un redémarrage (état mémoire vidé, coffre intact)',
        () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        const OpenSubtitlesCredentials(username: 'alice', password: 'p'),
      );

      // Simule un relancement : la mémoire repart de zéro.
      OpenSubtitlesCredentialsStore.instance.reset();
      expect(OpenSubtitlesCredentialsStore.instance.hasCredentials, isFalse);

      await OpenSubtitlesCredentialsStore.instance.load();
      expect(
        OpenSubtitlesCredentialsStore.instance.credentials,
        const OpenSubtitlesCredentials(username: 'alice', password: 'p'),
      );
    });

    test('clear efface l\'identifiant et le mot de passe du coffre', () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        const OpenSubtitlesCredentials(username: 'alice', password: 'p'),
      );

      await OpenSubtitlesCredentialsStore.instance.clear();

      expect(await storedUsername(), isNull);
      expect(await storedPassword(), isNull);
      expect(
        OpenSubtitlesCredentialsStore.instance.credentials.isEmpty,
        isTrue,
      );
    });

    test('les préférences legacy (password en clair) migrent vers le coffre',
        () async {
      // Installation existante : identifiant ET mot de passe en clair dans les
      // préférences (stockage de l'ancienne version).
      SharedPreferences.setMockInitialValues({
        'opensubtitles_username': 'alice',
        'opensubtitles_password': 'old-password',
      });

      await OpenSubtitlesCredentialsStore.instance.load();

      expect(
        OpenSubtitlesCredentialsStore.instance.credentials.username,
        'alice',
      );
      expect(
        OpenSubtitlesCredentialsStore.instance.credentials.password,
        'old-password',
      );
      expect(
        await storedPassword(),
        'old-password',
        reason: 'le mot de passe doit désormais vivre dans le coffre sécurisé',
      );
      expect(
        await storedUsername(),
        'alice',
        reason: 'l\'identifiant, non sensible, reste dans SharedPreferences',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('opensubtitles_password'),
        isNull,
        reason: 'le mot de passe en clair doit avoir quitté les préférences',
      );
    });
  });

  group('nettoyage à la saisie', () {
    test('l\'identifiant subit le même nettoyage que la clé API', () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        OpenSubtitlesCredentials(
          username: 'alice${ch(0x200B)}compte${ch(0xFEFF)}',
          password: 'p',
        ),
      );

      expect(
        OpenSubtitlesCredentialsStore.instance.credentials.username,
        'alicecompte',
        reason: 'un zéro-espace ou un BOM collé doit disparaître, sinon '
            'l\'identifiant est rejeté sans que rien ne se voie',
      );
    });

    test('le mot de passe ne perd que ses espaces de bord, jamais les internes',
        () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        const OpenSubtitlesCredentials(
          username: 'alice',
          password: '  mon mot de passe  ',
        ),
      );

      expect(
        OpenSubtitlesCredentialsStore.instance.credentials.password,
        'mon mot de passe',
      );
      expect(await storedPassword(), 'mon mot de passe');
    });

    test('un identifiant tout en invisibles devient vide', () async {
      await OpenSubtitlesCredentialsStore.instance.setCredentials(
        OpenSubtitlesCredentials(
          username: '${ch(0x200B)}${ch(0x200B)}',
          password: 'p',
        ),
      );

      expect(
        OpenSubtitlesCredentialsStore.instance.credentials.username,
        isEmpty,
      );
      expect(await storedUsername(), isNull);
    });
  });
}