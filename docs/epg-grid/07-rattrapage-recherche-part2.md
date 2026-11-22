# EPG â€” grille : 7. rattrapage et recherche

> **Partie 2/3**

> Fiche gÃ©nÃ©rÃ©e depuis le code source â€” extraction fidÃ¨le, commentaires compris. Chaque bloc est limitÃ© Ã  200 lignes pour rester copiable sans saturer le presse-papier.


> ⚠️ **ARCHIVÉ** : epg_ai_search.dart (service de recherche IA EPG) a été **supprimé** par le commit 4458d6d. Ce document est conservé pour référence historique uniquement.
Sources : `lib/features/epg/widgets/catch_up_screen.dart`, `lib/utils/epg_search.dart`, `lib/utils/epg_gap_filler.dart`, `lib/services/epg_ai_search.dart`

### 7.1 `CatchUpScreen` â€” rattrapage depuis la grille â€” suite 2/2

`lib/features/epg/widgets/catch_up_screen.dart` Â· lignes 401â€“452

#### `lib/features/epg/widgets/catch_up_screen.dart` Â· lignes 401â€“452 Â· partie 1/1

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

### 7.2 `epg_search` â€” recherche locale

`lib/utils/epg_search.dart` Â· lignes 1â€“67

#### `lib/utils/epg_search.dart` Â· lignes 1â€“67 Â· partie 1/1

```dart
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Recherche des programmes d'une chaÃ®ne dans une fenÃªtre horaire.
///
/// ## Pourquoi pas de dÃ©rÃ©fÃ©rencement forcÃ©
///
/// Les champs `startEpochSec` / `endEpochSec` sont nullables : certaines
/// sources (panel renvoyant des entrÃ©es tronquÃ©es) ne les renseignent pas. Un
/// `!` ici faisait sauter la recherche binaire entiÃ¨re, et l'exception Ã©tait
/// avalÃ©e par le `safeAsync` appelant : la ligne restait vide sans qu'aucun
/// message n'explique pourquoi. On compare donc sur les `DateTime`, qui sont
/// non nulles par construction, et l'on retombe sur un balayage si l'indexation
/// n'est pas fiable.
class EPGSearchEngine {
  const EPGSearchEngine._();

  /// Programmes chevauchant `[windowStart, windowEnd]`, triÃ©s par dÃ©but.
  ///
  /// La liste fournie peut ne pas Ãªtre triÃ©e (le cache EPG la range par chaÃ®ne,
  /// mais un appelant peut fournir un ordre quelconque) : on la copie et on la
  /// trie si nÃ©cessaire. Le tri est indispensable : la recherche dichotomique
  /// ci-dessous en dÃ©pend.
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

    // Recherche dichotomique du premier programme finissant aprÃ¨s le dÃ©but de
    // la fenÃªtre. Les chevauchements au dÃ©but (programme commencÃ© la veille)
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

### 7.3 `epg_gap_filler` â€” comblement de trous

`lib/utils/epg_gap_filler.dart` Â· lignes 1â€“86

#### `lib/utils/epg_gap_filler.dart` Â· lignes 1â€“86 Â· partie 1/1

```dart
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Comblement des trous d'une ligne de la grille EPG.
///
/// ## Pourquoi
///
/// Un flux EPG n'est jamais continu : il y a des trous entre deux Ã©missions, en
/// dÃ©but de journÃ©e, et autour des programmes en cours. Sur une grille dont
/// l'axe horaire est continu, un trou n'est pas un blanc neutre â€” c'est une
/// absence qui se lit comme Â« rien n'est programmÃ© Â», et qui dÃ©cale la lecture
/// de l'axe. On insÃ¨re donc un bloc explicite, ce qui rend le trou visible et
/// dit sa cause.
///
/// Le rÃ©sultat couvre **exactement** `[windowStart, windowEnd]` : la somme des
/// durÃ©es vaut la largeur de la fenÃªtre, et c'est ce qui garantit qu'aucun
/// programme ne se retrouve dÃ©calÃ© d'une colonne.
class EpgGapFiller {
  const EpgGapFiller._();

  /// Titre du bloc de remplacement.
  static const String noDataTitle = 'Aucune donnÃ©e de programme';

  /// ComplÃ¨te la couverture de la fenÃªtre pour une chaÃ®ne.
  ///
  /// Les programmes sont d'abord rognÃ©s aux bornes : un programme commencÃ© la
  /// veille commence Ã  la fenÃªtre. Les chevauchements sont traitÃ©s en rognant
  /// le dÃ©but du suivant, ce qui Ã©vite deux blocs superposÃ©s.
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
      // Borne de dÃ©but : jamais avant le curseur (chevauchement), jamais avant
      // la fenÃªtre.
      final clippedStart = p.start.isAfter(windowStart) ? p.start : windowStart;
      final start = clippedStart.isBefore(cursor) ? cursor : clippedStart;
      // Borne de fin : jamais aprÃ¨s la fenÃªtre, et toujours aprÃ¨s le dÃ©but.
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

    // Trou de fin : du dernier programme (ou du dÃ©but de fenÃªtre) Ã  la fin.
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



