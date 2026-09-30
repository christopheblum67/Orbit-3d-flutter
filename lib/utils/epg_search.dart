import 'package:orbit_3d_flutter/models/epg_program.dart';

class EPGSearchEngine {
  /// Trouve les programmes d'une chaîne interceptant la fenêtre [windowStartSec, windowEndSec]
  /// Complexité : O(log N) pour la recherche + O(K) pour la collecte des résultats
  static List<EPGProgram> getProgramsInWindow(
    List<EPGProgram> programs,
    int windowStartSec,
    int windowEndSec,
  ) {
    if (programs.isEmpty) return [];

    // Les programmes doivent être triés par startEpochSec (timestamp Unix en secondes)
    int low = 0;
    int high = programs.length - 1;
    int startIndex = -1;

    // Binary search pour trouver le premier programme potentiel
    while (low <= high) {
      final mid = (low + high) >> 1;
      final endEpochSec = programs[mid].endEpochSec!;
      if (endEpochSec > windowStartSec) {
        startIndex = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    if (startIndex == -1) return [];

    final result = <EPGProgram>[];
    var i = startIndex;
    while (i < programs.length && programs[i].startEpochSec! < windowEndSec) {
      result.add(programs[i]);
      i++;
    }
    return result;
  }
}