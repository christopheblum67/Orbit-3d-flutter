import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Comblement des trous d'une ligne de la grille EPG.
///
/// ## Pourquoi
///
/// Un flux EPG n'est jamais continu : il y a des trous entre deux émissions, en
/// début de journée, et autour des programmes en cours. Sur une grille dont
/// l'axe horaire est continu, un trou n'est pas un blanc neutre — c'est une
/// absence qui se lit comme « rien n'est programmé », et qui décale la lecture
/// de l'axe. On insère donc un bloc explicite, ce qui rend le trou visible et
/// dit sa cause.
///
/// Le résultat couvre **exactement** `[windowStart, windowEnd]` : la somme des
/// durées vaut la largeur de la fenêtre, et c'est ce qui garantit qu'aucun
/// programme ne se retrouve décalé d'une colonne.
class EpgGapFiller {
  const EpgGapFiller._();

  /// Titre du bloc de remplacement.
  static const String noDataTitle = 'Aucune donnée de programme';

  /// Complète la couverture de la fenêtre pour une chaîne.
  ///
  /// Les programmes sont d'abord rognés aux bornes : un programme commencé la
  /// veille commence à la fenêtre. Les chevauchements sont traités en rognant
  /// le début du suivant, ce qui évite deux blocs superposés.
  static List<EPGProgram> fill({
    required List<EPGProgram> programs,
    required DateTime windowStart,
    required DateTime windowEnd,
    String channelId = '',
  }) {
    if (!windowEnd.isAfter(windowStart)) return const <EPGProgram>[];

    final overlapping = programs
        .where((p) => p.end.isAfter(windowStart) && p.start.isBefore(windowEnd))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final out = <EPGProgram>[];
    var cursor = windowStart;

    for (final p in overlapping) {
      // Borne de début : jamais avant le curseur (chevauchement), jamais avant
      // la fenêtre.
      final clippedStart = p.start.isAfter(windowStart) ? p.start : windowStart;
      final start = clippedStart.isBefore(cursor) ? cursor : clippedStart;
      // Borne de fin : jamais après la fenêtre, et toujours après le début.
      final end = p.end.isBefore(windowEnd) ? p.end : windowEnd;
      if (!end.isAfter(start)) continue;

      if (start.isAfter(cursor)) {
        out.add(_dummy(channelId, cursor, start));
      }
      out.add(
        EPGProgram(
          channelId: p.channelId.isEmpty ? channelId : p.channelId,
          title: p.title,
          description: p.description,
          start: start,
          end: end,
          category: p.category,
          isDummy: p.isDummy,
        ),
      );
      cursor = end;
    }

    // Trou de fin : du dernier programme (ou du début de fenêtre) à la fin.
    if (cursor.isBefore(windowEnd)) {
      out.add(_dummy(channelId, cursor, windowEnd));
    }
    return out;
  }

  static EPGProgram _dummy(String channelId, DateTime start, DateTime end) =>
      EPGProgram(
        channelId: channelId,
        title: noDataTitle,
        description: '',
        start: start,
        end: end,
        isDummy: true,
      );
}
