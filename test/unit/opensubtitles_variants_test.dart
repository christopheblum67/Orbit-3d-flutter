import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Formes de requete essayees pour resoudre un titre de diffusion.
///
/// `/features` rend zero sur le nom complet d un episode francophone, `full_search`
/// compris. La recherche plein texte exige que les termes correspondent presque
/// tous : le titre de l episode et l accroche d ouverture ne figurent dans aucune
/// entree et font echouer la requete. On descend donc vers des formes de plus en
/// plus courtes jusqu a trouver, la derniere etant les deux derniers mots du nom
/// de serie — souvent le seul fragment retrouve par `full_search`.
void main() {
  const panelTitle =
      '|FR| Monstre : L''histoire de Lizzie Borden 01x02 - Une chatte tenace (MULTI)';

  test('l echelle descend du titre complet vers le nom de serie', () {
    final variants = OpenSubtitlesService.titleVariants(panelTitle);

    expect(variants.first,
        'Monstre : L''histoire de Lizzie Borden - Une chatte tenace');
    expect(variants, contains('Monstre : L''histoire de Lizzie Borden'));
    expect(variants, contains('L''histoire de Lizzie Borden'));
    expect(variants.last, 'Lizzie Borden');
  });

  test('aucune variante derivee ne se termine par le titre de l episode', () {
    // Les deux derniers mots du nom COMPLET sont ceux de l'episode. Les
    // construire depuis le nom complet aurait produit « chatte tenace », qui
    // ne conduit a rien et ramènerait des contenus sans rapport. La premiere
    // variante, elle, contient le titre complet : c'est voulu, on l'essaie en
    // premier.
    final variants = OpenSubtitlesService.titleVariants(panelTitle);
    for (final derived in variants.skip(1)) {
      expect(derived.endsWith('chatte tenace'), isFalse,
          reason: '« $derived » ne mène à aucun contenu');
    }
  });

  test('les variantes sont uniques et font au moins deux mots', () {
    final variants = OpenSubtitlesService.titleVariants(panelTitle);
    expect(variants.toSet().length, variants.length);
    for (final v in variants) {
      expect(v.split(RegExp(r'\s+')).length, greaterThanOrEqualTo(2),
          reason: '« $v » est trop ambigu');
    }
  });

  test('un titre sans suffixe d episode donne une echelle courte', () {
    // « The Office US » d'abord, puis « Office US » : la queue de deux mots
    // reste une tentative legitime, elle ne remplace pas la forme complete.
    final variants =
        OpenSubtitlesService.titleVariants('The Office US S03E12 1080p');
    expect(variants.first, 'The Office US');
    expect(variants.every((v) => v.split(RegExp(r'\s+')).length >= 2), isTrue);
  });

  test('un nom trop court ne donne aucune variante', () {
    expect(OpenSubtitlesService.titleVariants('|FR| Dune (MULTI)'), isEmpty);
    expect(OpenSubtitlesService.titleVariants(''), isEmpty);
  });
}