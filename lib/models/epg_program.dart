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
