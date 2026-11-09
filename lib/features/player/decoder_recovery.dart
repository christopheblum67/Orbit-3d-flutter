import 'package:orbit_3d_flutter/services/video_decoder_prefs.dart';

/// Returns a preferred codec order only when the failed codec is known.
int? decoderRecoveryMode(String? description, VideoDecoderMode preference) {
  if (preference != VideoDecoderMode.auto || description == null) return null;
  if (description.contains('orbitDecoder=software')) return 0;
  if (description.contains('orbitDecoder=hardware')) return 2;
  return null;
}
