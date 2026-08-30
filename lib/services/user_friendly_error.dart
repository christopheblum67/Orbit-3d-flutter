import 'package:dio/dio.dart';
import 'api_service.dart';

String userFriendlyError(Object error) {
  if (error is StreamNetworkException || error is DioException) {
    return 'Impossible de se connecter au serveur. Vérifie ta connexion internet.';
  }
  return 'Une erreur est survenue. Réessaie plus tard.';
}