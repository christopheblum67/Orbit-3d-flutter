// Corrige les mots dont les accents ont été perdus (U+FFFD) dans
// lib/services/api_service.dart, via un dictionnaire de mots complets.
//
// Le caractère U+FFFD remplace EXACTEMENT un caractère accentué ; chaque mot
// du dictionnaire est désambiguïsé par son contexte (cf. la liste extraite
// avant l'édition). On ne touche PAS aux « ? » isolés : ils sont listés à la
// fin pour correction manuelle (à / é / dû… dépend du contexte).
import 'dart:convert';
import 'dart:io';

const _replacement = '\uFFFD';

const dictionary = <String, String>{
  'utilis\uFFFDe': 'utilisée',
  'm\uFFFDmoris\uFFFDs': 'mémorisés',
  'M\uFFFDmorise': 'Mémorise',
  'r\uFFFDsolu': 'résolu',
  'fa\uFFFDon': 'façon',
  'm\uFFFDmoire': 'mémoire',
  'compl\uFFFDte': 'complète',
  'entr\uFFFDes': 'entrées',
  '\uFFFDt\uFFFD': 'été',
  'cha\uFFFDne': 'chaîne',
  'plut\uFFFDt': 'plutôt',
  'g\uFFFDn\uFFFDral': 'général',
  'requ\uFFFDtes': 'requêtes',
  'simultan\uFFFDes': 'simultanées',
  'd\uFFFDlai': 'délai',
  'r\uFFFDseau': 'réseau',
  'requ\uFFFDte': 'requête',
  'tr\uFFFDs': 'très',
  'pr\uFFFDchargeur': 'préchargeur',
  'simultan\uFFFDs': 'simultanés',
  'r\uFFFDessaie': 'réessaie',
  'm\uFFFDme': 'même',
  'r\uFFFDussissait': 'réussissait',
  'relev\uFFFDs': 'relevés',
  'retomb\uFFFDe': 'retombée',
  '\uFFFDpuis\uFFFDs': 'épuisés',
  'r\uFFFDpondre': 'répondre',
  'R\uFFFDponse': 'Réponse',
  'interm\uFFFDdiaire': 'intermédiaire',
  's\uFFFDries': 'séries',
  'D\uFFFDcouvre': 'Découvre',
  'publi\uFFFDes': 'publiées',
  's\uFFFDrie': 'série',
  'd\uFFFDl\uFFFDgu\uFFFEe': 'déléguée',
  'l\uFFFDve': 'lève',
  '\uFFFDchoue': 'échoue',
  '\uFFFDtre': 'être',
  'd\uFFFDfaut': 'défaut',
  'caract\uFFFDres': 'caractères',
  'sp\uFFFDciaux': 'spéciaux',
  'r\uFFFDcup\uFFFDre': 'récupère',
  'd\uFFFDcode': 'décode',
  'm\uFFFDmes': 'mêmes',
  'demand\uFFFDes': 'demandées',
  'repr\uFFFDsentent': 'représentent',
  'fen\uFFFDtre': 'fenêtre',
  'enti\uFFFDre': 'entière',
  'd\uFFFDj\uFFFD': 'déjà',
  't\uFFFDl\uFFFDcharg\uFFFD': 'téléchargé',
  'param\uFFFDtre': 'paramètre',
  'respect\uFFFD': 'respecté',
  'renvoy\uFFFD': 'renvoyé',
  'journ\uFFFDe': 'journée',
  'pass\uFFFD': 'passé',
  'o\uFFFD': 'où',
  '\uFFFDcrans': 'écrans',
  'cha\uFFFDnes': 'chaînes',
  'marqu\uFFFDes': 'marquées',
  'termin\uFFFDs': 'terminés',
  'd\uFFFDfinition': 'définition',
  'utilis\uFFFD': 'utilisé',
  'compl\uFFFDment': 'complément',
  'r\uFFFDplayables': 'rejouables',
  'r\uFFFDtroactivit\uFFFD': 'rétroactivité',
  'd\uFFFDdupliquant': 'dédupliquant',
  'd\uFFFDbut': 'début',
  'termin\uFFFD': 'terminé',
  'expos\uFFFD': 'exposé',
  's\uFFFDpar\uFFFDs': 'séparés',
  '\uFFFDcran': 'écran',
  'malgr\uFFFD': 'malgré',
  'd\uFFFDclare': 'déclare',
  '\uFFFDliminait': 'éliminait',
  'annon\uFFFDant': 'annonçant',
  '\uFFFDtait': 'était',
  'filtr\uFFFD': 'filtré',
  'c\uFFFDt\uFFFD': 'côté',
  'R\uFFFDsum\uFFFD': 'Résumé',
  'pr\uFFFDsentation': 'présentation',
  'renvoy\uFFFDs': 'renvoyés',
  'Premi\uFFFDre': 'Première',
  'cl\uFFFD': 'clé',
  'normalis\uFFFDe': 'normalisée',
  'ordonn\uFFFDe': 'ordonnée',
  'fr\uFFFDquence': 'fréquence',
  'd\uFFFDcroissante': 'décroissante',
  'moiti\uFFFD': 'moitié',
  'pr\uFFFDsentateur': 'présentateur',
  '\uFFFDventuelles': 'éventuelles',
  'retir\uFFFDes': 'retirées',
  'appara\uFFFDtait': 'apparaissait',
  'litt\uFFFDralement': 'littéralement',
  'f\uFFFDvr': 'févr',
  'ao\uFFFDt': 'août',
  'd\uFFFDc': 'déc',
  'cass\uFFFDs': 'cassés',
  'd\uFFFDcodage': 'décodage',
  'r\uFFFDel': 'réel',
  'd\uFFFDclaration': 'déclaration',
  '\uFFFDchapp\uFFFD': 'échappé',
  'r\uFFFDussit': 'réussit',
  'Ignor\uFFFD': 'Ignoré',
  'r\uFFFDellement': 'réellement',
  'd\uFFFDclar\uFFFD': 'déclaré',
  'Priorit\uFFFD': 'Priorité',
  't\uFFFDte': 'tête',
  'd\uFFFDcod\uFFFD': 'décodé',
  'r\uFFFDencode': 'réencode',
  'document\uFFFD': 'documenté',
  'm\uFFFDthode': 'méthode',
  'd\uFFFDtect\uFFFD': 'détecté',
  '\uFFFDchec': 'échec',
  'autoris\uFFFDs': 'autorisés',
  'r\uFFFDpond': 'répond',
  'accept\uFFFD': 'accepté',
  '\uFFFDcarte': 'écarte',
  '\uFFFDmet': 'émet',
  'd\uFFFD': 'dû',
};

