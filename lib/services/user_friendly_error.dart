import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/app_log.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    show StreamNetworkException;

/// Message d'erreur destiné à l'utilisateur.
///
/// ## La limitation de débit
///
/// Une limitation de débit (429) ne se présente pas comme une panne de
/// connexion. Elle était pourtant ramenée à « Vérifie ta connexion internet » :
/// un diagnostic faux, et surtout silentieux — l'utilisateur voyait un
/// écran vide sans comprendre pourquoi. Le message propre indique la cause et
/// l'heure de réinitialisation quand le serveur la fournit.
String userFriendlyError(Object error) {
  final quota = _rateLimitMessage(error);
  if (quota != null) return quota;

  if (error is StreamNetworkException) return error.message;
  if (error is DioException) {
    if (error.response?.statusCode == 429) {
      return 'Le service limite temporairement les requêtes. '
          'Réessaie dans quelques minutes.';
    }
    return 'Impossible de se joindre au serveur. '
        'Vérifie ta connexion internet.';
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

/// Message de limitation, ou `null` si l'erreur n'en est pas une.
String? _rateLimitMessage(Object error) {
  // Le message est déjà complet quand l'API l'a construit : il contient
  // l'heure de réinitialisation lue dans les en-têtes du serveur.
  if (error is StreamNetworkException) {
    if (error.isRetriable) return null;
    if (error.message.contains('Limite de requêtes')) return error.message;
    return null;
  }
  if (error is DioException && error.response?.statusCode == 429) {
    return 'Le service limite temporairement les requêtes. '
        'Réessaie dans quelques minutes.';
  }
  return null;
}
