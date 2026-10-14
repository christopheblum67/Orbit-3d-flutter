import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final translatedSynopsisProvider = FutureProvider.family<TranslatedSynopsis,
    ({String title, String raw, bool isSeries})>((ref, arg) async {
  final service = ref.watch(synopsisTranslationServiceProvider);
  final tmdb = ref.watch(tmdbServiceProvider);

  // Cherche un synopsis TMDB en français. TMDB sert fr-FR par défaut (Dio
  // baseOptions) mais retombe sur la langue d'origine quand la traduction fr
  // n'existe pas : le garde `isFrench` évite de présenter de l'anglais comme
  // une traduction TMDB.
  String? tmdbFrench;
  if (tmdb.hasApiKey && arg.title.trim().isNotEmpty) {
    try {
      String overview = '';
      if (arg.isSeries) {
        final id = await tmdb.searchTvId(arg.title);
        if (id != null) {
          final detail = await tmdb.getTvDetail(id);
          overview = detail?.description ?? '';
        }
      } else {
        final id = await tmdb.searchMovieId(arg.title);
        if (id != null) {
          final detail = await tmdb.getMovieDetail(id);
          overview = detail?.description ?? '';
        }
      }
      if (overview.trim().isNotEmpty && service.isFrench(overview.trim())) {
        tmdbFrench = overview;
      }
    } catch (_) {
      // Non bloquant : on continue sans synopsis TMDB.
    }
  }

  final result = await service.resolve(
    rawSynopsis: arg.raw,
    tmdbFrenchSynopsis: tmdbFrench,
  );

  return result;
});
