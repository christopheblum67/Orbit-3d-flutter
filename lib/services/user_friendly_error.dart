import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

String userFriendlyError(Object error) {
  if (error is StreamNetworkException || error is DioException) {
    return 'Impossible de se connecter au serveur. Vérifie ta connexion internet.';
  }
  if (error is StreamAiException) {
    return error.message;
  }
  // Une erreur non classee ne doit pas disparaitre derriere un message
  // generique : on la trace dans les journaux (visibles via le canal natif
  // `OrbitDiag`) sans l'exposer a l'ecran, qui garde un message clean.
  logDiag('ERREUR non classee: ${error.runtimeType} -> $error');
  return 'Une erreur est survenue. Réessaie plus tard.';
}
