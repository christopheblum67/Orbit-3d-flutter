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

    expect(notifier.state.useTlsImpersonation, isTrue);
    expect(notifier.state.dnsProvider, '1.1.1.1 (Cloudflare DoH)');
    expect(notifier.state.zeroLagPrefetch, isTrue);
    expect(notifier.state.localVideoProxy, isFalse);
    expect(notifier.state.nightFocusEnabled, isFalse);
    expect(notifier.state.nightFocusDialogueBoost, isTrue);
    expect(notifier.state.nightFocusBassKiller, isTrue);
    expect(notifier.state.nightFocusVocalGainDb, 3.0);
    expect(notifier.state.nightFocusAudioShiftMs, 0);
    expect(
      notifier.state.vodSubtitleMode,
      VodSubtitleMode.defaultSelection,
    );
    for (final type in PlaybackContentType.values) {
      expect(notifier.state.configFor(type), const PlayerPerTypeConfig());
    }
  });

  test('modifications persistées et relues', () async {
    SharedPreferences.setMockInitialValues({
      AdvancedSettings.kTlsImpersonation: true,
      AdvancedSettings.kDnsProvider: '8.8.8.8 (Google DoH)',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(advancedSettingsProvider);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.load();

    await notifier.setTlsImpersonation(false);
    await notifier.setDnsProvider('9.9.9.9 (Quad9 DoH)');
    await notifier.setZeroLagPrefetch(false);
    await notifier.setLocalVideoProxy(true);
    await notifier.setNightFocus(true);
    await notifier.setNightFocusDialogueBoost(false);
    await notifier.setNightFocusVocalGainDb(6.0);
    await notifier.setVodSubtitleMode(VodSubtitleMode.forcedOnly);

    expect(notifier.state.useTlsImpersonation, isFalse);
    expect(notifier.state.dnsProvider, '9.9.9.9 (Quad9 DoH)');
    expect(notifier.state.zeroLagPrefetch, isFalse);
    expect(notifier.state.localVideoProxy, isTrue);
    expect(notifier.state.nightFocusEnabled, isTrue);
    expect(notifier.state.nightFocusDialogueBoost, isFalse);
    expect(notifier.state.nightFocusVocalGainDb, 6.0);
    expect(notifier.state.vodSubtitleMode, VodSubtitleMode.forcedOnly);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AdvancedSettings.kTlsImpersonation), isFalse);
    expect(
      prefs.getString(AdvancedSettings.kDnsProvider),
      '9.9.9.9 (Quad9 DoH)',
    );
    expect(prefs.getBool(AdvancedSettings.kZeroLagPrefetch), isFalse);
    expect(prefs.getBool(AdvancedSettings.kLocalVideoProxy), isTrue);
    expect(prefs.getBool(AdvancedSettings.kNightFocus), isTrue);
    expect(prefs.getDouble(AdvancedSettings.kNightFocusVocalGainDb), 6.0);
    expect(
      prefs.getString(AdvancedSettings.kVodSubtitleMode),
      VodSubtitleMode.forcedOnly.name,
    );

    final reloadedContainer = ProviderContainer();
    addTearDown(reloadedContainer.dispose);
    reloadedContainer.read(advancedSettingsProvider);
    final reloaded = reloadedContainer.read(advancedSettingsProvider.notifier);
    await reloaded.load();
    expect(reloaded.state.useTlsImpersonation, isFalse);
    expect(reloaded.state.dnsProvider, '9.9.9.9 (Quad9 DoH)');
    expect(reloaded.state.zeroLagPrefetch, isFalse);
    expect(reloaded.state.localVideoProxy, isTrue);
    expect(reloaded.state.nightFocusEnabled, isTrue);
    expect(reloaded.state.nightFocusVocalGainDb, 6.0);
    expect(reloaded.state.vodSubtitleMode, VodSubtitleMode.forcedOnly);
  });

  test('moteurs et secours sauvegardés sont relus pour chaque type', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.load();

    for (final type in PlaybackContentType.values) {
      for (final engine in PlayerEngine.values) {
        await notifier.setPlayerPrimary(type, engine);
        await notifier.setPlayerFallback(type, engine);
        final reloadedContainer = ProviderContainer();
        final reloaded =
            reloadedContainer.read(advancedSettingsProvider.notifier);
        await reloaded.load();
        expect(reloaded.state.configFor(type).primary, engine);
        expect(reloaded.state.configFor(type).fallback, engine);
        reloadedContainer.dispose();
      }
    }
  });

  test('anciens libellés de moteurs restent lisibles', () async {
    SharedPreferences.setMockInitialValues({
      AdvancedSettings.kPlayerPrimary(PlaybackContentType.vod):
          PlayerEngine.mxPlayer.label,
      AdvancedSettings.kPlayerFallback(PlaybackContentType.vod):
          PlayerEngine.vlc.label,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.load();
    expect(notifier.state.playerVod.primary, PlayerEngine.mxPlayer);
    expect(notifier.state.playerVod.fallback, PlayerEngine.vlc);
  });

  test('le relais est conservé après import des réglages', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.importFromJson(const AdvancedSettings(localVideoProxy: true));
    final reloadedContainer = ProviderContainer();
    addTearDown(reloadedContainer.dispose);
    final reloaded = reloadedContainer.read(advancedSettingsProvider.notifier);
    await reloaded.load();
    expect(reloaded.state.localVideoProxy, isTrue);
  });
}
