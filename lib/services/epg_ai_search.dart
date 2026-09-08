import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/epg_search.dart';

/// Recherche IA « locale » sur le guide TV réel : agent local sans réseau,
/// règles françaises + scoring sur les champs EPG (titre, description,
/// horaires). Ne réinvente aucune source : si la chaîne n'a pas d'EPG, aucun
/// résultat n'est produit (fallback texte possible côté UI).

String _fold(String s) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  final buffer = StringBuffer();
  for (final rune in s.toLowerCase().codeUnits) {
    buffer
        .write(accents[String.fromCharCode(rune)] ?? String.fromCharCode(rune));
  }
  return buffer.toString().replaceAll(RegExp(r"[^a-z0-9 ]+"), ' ').trim();
}

/// Analyse une requête en langage naturel français en [EpgSearchQuery].
///
/// Reconnaît : « maintenant / en ce moment », « ce soir », « demain »,
/// « demain soir », « à 20h(30) », une intention de contenu
/// (film / série / sport / info / documentaire), et les noms de chaînes
/// connues.
class EpgQueryParser {
  EpgQueryParser({List<Channel> channels = const []}) : _channels = channels;

  final List<Channel> _channels;

  EpgSearchQuery parse(String raw) {
    final folded = _fold(raw);
    final now = DateTime.now();

    DateTime? referenceTime;
    var preferLiveNow = false;

    var text = folded;

    final timeRe = RegExp(r"(\d{1,2})h(?:(\d{2}))?");
    final timeMatch = timeRe.firstMatch(text);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
      var target = DateTime(now.year, now.month, now.day, hour, minute);
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }
      referenceTime = target;
      text = text.replaceAll(timeMatch.group(0)!, ' ');
    }
    if (text.contains('en ce moment') ||
        text.contains('maintenant') ||
        text.contains('actuellement')) {
      preferLiveNow = true;
      text = text
          .replaceAll('en ce moment', ' ')
          .replaceAll('maintenant', ' ')
          .replaceAll('actuellement', ' ');
    }
    if (text.contains('ce soir')) {
      referenceTime = DateTime(now.year, now.month, now.day, 21, 0);
      text = text.replaceAll('ce soir', ' ');
    } else if (text.contains('cette nuit')) {
      referenceTime = DateTime(now.year, now.month, now.day, 23, 0);
      text = text.replaceAll('cette nuit', ' ');
    } else if (text.contains('demain soir')) {
      referenceTime = now.add(const Duration(days: 1));
      referenceTime = DateTime(
          referenceTime.year, referenceTime.month, referenceTime.day, 21, 0);
      text = text.replaceAll('demain soir', ' ');
    } else if (text.contains('demain')) {
      final tomorrow = now.add(const Duration(days: 1));
      referenceTime =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20, 0);
      text = text.replaceAll('demain', ' ');
    }
    if (text.contains('hier')) {
      text = text.replaceAll('hier', ' ');
    }

    String? contentTypeIntent;
    if (_containsAny(text, const ['film', 'cinema'])) {
      contentTypeIntent = 'film';
    } else if (_containsAny(text, const ['serie', 'series'])) {
      contentTypeIntent = 'serie';
    } else if (_containsAny(
        text, const ['sport', 'match', 'foot', 'tennis', 'rugby'])) {
      contentTypeIntent = 'sport';
    } else if (_containsAny(
        text, const ['info', 'journal', 'actualite', 'news'])) {
      contentTypeIntent = 'info';
    } else if (_containsAny(text, const ['docu', 'documentaire'])) {
      contentTypeIntent = 'documentaire';
    }

    final tokens =
        text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    final channelKeywords = <String>[];
    final contentKeywords = <String>[];
    for (final token in tokens) {
      if (token.length < 2) continue;
      final matched = _channels.any((c) => _hitsChannelName(c.name, token));
      if (matched) {
        channelKeywords.add(token);
      } else {
        contentKeywords.add(token);
      }
    }

    // Une chaîne reconnue en plusieurs mots (« france 2 ») : relit la phrase.
    for (final channel in _channels) {
      final name = _fold(channel.name);
      if (name.length < 3) continue;
      if (name.contains(' ')) {
        final nameTokens = name.split(' ');
        if (nameTokens.every((t) => tokens.contains(t))) {
          for (final t in nameTokens) {
            if (!channelKeywords.contains(t)) channelKeywords.add(t);
          }
        }
      }
    }

    return EpgSearchQuery(
      queryText: raw.trim(),
      channelKeywords: channelKeywords,
      contentKeywords: contentKeywords,
      referenceTime: referenceTime,
      preferLiveNow: preferLiveNow,
      contentTypeIntent: contentTypeIntent,
    );
  }

  bool _containsAny(String text, List<String> words) {
    for (final w in words) {
      if (text.contains(w)) return true;
    }
    return false;
  }

  bool _hitsChannelName(String channelName, String token) {
    final name = _fold(channelName);
    if (name == token) return true;
    final nameTokens = name.split(' ');
    return nameTokens.any((t) => t == token);
  }
}

