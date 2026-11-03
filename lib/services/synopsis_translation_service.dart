import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Origine effective d'un synopsis affiché.
enum SynopsisSource {
  /// Texte déjà en français, tel quel.
  original,

  /// Synopsis français fourni par TMDB (qualité éditoriale, préférée).
  tmdb,

  /// Traduction automatique Google (endpoint unofficial).
  googleTranslate,

  /// Traduction impossible.
  none,
}

extension on SynopsisSource {
  /// Libellé de la source, ou null quand aucune traduction n'a eu lieu.
  String? get label => switch (this) {
        SynopsisSource.original => null,
        SynopsisSource.tmdb => 'Synopsis TMDB',
        SynopsisSource.googleTranslate => 'Traduit par Google',
        SynopsisSource.none => null,
      };
}

/// Résultat de la résolution d'un synopsis.
class TranslatedSynopsis {
  const TranslatedSynopsis({
    required this.text,
    required this.source,
    this.detectedLanguage,
  });

  final String text;
  final SynopsisSource source;

  /// Code ISO de la langue d'origine, quand la détection a réussi.
  final String? detectedLanguage;

  /// Vrai si le texte affiché n'est pas celui d'origine.
  bool get isTranslated =>
      source == SynopsisSource.tmdb || source == SynopsisSource.googleTranslate;

  /// Libellé de source à afficher sous le texte (null si pas de traduction).
  String? get attribution => source.label;
}

/// Résout le synopsis à afficher : conserve la langue cible, privilégie un
/// synopsis TMDB localisé, puis utilise Google Translate en dernier recours.
class SynopsisTranslationService {
  SynopsisTranslationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _endpoint =
      'https://translate.googleapis.com/translate_a/single';

  /// Langues que l'on considère comme « déjà dans la bonne langue ».
  static const _targetLanguage = 'fr';
  static const _languageMarkers = <String, List<String>>{
    'en': [
      ' the ',
      ' and ',
      ' of ',
      ' to ',
      ' is ',
      ' in ',
      ' with ',
      ' from ',
    ],
    'es': [
      ' que ',
      ' y ',
      ' una ',
      ' para ',
      ' por ',
      ' está ',
      ' del ',
      ' los ',
      ' las ',
    ],
    'de': [
      ' der ',
      ' die ',
      ' das ',
      ' und ',
      ' von ',
      ' zu ',
      ' mit ',
      ' ein ',
    ],
    'it': [
      ' che ',
      ' una ',
      ' con ',
      ' sono ',
      ' per ',
      ' degli ',
      ' nella ',
      ' nel ',
    ],
  };

  /// Heuristique : caractères accentués / mots très français.
  static const _frenchMarkers = <String>[
    ' le ',
    ' la ',
    ' les ',
    ' des ',
    ' un ',
    ' une ',
    ' est ',
    ' et ',
    ' du ',
    ' dans ',
    ' pour ',
    ' qui ',
    ' ce ',
    ' plus ',
    ' avec ',
    ' sur ',
    ' au ',
  ];

  /// Décide quoi afficher pour [rawSynopsis].
  Future<TranslatedSynopsis> resolve({
    required String rawSynopsis,
    String? tmdbLocalizedSynopsis,
    String? originalLanguageCode,
    String targetLanguage = _targetLanguage,
  }) async {
    final raw = rawSynopsis.trim();
    final target = _languageCode(targetLanguage);
    if (raw.isEmpty) {
      return const TranslatedSynopsis(
        text: '',
        source: SynopsisSource.none,
      );
    }

    final detected = _detectLanguage(raw, originalLanguageCode);
    if (detected == target || isInLanguage(raw, target)) {
      return TranslatedSynopsis(
        text: raw,
        source: SynopsisSource.original,
        detectedLanguage: detected,
      );
    }

    final tmdbText = (tmdbLocalizedSynopsis ?? '').trim();
    if (tmdbText.isNotEmpty && isInLanguage(tmdbText, target)) {
      return TranslatedSynopsis(
        text: tmdbText,
        source: SynopsisSource.tmdb,
        detectedLanguage: target,
      );
    }

    final translated = await _googleTranslate(raw, detected ?? 'auto', target);
    if (translated == null || translated.trim().isEmpty) {
      return TranslatedSynopsis(
        text: raw,
        source: SynopsisSource.original,
        detectedLanguage: detected,
      );
    }
    return TranslatedSynopsis(
      text: translated.trim(),
      source: SynopsisSource.googleTranslate,
      detectedLanguage: detected,
    );
  }

