import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_key_store.dart';

/// Clé API OpenSubtitles saisie par l'utilisateur.
///
/// L'API refusant toute requête sans clé, une valeur vide rend la recherche
/// en ligne indisponible — elle n'est pas un mode dégradé. Voir
/// [OpenSubtitlesKeyStore] pour le stockage.
final openSubtitlesApiKeyProvider =
    NotifierProvider<OpenSubtitlesApiKeyNotifier, String>(
  OpenSubtitlesApiKeyNotifier.new,
);

class OpenSubtitlesApiKeyNotifier extends Notifier<String> {
  /// Incrémenté à chaque écriture VOLONTAIRE de la clé.
  ///
  /// `load()` est lancé en `unawaited` au démarrage (voir `main.dart`), donc il
  /// se termine souvent APRÈS que l'utilisateur a ouvert les réglages et
  /// enregistré sa clé. Sans ce compteur, ce `load()` tardif publiait l'ancienne
  /// valeur par-dessus la nouvelle : le champ se vidait et la sauvegarde
  /// PARAÎTAIT avoir échoué, alors qu'elle était bien écrite sur le disque.
  int _writeGeneration = 0;

  @override
  String build() => '';

  Future<void> load() async {
    final generationAtStart = _writeGeneration;
    await OpenSubtitlesKeyStore.instance.load();
    // Une saisie a eu lieu pendant le chargement : elle fait foi.
    //
    // NON VÉRIFIÉ PAR TEST : `OpenSubtitlesKeyStore` est un singleton dont on
    // ne peut pas contrôler la latence, donc impossible de reproduire
    // déterministiquement l'ordre « load() démarre, setApiKey() finit,
    // load() termine ». Le test correspondant passait aussi sans ce garde-fou :
    // il ne prouvait rien et a été retiré plutôt que conservé pour le nombre.
    //
    // Ce qui A été vérifié sur l'appareil : la clé saisie est bien écrite et
    // survit au redémarrage. L'ordre précis « load() tardif » ne l'a pas été,
    // et rien ne permet de dire qu'il se produit chez un utilisateur réel.
    if (generationAtStart != _writeGeneration) return;
    state = OpenSubtitlesKeyStore.instance.apiKey;
  }

  Future<void> setApiKey(String value) async {
    _writeGeneration++;
    await OpenSubtitlesKeyStore.instance.setApiKey(value);
    state = OpenSubtitlesKeyStore.instance.apiKey;
  }
}
