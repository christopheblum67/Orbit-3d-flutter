import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Recherche dichotomique O(log N) du programme en cours à l'instant [now]
/// dans une liste triée par `start` croissant.
///
/// Remplace le parcours linéaire `.firstWhere` (O(N)) utilisé par la grille et
/// le lecteur : sur ~48 h de programmes par chaîne, le coût passe de milliers
/// de comparaisons à une dizaine maximum, ce qui évite la saccade au scroll.
EPGProgram? epgCurrentProgram(List<EPGProgram> programs, DateTime now) {
  var lo = 0;
  var hi = programs.length - 1;
  var lastStartBeforeNow = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (!programs[mid].start.isAfter(now)) {
      lastStartBeforeNow = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (lastStartBeforeNow == -1) return null;
  final candidate = programs[lastStartBeforeNow];
  return candidate.end.isAfter(now) ? candidate : null;
}

/// Recherche dichotomique O(log N) du prochain programme (start > now) dans
/// une liste triée par `start` croissant.
EPGProgram? epgNextProgram(List<EPGProgram> programs, DateTime now) {
  var lo = 0;
  var hi = programs.length - 1;
  var firstStartAfterNow = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (programs[mid].start.isAfter(now)) {
      firstStartAfterNow = mid;
      hi = mid - 1;
    } else {
      lo = mid + 1;
    }
  }
  return firstStartAfterNow == -1 ? null : programs[firstStartAfterNow];
}

/// Renvoie (programme en cours, programme suivant) en une seule passe.
(EPGProgram?, EPGProgram?) epgCurrentAndNext(
  List<EPGProgram> programs,
  DateTime now,
) =>
    (epgCurrentProgram(programs, now), epgNextProgram(programs, now));

/// Nombre de programmes affichés dans l'aperçu de chaîne (Live TV).
///
/// 7 : la soirée entière reste lisible sans noyer l'aperçu. L'ancienne limite
/// de 5 coupait la grille trop tôt sur les chaînes au rythme de programmes
/// court (journaux, magazines) ; +2 lignes couvrent ces cas (demande produit).
const int kEpgPreviewMaxPrograms = 6;

/// Sélectionne les programmes EPG à afficher dans l'aperçu de chaîne.
///
/// Écarte le passé (`end` postérieur à [now]) et retient au plus
/// [maxPrograms] programmes à venir. Extrait du widget pour être testable :
/// c'est la seule logique métier de l'aperçu, le rendu des lignes restant
/// purement visuel.
List<EPGProgram> epgPreviewPrograms(
  List<EPGProgram> programs,
  DateTime now, {
  int maxPrograms = kEpgPreviewMaxPrograms,
}) =>
    programs
        .where((p) => p.end.isAfter(now))
        .take(maxPrograms)
        .toList(growable: false);
