# EPG — grille : 1. modèles et utilitaires purs

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/models/epg_program.dart`, `lib/models/epg_models.dart`, `lib/models/epg_search.dart`, `lib/core/utils/epg_day_window.dart`, `lib/core/utils/epg_lookup.dart`, `lib/features/epg/replay_utils.dart`

### 1.1 `EPGProgram` — un programme EPG

`lib/models/epg_program.dart` · lignes 1–139

#### `lib/models/epg_program.dart` · lignes 1–139 · partie 1/1

```dart
import 'package:flutter/material.dart';

enum ProgramCategory {
  movie,
  series,
  sport,
  news,
  documentary,
  other,
}

extension ProgramCategoryX on ProgramCategory {
  int get colorValue {
    switch (this) {
      case ProgramCategory.movie:
        return 0xFF7C4DFF;
      case ProgramCategory.series:
        return 0xFF00E676;
      case ProgramCategory.sport:
        return 0xFFFF5252;
      case ProgramCategory.news:
        return 0xFF448AFF;
      case ProgramCategory.documentary:
        return 0xFFFFAB00;
      case ProgramCategory.other:
        return 0xFF424242;
    }
  }

  int get accentColorValue {
    switch (this) {
      case ProgramCategory.movie:
        return 0xFFB388FF;
      case ProgramCategory.series:
        return 0xFFB9F6CA;
      case ProgramCategory.sport:
        return 0xFFFF8A80;
      case ProgramCategory.news:
        return 0xFF82B1FF;
      case ProgramCategory.documentary:
        return 0xFFFFD740;
      case ProgramCategory.other:
        return 0xFF757575;
    }
  }

  String get displayName {
    switch (this) {
      case ProgramCategory.movie:
        return 'Film';
      case ProgramCategory.series:
        return 'Série';
      case ProgramCategory.sport:
        return 'Sport';
      case ProgramCategory.news:
        return 'Info';
      case ProgramCategory.documentary:
        return 'Docu';
      case ProgramCategory.other:
        return 'Général';
    }
  }

  static ProgramCategory fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'movie':
      case 'film':
        return ProgramCategory.movie;
      case 'series':
      case 'série':
        return ProgramCategory.series;
      case 'sport':
        return ProgramCategory.sport;
      case 'news':
      case 'info':
        return ProgramCategory.news;
      case 'documentary':
      case 'documentaire':
        return ProgramCategory.documentary;
      default:
        return ProgramCategory.other;
    }
  }
}

class EPGProgram {
  final String channelId;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final ProgramCategory category;

  /// Programme factice, généré pour combler un trou de l'EPG.
  ///
  /// Les panels laissent des trous entre deux émissions. Sans bloc de
  /// remplacement, la grille affichait un vide et surtout décalait la lecture :
  /// l'axe horaire étant continu, un trou de 40 min se lisait comme une
  /// absence de programme alors que c'en était un de données. Un bloc
  /// explicite rend le trou visible **et** dit pourquoi.
  final bool isDummy;

  EPGProgram({
    required this.channelId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    this.category = ProgramCategory.other,
    this.isDummy = false,
  });

  DateTime get startTime => start;
  DateTime get endTime => end;
  int get durationMinutes => end.difference(start).inMinutes;
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }
}

extension EPGProgramX on EPGProgram {
  int get durationSec => end.difference(start).inSeconds;

  bool get isLiveNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  double get progress {
    if (!isLiveNow) return 0.0;
    final now = DateTime.now();
    return (now.difference(start).inSeconds / durationSec).clamp(0.0, 1.0);
  }

  Color get categoryColor => Color(category.colorValue);
  Color get accentColor => Color(category.accentColorValue);
  String get categoryDisplayName => category.name.toUpperCase();
}
```

### 1.2 `epg_models` — types annexes

`lib/models/epg_models.dart` · lignes 1–98

#### `lib/models/epg_models.dart` · lignes 1–98 · partie 1/1

```dart
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/channel.dart';

/// Catégorie d'abonnement (pour orbite par genre/thème)
class SubscriptionCategory {
  final String id;
  final String name;
  final Color orbitColor;

  const SubscriptionCategory({
    required this.id,
    required this.name,
    this.orbitColor = Colors.purpleAccent,
  });
}

/// Chaîne en tant que planète orbitale (modèle 3D)
class OrbitChannelPlanet {
  final String id;
  final String name;
  final String categoryId;
  final String logoUrl;
  final double userPreferenceScore; // 0.0 à 1.0
  final String currentProgramTitle;
  final double currentProgramProgress; // 0.0 à 1.0

  OrbitChannelPlanet({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.logoUrl,
    this.userPreferenceScore = 0.5,
    required this.currentProgramTitle,
    required this.currentProgramProgress,
  });

  double getOrbitRadius(double baseRadius) {
    return baseRadius + ((1.0 - userPreferenceScore) * 180.0);
  }

  factory OrbitChannelPlanet.fromChannel(
    Channel channel, {
    double preference = 0.5,
    String currentProgram = '',
    double progress = 0.0,
  }) {
    return OrbitChannelPlanet(
      id: channel.id,
      name: channel.name,
      categoryId: channel.categoryId,
      logoUrl: channel.logoUrl,
      userPreferenceScore: preference,
      currentProgramTitle: currentProgram,
      currentProgramProgress: progress,
    );
  }
}

/// Favoris pour le système solaire (Soleil + planètes)
class FavoriteChannelNode {
  final String id;
  final String name;
  final String logoUrl;
  final String currentProgramTitle;
  final double currentProgramProgress;
  final bool isTopFavorite;

