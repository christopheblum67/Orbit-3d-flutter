# EPG — grille : 7. rattrapage et recherche

> **Partie 2/3**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/catch_up_screen.dart`, `lib/utils/epg_search.dart`, `lib/utils/epg_gap_filler.dart`, `lib/services/epg_ai_search.dart`

### 7.1 `CatchUpScreen` — rattrapage depuis la grille — suite 2/2

`lib/features/epg/widgets/catch_up_screen.dart` · lignes 401–452

#### `lib/features/epg/widgets/catch_up_screen.dart` · lignes 401–452 · partie 1/1

```dart
                        fontWeight: FontWeight.bold,),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Horaire
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(timeStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),),
            ],
          ),
          // Description
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              program.description,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13, height: 1.4,),
            ),
          ],
          // Bouton Replay
          if (replayable && onReplayTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l.epgStartReplay),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6EE7B7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),),
                ),
                onPressed: onReplayTap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
```

### 7.2 `epg_search` — recherche locale

`lib/utils/epg_search.dart` · lignes 1–67

#### `lib/utils/epg_search.dart` · lignes 1–67 · partie 1/1

```dart
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
```

### 7.3 `epg_gap_filler` — comblement de trous

`lib/utils/epg_gap_filler.dart` · lignes 1–86

#### `lib/utils/epg_gap_filler.dart` · lignes 1–86 · partie 1/1

```dart
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
```
