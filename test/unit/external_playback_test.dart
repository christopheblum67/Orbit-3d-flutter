import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/external_playback.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('provider verification uses only an HTTP(S) origin', () {
    expect(
      providerVerificationUri('https://user:pass@example.test:8443/path?q=1#s'),
      Uri.parse('https://example.test:8443'),
    );
    expect(
      providerVerificationUri('http://example.test/path'),
      Uri.parse('http://example.test'),
    );
    for (final input in [null, '', 'not a URL', 'file:///path', 'ftp://host']) {
      expect(providerVerificationUri(input), isNull);
    }
  });

  test('external launch uses configured engine and checks platform', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('orbit/external_player');
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      await launchExternalPlayback(engine: PlayerEngine.exoPlayer, url: 'url'),
      isFalse,
    );
    expect(
      await launchExternalPlayback(engine: PlayerEngine.vlc, url: 'url'),
      isTrue,
    );
    expect(calls.single.method, 'open');
    expect(calls.single.arguments, {'url': 'url', 'engine': 'vlc'});
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      await launchExternalPlayback(engine: PlayerEngine.mxPlayer, url: 'url'),
      isFalse,
    );
    expect(calls.length, 1);
  });
}
