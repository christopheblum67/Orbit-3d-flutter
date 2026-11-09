import 'package:orbit_3d_flutter/services/api_service.dart';

/// Trois relances à 200, 400 et 800 ms pour les erreurs ordinaires.
/// Un refus de quota ne doit jamais être relancé automatiquement : cela
/// prolongerait la saturation du panel.
Duration? catalogRetryUnlessRateLimited(int retryCount, Object error) {
  if (ApiService.isRateLimitError(error)) return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}
