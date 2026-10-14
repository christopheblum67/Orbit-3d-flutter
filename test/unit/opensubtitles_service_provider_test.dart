import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_api_key_provider.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_credentials_provider.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_service_provider.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_credentials_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La clé API saisie doit prendre effet SANS redémarrage.
///
/// [OpenSubtitlesService] prend sa clé dans son constructeur et le champ est
/// `final` : un service construit une fois garde la clé qu'il portait. C'est
/// pour cela que la clé est une dépendance OBSERVÉE du provider — sans quoi
/// l'utilisateur enregistre sa clé, l'écran ne change rien, et il conclut que
/// le bouton « Sauver » est cassé.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Le store des identifiants est un singleton d'état mémoire : on le vide
    // entre deux tests, sinon les préférences d'un test nourrissent le suivant.
    OpenSubtitlesCredentialsStore.instance.reset();
  });

  ProviderContainer newContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('le service porte la clé enregistrée', () async {
    final container = newContainer();

    expect(
      container.read(openSubtitlesServiceProvider).apiKey,
      isEmpty,
      reason: 'aucune clé au démarrage',
    );

    await container
        .read(openSubtitlesApiKeyProvider.notifier)
        .setApiKey('cle-valide');

    expect(
      container.read(openSubtitlesServiceProvider).apiKey,
      'cle-valide',
      reason: 'le service doit refléter la nouvelle clé immédiatement',
    );
  });

  test('changer de clé remplace le service', () async {
    final container = newContainer();
    final notifier = container.read(openSubtitlesApiKeyProvider.notifier);

    await notifier.setApiKey('premiere');
    expect(container.read(openSubtitlesServiceProvider).apiKey, 'premiere');

    await notifier.setApiKey('seconde');
    expect(
      container.read(openSubtitlesServiceProvider).apiKey,
      'seconde',
      reason: 'une clé remplacée doit remplacer le service, pas s\'y ajouter',
    );
  });

  test('un écran à l\'écoute est notifié du changement de clé', () async {
    // Une simple relecture ne prouve rien : l'interface ne relit pas le service,
    // elle l'ÉCOUTE. C'est ce qui déclenche la reconstruction du widget.
    final container = newContainer();
    final seen = <String>[];
    final sub = container.listen(
      openSubtitlesServiceProvider,
      (_, next) => seen.add(next.apiKey),
    );
    addTearDown(sub.close);

    await container
        .read(openSubtitlesApiKeyProvider.notifier)
        .setApiKey('cle-notifiee');
    await Future<void>.delayed(Duration.zero);

    expect(
      seen,
      contains('cle-notifiee'),
      reason: 'l\'écouteur doit être réveillé, sinon la saisie ne se voit pas',
    );
  });

  test('la clé survit à un redémarrage de l\'application', () async {
    final first = newContainer();
    await first.read(openSubtitlesApiKeyProvider.notifier).setApiKey('persistee');

    // Nouveau conteneur = nouvelle session : c'est le cas d'un relancement.
    final second = newContainer();
    await second.read(openSubtitlesApiKeyProvider.notifier).load();

    expect(
      second.read(openSubtitlesServiceProvider).apiKey,
      'persistee',
      reason: 'le bouton « Sauver » doit écrire DANS les préférences ; sinon '
          'la clé disparaît au redémarrage et la recherche ne repart plus',
    );
  });

  test('une clé vide efface la précédente', () async {
    final container = newContainer();
    final notifier = container.read(openSubtitlesApiKeyProvider.notifier);

    await notifier.setApiKey('a-supprimer');
    await notifier.setApiKey('   ');

    expect(
      container.read(openSubtitlesServiceProvider).apiKey,
      isEmpty,
      reason: 'espaces seuls = effacement, sinon le bouton « Effacer la clé » '
          'laisserait une valeur inerte qui produit des 401',
    );
  });

  test('une clé persistée est chargée si l\'utilisateur n\'a rien saisi', () async {
    SharedPreferences.setMockInitialValues(
      {'opensubtitles_api_key': 'deja-enregistree'},
    );
    final container = newContainer();

    await container.read(openSubtitlesApiKeyProvider.notifier).load();

    expect(
      container.read(openSubtitlesApiKeyProvider),
      'deja-enregistree',
      reason: 'le garde-fou ne doit pas casser le chargement normal',
    );
  });

  test('le service porte le compte enregistré', () async {
    final container = newContainer();

    expect(
      container.read(openSubtitlesServiceProvider).username,
      isEmpty,
      reason: 'aucun compte au démarrage',
    );

    await container
        .read(openSubtitlesCredentialsProvider.notifier)
        .setCredentials(
          const OpenSubtitlesCredentials(username: 'alice', password: 'p'),
        );

    final service = container.read(openSubtitlesServiceProvider);
    expect(
      service.username,
      'alice',
      reason: 'sans cela, un compte saisi ne servirait qu\'au redémarrage '
          'suivant, exactement le symptôme « j\'ai enregistré et ça n\'a rien '
          'changé »',
    );
    expect(service.password, 'p');
  });

  test('effacer le compte vide le service', () async {
    final container = newContainer();
    final notifier = container.read(openSubtitlesCredentialsProvider.notifier);

    await notifier.setCredentials(
      const OpenSubtitlesCredentials(username: 'alice', password: 'p'),
    );
    expect(container.read(openSubtitlesServiceProvider).username, 'alice');

    await notifier.clear();
    expect(
      container.read(openSubtitlesServiceProvider).username,
      isEmpty,
      reason: 'le bouton « Effacer le compte » doit reconstruire un service '
          'anonyme, pas garder l\'ancien',
    );
  });

  test('les identifiants survivent à un redémarrage de l\'application',
      () async {
    final first = newContainer();
    await first
        .read(openSubtitlesCredentialsProvider.notifier)
        .setCredentials(
          const OpenSubtitlesCredentials(username: 'alice', password: 'p'),
        );

    // Nouveau conteneur = nouvelle session : c'est le cas d'un relancement.
    final second = newContainer();
    await second.read(openSubtitlesCredentialsProvider.notifier).load();

    final service = second.read(openSubtitlesServiceProvider);
    expect(service.username, 'alice');
    expect(service.password, 'p');
  });
}