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
