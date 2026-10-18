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
        SynopsisSource.googleTranslate => 'Traduit automatiquement (Google)',
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

/// Résout le synopsis à afficher en suivant la règle de priorité :
///
/// 1. Synopsis XMLTV présent **et** dans la langue de l'app → conserver tel quel.
/// 2. Synopsis XMLTV présent **mais** dans une autre langue → TMDB (traduction humaine).
/// 3. TMDB absent → Google Translate (traduction automatique).
///
/// L'ordre est dicté par l'ergonomie : le XMLTV du fournisseur est la source
/// primaire. TMDB n'est utilisé que comme fallback de traduction quand le
/// texte n'est pas dans la langue courante de l'app.
class SynopsisTranslationService {
  SynopsisTranslationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _endpoint =
      'https://translate.googleapis.com/translate_a/single';

  /// Langue par défaut (utilisée quand aucune locale n'est fournie).
  static const _defaultLanguage = 'fr';

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

  /// Décide quoi afficher pour [rawSynopsis] en suivant la règle :
  ///
  /// 1. XMLTV présent et dans la langue de l'app → conserver.
  /// 2. XMLTV présent mais dans une autre langue → TMDB.
  /// 3. TMDB absent → Google Translate.
  ///
  /// [tmdbFrenchSynopsis] est le résumé que TMDB renvoie pour la langue
  /// cible (souvent vide si le contenu n'a pas été traduit).
  /// [targetLanguage] est la langue courante de l'app (défaut 'fr').
  Future<TranslatedSynopsis> resolve({
    required String rawSynopsis,
    String? tmdbFrenchSynopsis,
    String? originalLanguageCode,
    String targetLanguage = _defaultLanguage,
  }) async {
    final raw = rawSynopsis.trim();
    final tmdbFr = (tmdbFrenchSynopsis ?? '').trim();

    // 1. XMLTV présent ET déjà dans la langue de l'app → conserver tel quel.
    if (raw.isNotEmpty) {
      final detected = _detectLanguage(raw, originalLanguageCode);
      if (detected == targetLanguage) {
        return TranslatedSynopsis(
          text: raw,
          source: SynopsisSource.original,
          detectedLanguage: detected,
        );
      }
    }

    // 2. XMLTV présent mais dans une autre langue → TMDB (meilleure qualité).
    if (tmdbFr.isNotEmpty) {
      return TranslatedSynopsis(
        text: tmdbFr,
        source: SynopsisSource.tmdb,
        detectedLanguage: targetLanguage,
      );
    }

    // 3. TMDB absent → Google Translate (traduction automatique).
    if (raw.isNotEmpty) {
      final detected = _detectLanguage(raw, originalLanguageCode);
      final translated =
          await _googleTranslate(raw, detected ?? 'auto', targetLanguage);
      if (translated == null || translated.trim().isEmpty) {
        // Google Translate échoue → retourner le texte d'origine tel quel.
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

    // Aucun synopsis disponible.
    return const TranslatedSynopsis(
      text: '',
      source: SynopsisSource.none,
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

  /// Détection inexpensive : on se fie au code de langue fourni par l'API si
  /// présent, sinon à l'heuristique [isFrench].
  String? _detectLanguage(String text, String? originalLanguageCode) {
    if (originalLanguageCode != null && originalLanguageCode.isNotEmpty) {
      return originalLanguageCode.toLowerCase();
    }
    return isFrench(text) ? _defaultLanguage : null;
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
      final data = response.data;
      if (data is String) {
        // Certains TLS/proxies renvoient du texte brut déjà décodé.
        return _extractFromJsonString(data);
      }
      if (data is Map) {
        return _extractFromShape(data);
      }
      return null;
    } catch (error) {
      LoggerService.instance.info('SynopsisTranslate indisponible: $error');
      return null;
    }
  }

  /// Google Translate renvoie `[[["traduit","source",null,null,10]],null,...]`.
  String? _extractFromShape(Map<dynamic, dynamic> data) {
    try {
      final first = data[0];
      if (first is List && first.isNotEmpty) {
        final chunks = first[0];
        if (chunks is List) {
          final buffer = StringBuffer();
          for (final chunk in chunks) {
            if (chunk is List && chunk.isNotEmpty) buffer.write(chunk[0]);
          }
          return buffer.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _extractFromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return _extractFromShape(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }
}
