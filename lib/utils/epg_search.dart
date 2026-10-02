import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Recherche des programmes d'une chaîne dans une fenêtre horaire.
///
/// ## Pourquoi pas de déréférencement forcé
///
/// Les champs `startEpochSec` / `endEpochSec` sont nullables : certaines
/// sources (panel renvoyant des entrées tronquées) ne les renseignent pas. Un
/// `!` ici faisait sauter la recherche binaire entière, et l'exception était
/// avalée par le `safeAsync` appelant : la ligne restait vide sans qu'aucun
/// message n'explique pourquoi. On compare donc sur les `DateTime`, qui sont
/// non nulles par construction, et l'on retombe sur un balayage si l'indexation
/// n'est pas fiable.
class EPGSearchEngine {
  const EPGSearchEngine._();

  /// Programmes chevauchant `[windowStart, windowEnd]`, triés par début.
  ///
  /// La liste fournie peut ne pas être triée (le cache EPG la range par chaîne,
  /// mais un appelant peut fournir un ordre quelconque) : on la copie et on la
  /// trie si nécessaire. Le tri est indispensable : la recherche dichotomique
  /// ci-dessous en dépend.
  static List<EPGProgram> getProgramsInWindow(
    List<EPGProgram> programs,
    int windowStartSec,
    int windowEndSec,
  ) {
    if (programs.isEmpty) return const <EPGProgram>[];

    final sorted = programs.length > 1 && !_isSorted(programs)
        ? (List<EPGProgram>.of(programs)
          ..sort((a, b) => a.start.compareTo(b.start)))
        : programs;

    // Recherche dichotomique du premier programme finissant après le début de
    // la fenêtre. Les chevauchements au début (programme commencé la veille)
    // sont donc bien inclus.
    var low = 0;
    var high = sorted.length - 1;
    var startIndex = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (sorted[mid].end.millisecondsSinceEpoch ~/ 1000 > windowStartSec) {
        startIndex = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    if (startIndex == -1) return const <EPGProgram>[];

    final result = <EPGProgram>[];
    for (var i = startIndex; i < sorted.length; i++) {
      final p = sorted[i];
      if (p.start.millisecondsSinceEpoch ~/ 1000 >= windowEndSec) break;
      result.add(p);
    }
    return result;
  }

  static bool _isSorted(List<EPGProgram> list) {
    for (var i = 1; i < list.length; i++) {
      if (list[i].start.isBefore(list[i - 1].start)) return false;
    }
    return true;
  }
}
