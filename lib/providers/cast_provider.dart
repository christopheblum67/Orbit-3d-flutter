import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/services/cast_playback_service.dart';

/// Service Chromecast partagé par le lecteur (bouton Cast de la footerbar).
final castServiceProvider = Provider<CastPlaybackService>((ref) {
  final service = CastPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});