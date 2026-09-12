import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('valeurs par défaut appliquées quand rien n\'est persisté', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(advancedSettingsProvider);
    final notifier = container.read(advancedSettingsProvider.notifier);
    await notifier.load();

    expect(notifier.state.useTlsImpersonation, isTrue);
    expect(notifier.state.dnsProvider, '1.1.1.1 (Cloudflare DoH)');
    expect(notifier.state.zeroLagPrefetch, isTrue);
    expect(notifier.state.nightFocusEnabled, isFalse);
    expect(notifier.state.nightFocusDialogueBoost, isTrue);
    expect(notifier.state.nightFocusBassKiller, isTrue);
    expect(notifier.state.nightFocusVocalGainDb, 3.0);
    expect(notifier.state.nightFocusAudioShiftMs, 0);
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
    await notifier.setNightFocus(true);
    await notifier.setNightFocusDialogueBoost(false);
    await notifier.setNightFocusVocalGainDb(6.0);

    expect(notifier.state.useTlsImpersonation, isFalse);
    expect(notifier.state.dnsProvider, '9.9.9.9 (Quad9 DoH)');
    expect(notifier.state.zeroLagPrefetch, isFalse);
    expect(notifier.state.nightFocusEnabled, isTrue);
    expect(notifier.state.nightFocusDialogueBoost, isFalse);
    expect(notifier.state.nightFocusVocalGainDb, 6.0);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AdvancedSettings.kTlsImpersonation), isFalse);
    expect(prefs.getString(AdvancedSettings.kDnsProvider), '9.9.9.9 (Quad9 DoH)');
    expect(prefs.getBool(AdvancedSettings.kZeroLagPrefetch), isFalse);
    expect(prefs.getBool(AdvancedSettings.kNightFocus), isTrue);
    expect(prefs.getDouble(AdvancedSettings.kNightFocusVocalGainDb), 6.0);

    final reloadedContainer = ProviderContainer();
    addTearDown(reloadedContainer.dispose);
    reloadedContainer.read(advancedSettingsProvider);
    final reloaded =
        reloadedContainer.read(advancedSettingsProvider.notifier);
    await reloaded.load();
    expect(reloaded.state.useTlsImpersonation, isFalse);
    expect(reloaded.state.dnsProvider, '9.9.9.9 (Quad9 DoH)');
    expect(reloaded.state.zeroLagPrefetch, isFalse);
    expect(reloaded.state.nightFocusEnabled, isTrue);
    expect(reloaded.state.nightFocusVocalGainDb, 6.0);
  });
}