void main(List<String> args) {
  final path =
      args.isNotEmpty ? args.first : 'lib/services/api_service.dart';
  final text = utf8.decode(File(path).readAsBytesSync(), allowMalformed: true);

  // Longest first : « téléchargé » avant « tél ».
  final keys = dictionary.keys.toList()..sort((a, b) => b.length - a.length);

  var fixed = 0;
  var output = text;
  for (final k in keys) {
    if (!output.contains(k)) continue;
    output = output.replaceAll(k, dictionary[k]!);
    fixed++;
  }
  fixed = (fixed); // nombre d'occurrences distinctes de mots corrigés

  // Compte aussi les occurrences réelles (le même mot peut apparaître 2×).
  var occurrences = 0;
  var probe = text;
  for (final k in keys) {
    final allMatches = RegExp(RegExp.escape(k)).allMatches(probe);
    occurrences += allMatches.length;
    probe = probe.replaceAll(k, dictionary[k]!);
  }

  File(path).writeAsBytesSync(utf8.encode(output));
  stdout.writeln('$path : $occurrences mot(s) corrigé(s) '
      '(${dictionary.length} entrées)');

  // Liste les « ? » isolés restants, à corriger manuellement.
  final lone = <String>[];
  for (final m in RegExp(patternPlaceholder).allMatches(output)) {}

  for (final mm in RegExp('\uFFFD').allMatches(output)) {
    final s = mm.start > 20 ? mm.start - 20 : 0;
    final end = (mm.start + 20) < output.length ? mm.start + 20 : output.length;
    lone.add('... ${output.substring(s, end).replaceAll('\n', ' ')} ...');
  }
  stdout.writeln('isolés restants : ${lone.length}');
  for (final l in lone) {
    stdout.writeln('   $l');
  }
}

const patternPlaceholder = '__none__';