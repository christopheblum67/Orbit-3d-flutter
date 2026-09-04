import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('valeurs par défaut appliquées quand rien n\'est persisté', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = AdvancedSettingsNotifier();
    await notifier.load();

    expect(notifier.state.useTlsImpersonation, isTrue);
    expect(notifier.state.useCustomDNS, isTrue);
    expect(notifier.state.enableP2PHybrid, isFalse);
    expect(notifier.state.livePlayer, 'ExoPlayer (Interne)');
    expect(notifier.state.autoFrameRate, isTrue);
    expect(notifier.state.enableAiUpscaling, isFalse);
    expect(notifier.state.smartFailover, isTrue);
    expect(notifier.state.hideCredentials, isTrue);
    expect(notifier.state.directToLive, isFalse);
    expect(notifier.state.nightFocusEnabled, isFalse);
    expect(notifier.state.localAiSubtitles, isFalse);
    expect(notifier.state.sportsHighlightsDetection, isTrue);
  });

  test('modifications persistées et relues', () async {
    SharedPreferences.setMockInitialValues({
      AdvancedSettings.kTlsImpersonation: true,
      AdvancedSettings.kCustomDNS: true,
    });
    final notifier = AdvancedSettingsNotifier();
    await notifier.load();

    await notifier.setTlsImpersonation(false);
    await notifier.setCustomDNS(false);
    await notifier.setP2PHybrid(true);
    await notifier.setLivePlayer('VLC (Externe)');
    await notifier.setAiUpscaling(true);
    await notifier.setHideCredentials(false);
    await notifier.setSportsHighlights(false);
    await notifier.setNightFocus(true);

    expect(notifier.state.useTlsImpersonation, isFalse);
    expect(notifier.state.useCustomDNS, isFalse);
    expect(notifier.state.enableP2PHybrid, isTrue);
    expect(notifier.state.livePlayer, 'VLC (Externe)');
    expect(notifier.state.enableAiUpscaling, isTrue);
    expect(notifier.state.hideCredentials, isFalse);
    expect(notifier.state.sportsHighlightsDetection, isFalse);
    expect(notifier.state.nightFocusEnabled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AdvancedSettings.kTlsImpersonation), isFalse);
    expect(prefs.getBool(AdvancedSettings.kP2PHybrid), isTrue);
    expect(prefs.getBool(AdvancedSettings.kNightFocus), isTrue);
    final reloaded = AdvancedSettingsNotifier();
    await reloaded.load();
    expect(reloaded.state.enableP2PHybrid, isTrue);
    expect(reloaded.state.nightFocusEnabled, isTrue);
  });
}
