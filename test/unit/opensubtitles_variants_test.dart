import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';

/// Formes de requête essayées pour résoudre un titre de diffusion, et leur
/// fiabilité.
///
/// `/features` rend zéro sur le nom complet d'un épisode francophone,
/// `full_search` compris. La recherche plein texte exige que les termes
/// correspondent presque tous : le titre de l'épisode et l'accroche
/// d'ouverture ne figurent dans aucune entrée et font échouer la requête.
///
/// La dernière防线 est la fiabilité : une variante tronquée trouve un
/// homonyme — « lizzie borden » mène à « The Lizzie Borden Chronicles », une
/// autre série — et servir ses sous-titres serait pire que de n'en proposer
/// aucun.
void main() {
  const panelTitle =
      '|FR| Monstre : L''histoire de Lizzie Borden 01x02 - Une chatte tenace (MULTI)';

  List<String> queries(String raw) => OpenSubtitlesService.titleVariants(raw)
      .map((v) => v.query)
      .toList();

  test('l échelle descend du titre complet vers le nom de série', () {
    final variants = queries(panelTitle);

    expect(variants.first,
        'Monstre : L''histoire de Lizzie Borden - Une chatte tenace');
    expect(variants, contains('Monstre : L''histoire de Lizzie Borden'));
    expect(variants, contains('L''histoire de Lizzie Borden'));
    expect(variants.last, 'Lizzie Borden');
  });

  test('aucune variante dérivée ne se termine par le titre de l’épisode', () {
    // Les deux derniers mots du nom COMPLET sont ceux de l'épisode. Les
    // construire depuis le nom complet aurait produit « chatte tenace », qui
    // ne conduit à rien. La première variante contient le titre complet : c'est
    // voulu, on l'essaie en premier.
    final variants = queries(panelTitle);
    for (final derived in variants.skip(1)) {
      expect(derived.endsWith('chatte tenace'), isFalse,
          reason: '« $derived » ne mène à aucun contenu');
    }
  });

  test('les variantes tronquées sont marquées comme non fiables', () {
    final variants = OpenSubtitlesService.titleVariants(panelTitle);

    final trusted = variants.where((v) => v.trusted).map((v) => v.query);
    final untrusted = variants.where((v) => !v.trusted).map((v) => v.query);

    // Les formes qui contiennent le nom de série complet restent dignes de
    // confiance.
    expect(trusted, contains('L''histoire de Lizzie Borden'));
    // La queue de deux mots, elle, n'est plus qu'un indice : c'est elle qui
    // ramène l'homonyme.
    expect(untrusted, contains('Lizzie Borden'));
    expect(
      variants.firstWhere((v) => v.query == 'Lizzie Borden').trusted,
      isFalse,
    );
  });

  test('un titre simple n’a que des variantes fiables', () {
    // « The Office US » : rien à tronquer de dangereux, la forme complète est
    // déjà le nom de la série.
    final variants = OpenSubtitlesService.titleVariants('The Office US S03E12 1080p');
    expect(variants.first.query, 'The Office US');
    expect(variants.first.trusted, isTrue);
  });

  test('les variantes sont uniques et font au moins deux mots', () {
    final variants = queries(panelTitle);
    expect(variants.toSet().length, variants.length);
    for (final v in variants) {
      expect(v.split(RegExp(r'\s+')).length, greaterThanOrEqualTo(2),
          reason: '« $v » est trop ambigu');
    }
  });

  test('un nom trop court ne donne aucune variante', () {
    expect(queries('|FR| Dune (MULTI)'), isEmpty);
    expect(queries(''), isEmpty);
  });
}