  /// Vrai si [text] semble déjà en français (heuristique mots français).
  ///
  /// Exposée pour le provider : TMDB sert fr-FR par défaut mais **retombe sur
  /// la langue d'origine** quand la traduction fr n'existe pas (surtout les
  /// séries inédites). Il ne faut alors pas présenter ce texte comme du TMDB
  /// français, sinon un synopsis anglais passerait pour traduit.
  bool isFrench(String text) {
    final lower = ' $text '.toLowerCase();
    final hits =
        _frenchMarkers.where((marker) => lower.contains(marker)).length;
    // 3 marqueurs suffisent à considérer le texte comme francophone.
    return hits >= 3;
  }

  /// Best-effort language check used to reject TMDB's untranslated fallback.
  bool isInLanguage(String text, String languageCode) {
    final language = _languageCode(languageCode);
    if (language == 'fr') return isFrench(text);
    if (language == 'ar') {
      return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    }
    final markers = _languageMarkers[language];
    if (markers == null) return false;
    final lower = ' ${text.toLowerCase()} ';
    return markers.where(lower.contains).length >= 2;
  }

  String _languageCode(String language) =>
      language.toLowerCase().split(RegExp('[-_]')).first;

  /// Détection inexpensive : on se fie au code de langue fourni par l'API si
  /// présent, sinon à l'heuristique [isFrench].
  String? _detectLanguage(String text, String? originalLanguageCode) {
    if (originalLanguageCode != null && originalLanguageCode.isNotEmpty) {
      return originalLanguageCode.toLowerCase();
    }
    if (isFrench(text)) return 'fr';
    for (final language in _languageMarkers.keys) {
      if (isInLanguage(text, language)) return language;
    }
    return null;
  }

  /// Appel à l'endpoint unofficial Google Translate.
  ///
  /// L'API n'est pas publique : elle peut être limitée ou changer de forme.
  /// D'où un timeout court, et un repli silencieux sur le texte d'origine en
  /// cas d'échec (l'utilisateur voit le synopsis, pas une erreur).
  Future<String?> _googleTranslate(
    String text,
    String sourceLang,
    String targetLanguage,
  ) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLang,
          'tl': targetLanguage,
          'dt': 't',
          'q': text,
        },
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      if (response.statusCode != 200) return null;
      return _extractFromPayload(response.data);
    } catch (error) {
      LoggerService.instance.info('SynopsisTranslate indisponible: $error');
      return null;
    }
  }

  /// Google Translate renvoie `[[["traduit","source",null,null,10]],null,...]`.
  String? _extractFromPayload(Object? data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is Map) return _extractFromShape(decoded);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded[0];
      if (first is List && first.isNotEmpty) {
        final buffer = StringBuffer();
        for (final chunk in first) {
          if (chunk is List && chunk.isNotEmpty && chunk[0] is String) {
            buffer.write(chunk[0]);
          }
        }
        return buffer.toString();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _extractFromShape(Map<dynamic, dynamic> data) {
    final first = data[0];
    if (first is! List || first.isEmpty) return null;
    final buffer = StringBuffer();
    for (final chunk in first) {
      if (chunk is List && chunk.isNotEmpty && chunk[0] is String) {
        buffer.write(chunk[0]);
      }
    }
    return buffer.toString();
  }
}
