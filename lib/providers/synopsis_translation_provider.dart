import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/synopsis_translation_service.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

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
final translatedSynopsisProvider =
    FutureProvider.family<TranslatedSynopsis, ({String title, String raw})>(
        (ref, arg) async {
  final service = ref.watch(synopsisTranslationServiceProvider);
  final tmdb = ref.watch(tmdbServiceProvider);

  // Cherche un synopsis TMDB en français à partir du titre. En cas d'échec
  // (pas de clé API, pas de correspondance), on renvoie null et le service
  // retombe sur la traduction automatique.
  String? tmdbFrench;
  if (tmdb.hasApiKey && arg.title.trim().isNotEmpty) {
    try {
      final id = await tmdb.searchMovieId(arg.title);
      if (id != null) {
        final detail = await tmdb.getMovieDetail(id);
        final overview = detail?.description ?? '';
        if (overview.trim().isNotEmpty) tmdbFrench = overview;
      }
    } catch (_) {
      // Non bloquant : on continue sans synopsis TMDB.
    }
  }

  return service.resolve(
    rawSynopsis: arg.raw,
    tmdbFrenchSynopsis: tmdbFrench,
  );
});
