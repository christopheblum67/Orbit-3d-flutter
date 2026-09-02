import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

String userFriendlyError(Object error) {
  if (error is StreamNetworkException || error is DioException) {
    return 'Impossible de se connecter au serveur. Vérifie ta connexion internet.';
  }
  if (error is StreamAiException) {
    return error.message;
  }
  return 'Une erreur est survenue. Réessaie plus tard.';
}
