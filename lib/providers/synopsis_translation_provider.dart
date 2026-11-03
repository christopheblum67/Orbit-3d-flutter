import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/synopsis_translation_service.dart';

/// Service de traduction, partagé.
final synopsisTranslationServiceProvider = Provider<SynopsisTranslationService>(
  (ref) => SynopsisTranslationService(),
);

/// Synopsis traduit pour un contenu, calculé une seule fois par identifiant.
///
/// Ordre de résolution (cf. [SynopsisTranslationService]) :
/// 1. synopsis français TMDB s'il existe ;
/// 2. texte d'origine s'il est déjà en français ;
/// 3. traduction automatique Google Translate.
///
/// `isSeries` est nécessaire : le catalogue série ne répond pas aux endpoints
/// film. Sans lui, `searchMovieId`/`getMovieDetail` ne trouvaient rien pour
/// une série (« Avatar : Seven Havens »…) et toute la résolution retombait
/// brutale sur la traduction automatique, d'où des synopsis restés en anglais.
final translatedSynopsisProvider = FutureProvider.family<
    TranslatedSynopsis,
    ({
      String title,
      String raw,
      bool isSeries,
      String? originalLanguageCode,
    })>((ref, arg) async {
  final service = ref.watch(synopsisTranslationServiceProvider);
  final tmdb = ref.watch(tmdbServiceProvider);
  final appLanguage = ref.watch(preferencesProvider.select((p) => p.language));
  final tmdbLanguage = _tmdbLanguageFor(appLanguage);

  String? tmdbLocalized;
  if (tmdb.hasApiKey && arg.title.trim().isNotEmpty) {
    try {
      String overview = '';
      if (arg.isSeries) {
        final id = await tmdb.searchTvId(arg.title, language: tmdbLanguage);
        if (id != null) {
          final detail = await tmdb.getTvDetail(id, language: tmdbLanguage);
          overview = detail?.description ?? '';
        }
      } else {
        final id = await tmdb.searchMovieId(arg.title, language: tmdbLanguage);
        if (id != null) {
          final detail = await tmdb.getMovieDetail(id, language: tmdbLanguage);
          overview = detail?.description ?? '';
        }
      }
      if (overview.trim().isNotEmpty &&
          overview.trim() != arg.raw.trim() &&
          service.isInLanguage(overview, appLanguage)) {
        tmdbLocalized = overview;
      }
    } catch (_) {
      // Non bloquant : on continue sans synopsis TMDB.
    }
  }

  final result = await service.resolve(
    rawSynopsis: arg.raw,
    tmdbLocalizedSynopsis: tmdbLocalized,
    originalLanguageCode: arg.originalLanguageCode,
    targetLanguage: appLanguage,
  );

  return result;
});

String _tmdbLanguageFor(String language) => switch (language.toLowerCase()) {
      'en' => 'en-US',
      'es' => 'es-ES',
      'de' => 'de-DE',
      'it' => 'it-IT',
      'ar' => 'ar-SA',
      _ => 'fr-FR',
    };
