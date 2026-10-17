import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

/// Vérifie que la persistance des moteurs utilise bien `.name` à la lecture.
/// Auparavant, l'écriture persistait `.name` ('vlc', 'exoPlayer', 'mxPlayer')
/// alors que la lecture tentait de décoder avec `fromLabel()` (basé sur
/// `label` : 'libVLC (Externe)' etc.) → écrasement en `exoPlayer` au `load()`.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('round-trip des moteurs par type de contenu', () async {
    SharedPreferences.setMockInitialValues({
      AdvancedSettings.kPlayerPrimary(PlaybackContentType.live): 'vlc',
      AdvancedSettings.kPlayerFallback(PlaybackContentType.live): 'mxPlayer',
      AdvancedSettings.kPlayerPrimary(PlaybackContentType.vod): 'mxPlayer',
      AdvancedSettings.kPlayerFallback(PlaybackContentType.vod): 'vlc',
      AdvancedSettings.kPlayerPrimary(PlaybackContentType.series): 'exoPlayer',
      AdvancedSettings.kPlayerFallback(PlaybackContentType.series): 'mxPlayer',
      AdvancedSettings.kPlayerPrimary(PlaybackContentType.replay): 'vlc',
      AdvancedSettings.kPlayerFallback(PlaybackContentType.replay): 'exoPlayer',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.load();

    expect(notifier.state.playerLive.primary, PlayerEngine.vlc);
    expect(notifier.state.playerLive.fallback, PlayerEngine.mxPlayer);
    expect(notifier.state.playerVod.primary, PlayerEngine.mxPlayer);
    expect(notifier.state.playerVod.fallback, PlayerEngine.vlc);
    expect(notifier.state.playerSeries.primary, PlayerEngine.exoPlayer);
    expect(notifier.state.playerSeries.fallback, PlayerEngine.mxPlayer);
    expect(notifier.state.playerReplay.primary, PlayerEngine.vlc);
    expect(notifier.state.playerReplay.fallback, PlayerEngine.exoPlayer);
  });

  test('valeurs par défaut après load() quand rien n\'est persisté', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.load();

    expect(notifier.state.playerLive.primary, PlayerEngine.exoPlayer);
    expect(notifier.state.playerLive.fallback, PlayerEngine.vlc);
  });
}