  FavoriteChannelNode({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.currentProgramTitle,
    required this.currentProgramProgress,
    this.isTopFavorite = false,
  });
}

/// Résultat de recherche nébuleuse
class NebulaSearchResult {
  final String title;
  final String type; // 'Live', 'VOD', 'Series', 'Channel', 'EPG'
  final double relevanceScore;
  final String? subtitle;
  final String? streamUrl;
  final String? id; // ID pour navigation vers detail (VOD/Series)

  NebulaSearchResult({
    required this.title,
    required this.type,
    required this.relevanceScore,
    this.subtitle,
    this.streamUrl,
    this.id,
  });
}

/// Layout pour le dual screen
enum DualScreenLayout { splitEqual, mainWithPip }
```

### 1.3 `epg_search` — modèle de recherche

`lib/models/epg_search.dart` · lignes 1–53

#### `lib/models/epg_search.dart` · lignes 1–53 · partie 1/1

```dart
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Requête PGL issue d'une saisie ou d'une élocution en langage naturel.
///
/// Exemples reconnus : « que passe sur TF1 ce soir », « un film à 21h »,
/// « match maintenant », « sFR info demain soir ».
class EpgSearchQuery {
  final String queryText;
  final List<String> channelKeywords;
  final List<String> contentKeywords;

  /// Moment visé (« ce soir », « à 20h30 », « demain soir »...). `null` = pas
  /// de contrainte horaire.
  final DateTime? referenceTime;

  /// L'utilisateur veut ce qui passe actuellement (« en ce moment »).
  final bool preferLiveNow;

  /// Intention de contenu détectée : film, série, sport, info, documentaire.
  final String? contentTypeIntent;

  const EpgSearchQuery({
    required this.queryText,
    this.channelKeywords = const [],
    this.contentKeywords = const [],
    this.referenceTime,
    this.preferLiveNow = false,
    this.contentTypeIntent,
  });
}

/// Résultat de recherche EPG IA : un programme relié à sa chaîne réelle.
class EpgSearchResult {
  final EPGProgram program;
  final Channel channel;
  final double relevance;

  const EpgSearchResult({
    required this.program,
    required this.channel,
    required this.relevance,
  });

  bool get isLiveNow => program.isLive;

  String get startLabel {
    final d = program.start;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
```

### 1.4 Fenêtre de jour (`epg_day_window`)

`lib/core/utils/epg_day_window.dart` · lignes 1–46

#### `lib/core/utils/epg_day_window.dart` · lignes 1–46 · partie 1/1

```dart
/// Fenêtre d'une journée de guide TV : minuit → minuit.
///
/// ## Pourquoi une seule définition
///
/// La grille EPG et le Replay doivent partager la même notion de « la journée »
/// : c'est le même programme, donc la même heure. On avait d'un côté
/// « maintenant moins 1 h → plus 24 h » et de l'autre « 00:00 → 23:59 », soit
/// deux emplacements différents pour un même programme selon l'écran où on le
/// regarde — et la grille ne pouvait pas non plus afficher la matinée si la
/// fenêtre ne couvrait pas minuit.
///
/// L'implémentation de la grille demande `gridStartTime` en `DateTime` et une
/// largeur totale fixe (`24 h × échelle`), donc la fenêtre est calée sur minuit
/// local. C'est le fuseau de l'appareil, ce qui est le comportement attendu :
/// « 20 h » dans un guide doit être l'heure locale de la personne qui regarde.
class EpgDayWindow {
  const EpgDayWindow({required this.start, required this.end});

  /// Début de la journée (minuit, heure locale).
  final DateTime start;

  /// Fin de la journée (minuit du lendemain, exclusive).
  final DateTime end;

  /// Longueur de la fenêtre : 24 h, sans exception.
  int get minutes => end.difference(start).inMinutes;

  /// La journée qui contient [moment].
  factory EpgDayWindow.of(DateTime moment) {
    final day = DateTime(moment.year, moment.month, moment.day);
    return EpgDayWindow(start: day, end: day.add(const Duration(days: 1)));
  }

  /// La journée en cours.
  factory EpgDayWindow.ofNow() => EpgDayWindow.of(DateTime.now());

  /// La fenêtre d'un jour de calendrier donné, pour le Replay.
  factory EpgDayWindow.ofDay(DateTime day) => EpgDayWindow(
        start: DateTime(day.year, day.month, day.day),
        end: DateTime(day.year, day.month, day.day + 1),
      );

  @override
  String toString() =>
      'EpgDayWindow(${start.toIso8601String()} → ${end.toIso8601String()})';
}
```

### 1.5 Lookup EPG (`epg_lookup`)

`lib/core/utils/epg_lookup.dart` · lignes 1–50

#### `lib/core/utils/epg_lookup.dart` · lignes 1–50 · partie 1/1

```dart
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
```

### 1.6 `isReplayableProgram` — la règle « rejouable »

`lib/features/epg/replay_utils.dart` · lignes 1–14

#### `lib/features/epg/replay_utils.dart` · lignes 1–14 · partie 1/1

```dart
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Un programme EPG est rejouable quand sa chaîne propose le replay/DVR
/// (timeshift) ET que le programme est déjà terminé (pas en cours de
/// diffusion, pas à venir).
bool isReplayableProgram(
  EPGProgram program, {
  required DateTime now,
  required bool channelSupportsReplay,
}) {
  if (!channelSupportsReplay) return false;
  if (program.isLive) return false;
  return program.end.isBefore(now);
}
```
