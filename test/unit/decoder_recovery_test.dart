import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/decoder_recovery.dart';
import 'package:orbit_3d_flutter/services/video_decoder_prefs.dart';

void main() {
  test('only swaps known codecs in automatic mode', () {
    expect(
        decoderRecoveryMode('orbitDecoder=software', VideoDecoderMode.auto), 0);
    expect(
        decoderRecoveryMode('orbitDecoder=hardware', VideoDecoderMode.auto), 2);
    expect(decoderRecoveryMode('orbitDecoder=unknown', VideoDecoderMode.auto),
        isNull);
    expect(
        decoderRecoveryMode('orbitDecoder=software', VideoDecoderMode.software),
        isNull);
    expect(
        decoderRecoveryMode('orbitDecoder=hardware', VideoDecoderMode.hardware),
        isNull);
  });
}
