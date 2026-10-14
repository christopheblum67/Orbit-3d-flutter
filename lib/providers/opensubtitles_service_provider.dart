import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_api_key_provider.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_credentials_provider.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Service OpenSubtitles, reconstruit quand la clé ou le compte changent.
///
/// ## Pourquoi un provider plutôt qu'un singleton
///
/// [OpenSubtitlesService] prend sa clé et ses identifiants dans son
/// CONSTRUCTEUR, et les champs sont `final`. Une instance créée une fois
/// garderait donc ceux de sa construction : saisir une nouvelle clé ou un
/// nouveau compte dans les réglages ne prendrait effet qu'au redémarrage, ce
/// qui est exactement le symptôme « j'ai enregistré ma clé et ça n'a rien
/// changé ».
///
/// Déclarer le service dans le graphe Riverpod et faire de la clé et des
/// identifiants des dépendances observées règle le problème à la source :
/// `ref.watch` invalide le service, l'écran qui l'écoute se reconstruit, et le
/// nouveau service porte la nouvelle configuration.
///
/// Le service reste `const`-constructible : cette factory le reconstruit au
/// changement, pas à chaque build.
final openSubtitlesServiceProvider = Provider<OpenSubtitlesService>((ref) {
  final key = ref.watch(openSubtitlesApiKeyProvider);
  final credentials = ref.watch(openSubtitlesCredentialsProvider);
  return OpenSubtitlesService(
    apiKey: key,
    username: credentials.username,
    password: credentials.password,
  );
});