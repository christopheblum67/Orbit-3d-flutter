import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Service OpenSubtitles, reconstruit quand la clé change.
///
/// ## Pourquoi un provider plutôt qu'un singleton
///
/// [OpenSubtitlesService] prend sa clé dans son CONSTRUCTEUR, et le champ est
/// `final`. Une instance créée une fois garderait donc la clé de son
/// construction : saisir une nouvelle clé dans les réglages ne prendrait effet
/// qu'au redémarrage, ce qui est exactement le symptôme « j'ai enregistré ma
/// clé et ça n'a rien changé ».
///
/// Déclarer le service dans le graphe Riverpod et faire de la clé une
/// dépendance observée règle le problème à la source : `ref.watch` sur la clé
/// invalide le service, l'écran qui l'écoute se reconstruit, et le nouveau
/// service porte la nouvelle clé.
///
/// Le service reste `const`-constructible : cette factory le reconstruit au
/// changement, pas à chaque build.
final openSubtitlesServiceProvider = Provider<OpenSubtitlesService>((ref) {
  final key = ref.watch(openSubtitlesApiKeyProvider);
  return OpenSubtitlesService(apiKey: key);
});