/// Moteur de recherche : filtre et score les [EPGProgram] face à la requête.
class EpgAiEngine {
  const EpgAiEngine();

  static const int _defaultLimit = 12;

  List<EpgSearchResult> search({
    required EpgSearchQuery query,
    required List<EPGProgram> allPrograms,
    required List<Channel> channels,
    int limit = _defaultLimit,
  }) {
    final byChannel = {for (final c in channels) c.epgChannelId: c};
    final now = DateTime.now();
    final scored = <EpgSearchResult>[];

    for (final program in allPrograms) {
      final channel = byChannel[program.channelId];
      if (channel == null) continue;
      if (!program.end.isAfter(now)) continue;

      var score = 0.0;
      var matched = false;

      final title = _fold(program.title);
      final desc = _fold(program.description);

      if (query.channelKeywords.isNotEmpty) {
        final name = _fold(channel.name);
        final hit = query.channelKeywords.any(name.contains);
        if (!hit) continue;
        score += 4;
        matched = true;
      }

      if (query.contentKeywords.isNotEmpty) {
        var keywordHits = 0;
        for (final kw in query.contentKeywords) {
          if (title.contains(kw)) {
            keywordHits++;
            score += 2.5;
          } else if (desc.contains(kw)) {
            keywordHits++;
            score += 1.0;
          }
        }
        if (keywordHits == 0) continue;
        matched = true;
      }

      if (!matched && query.contentTypeIntent == null) {
        // Requête sans mot-clé significatif (« que regarder ce soir ») : on
        // ne retient que les programmes en cours ou à venir proches.
        if (!query.preferLiveNow && query.referenceTime == null) {
          if (!program.isLive) continue;
          score += 1;
        }
      }

      if (query.contentTypeIntent != null) {
        final c = query.contentTypeIntent!;
        if (title.contains(c) || desc.contains(c)) {
          score += 1.5;
        }
      }

      if (program.isLive) {
        score += query.preferLiveNow ? 3.0 : 1.0;
      }

      final ref = query.referenceTime;
      if (ref != null) {
        final distance = program.start.difference(ref).inMinutes.abs();
        if (distance < 150) {
          score += 2.5 - (distance / 60).clamp(0.0, 2.5);
        }
      }

      if (score > 0) {
        scored.add(EpgSearchResult(
          program: program,
          channel: channel,
          relevance: (score / 8.0).clamp(0.0, 1.0),
        ));
      }
    }

    scored.sort((a, b) {
      final byScore = b.relevance.compareTo(a.relevance);
      if (byScore != 0) return byScore;
      return a.program.start.compareTo(b.program.start);
    });

    return scored.take(limit).toList();
  }
}
