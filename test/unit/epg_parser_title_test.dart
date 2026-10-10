import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/epg_stream_parser.dart';

/// Le titre des programmes, tel que le livre un XMLTV RÉEL.
///
/// ## Le défaut
///
/// L'extraction cherchait le texte littéral `<title>`. Or la spécification
/// XMLTV qualifie presque toujours l'élément d'une langue :
///
/// ```xml
/// <title lang="fr">Le Journal</title>
/// ```
///
/// La chaîne `<title>` n'y apparaît donc jamais, la recherche échouait, et le
/// titre revenait VIDE. Conséquence à l'écran : les programmes étaient bien
/// chargés, bien placés, bien colorées — et **sans aucun texte**. La grille
/// paraissait peuplée tout en n'affichant rien.
///
/// C'est aussi ce qui expliquait que la recherche dise « programmes trouvés »
/// alors que l'écran restait vide : la présence des programmes était mesurée,
/// leur CONTENU ne l'était pas.
///
/// ## Pourquoi personne ne l'avait vu
///
/// Tous les jeux d'essai existants écrivaient `<title>18h</title>`, sans
/// attribut. Ils encodaient donc l'hypothèse fausse au lieu de la reality du
/// format, et passaient tous.
void main() {
  String programme({
    String title = '<title lang="fr">Le Journal</title>',
    String desc = '<desc lang="fr">Le résumé de l\'émission.</desc>',
  }) =>
      '<programme start="20240115180000 +0000" stop="20240115190000 +0000" '
      'channel="tf1">$title$desc</programme>';

  test('un titre qualifié par lang est extrait', () {
    final programs = EpgStreamParser.parse('<tv>${programme()}</tv>');

    expect(programs, hasLength(1));
    expect(
      programs.first.title,
      'Le Journal',
      reason: 'le XMLTV réel porte `lang` sur le titre ; une recherche '
          'du littéral `<title>` ne le trouve pas et renvoie vide',
    );
  });

  test('une description qualifiée par lang est extraite', () {
    final programs = EpgStreamParser.parse('<tv>${programme()}</tv>');
    expect(programs.first.description, 'Le résumé de l\'émission.');
  });

  test('un titre sans attribut reste extrait', () {
    // Forme simple : elle fonctionnait déjà, elle doit continuer.
    final programs = EpgStreamParser.parse(
      '<tv>${programme(title: '<title>18h</title>', desc: '<desc>d</desc>')}</tv>',
    );
    expect(programs.first.title, '18h');
    expect(programs.first.description, 'd');
  });

  test('la langue n\'est pas prise pour le texte', () {
    final programs = EpgStreamParser.parse(
      '<tv>${programme(title: '<title lang="de">Nachrichten</title>')}</tv>',
    );
    expect(
      programs.first.title,
      'Nachrichten',
      reason: 'une extraction par expression régulière trop laxiste comprendrait '
          'l\'attribut lang dans le texte',
    );
  });

  test('les entités XML sont résolues dans le titre', () {
    final programs = EpgStreamParser.parse(
      '<tv>${programme(title: '<title>Journal &amp; Météo</title>')}</tv>',
    );
    expect(programs.first.title, 'Journal & Météo');
  });

  test('un titre contenant une balise voisine est pris au bon endroit', () {
    final xml = '<tv>'
        '<programme start="20240115180000 +0000" stop="20240115190000 +0000" '
        'channel="tf1"><desc lang="fr">d</desc>'
        '<title lang="fr">Le Journal</title></programme>'
        '</tv>';
    expect(EpgStreamParser.parse(xml).first.title, 'Le Journal');
  });

  test('un programme sans titre ne renvoie pas de texte parasite', () {
    final programs = EpgStreamParser.parse(
      '<tv><programme start="20240115180000 +0000" stop="20240115190000 +0000" '
      'channel="tf1"></programme></tv>',
    );
    expect(programs, hasLength(1));
    expect(programs.first.title, isEmpty);
  });

  test('le XMLTV complet produit des titres partout', () {
    // Forme réellement servie par un agrégateur : déclaration de langue partout.
    const xml = '<tv generator-info-name="x">'
        '<programme start="20240115180000 +0000" stop="20240115200000 +0000" '
        'channel="tf1"><title lang="fr">Le Journal</title>'
        '<desc lang="fr">Résumé</desc></programme>'
        '<programme start="20240115200000 +0000" stop="20240115220000 +0000" '
        'channel="tf1"><title lang="fr">Le JT</title>'
        '<desc lang="fr">Résumé 2</desc></programme>'
        '</tv>';
    final programs = EpgStreamParser.parse(xml);

    expect(programs.map((p) => p.title), ['Le Journal', 'Le JT']);
    expect(programs.every((p) => p.title.isNotEmpty), isTrue);
  });
}