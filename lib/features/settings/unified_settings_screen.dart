import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/services/epg_buffer_store.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_http_validators.dart';
import 'package:orbit_3d_flutter/services/conditional_xmltv_cache.dart';
import 'package:orbit_3d_flutter/services/video_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_tab_bar.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart'
    show showPlayerEngineConfigSheet;
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/widevine_config_tile.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/update_dialog.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_account_screen.dart';

/// Configuration unifiée (style XCIPTV) — fusionne SettingsScreen + AdvancedSettingsScreen.
/// Organisé en sections logiques avec icônes explicites, navigation au D-pad/TV.
class UnifiedSettingsScreen extends ConsumerStatefulWidget {
  const UnifiedSettingsScreen({super.key});

  @override
  ConsumerState<UnifiedSettingsScreen> createState() =>
      _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends ConsumerState<UnifiedSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: SettingsTabBar.icons.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _tabLabel(int i) {
    final l = AppLocalizations.of(context);
    return switch (i) {
      0 => l.tabAccount,
      1 => l.tabNetwork,
      2 => l.tabPlayer,
      3 => l.tabSecurity,
      4 => l.tabAudio,
      _ => l.tabAdvanced,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: AppLocalizations.of(context).profileBack,
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(AppLocalizations.of(context).settingsTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).settingsPlaybackEngines,
            onPressed: () => showPlayerEngineConfigSheet(context),
            icon: const Icon(Icons.settings_input_component),
          ),
        ],
        bottom: SettingsTabBar(
          controller: _tabController,
          labels: [
            for (var i = 0; i < SettingsTabBar.icons.length; i++) _tabLabel(i),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AccountSection(),
          _NetworkSection(),
          _PlayerSection(),
          _SecuritySection(),
          _AudioSection(),
          _AdvancedSection(),
        ],
      ),
    );
  }
}

/// ─── Tuile de navigation réutilisable ────────────────────────────
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: scheme.primary),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          trailing: trailing ??
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// ─── COMPTE ──────────────────────────────────────────────────────
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sub = ref.watch(activeSubscriptionProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSectionTitle(l.sectionAccountProfile),
        _NavTile(
          icon: Icons.manage_accounts_rounded,
          title: l.accountProfiles,
          subtitle: l.accountProfilesSubtitle,
          onTap: () => context.go('/profiles'),
        ),
        _NavTile(
          icon: Icons.subscriptions_rounded,
          title: l.accountSubscriptions,
          subtitle: sub == null
              ? l.accountNoSubscription
              : '${sub.name} · ${sub.validityLabel}',
          onTap: () => context.go('/subscriptions'),
        ),
        _NavTile(
          icon: Icons.settings_outlined,
          title: l.accountPreferences,
          subtitle: l.accountPreferencesSubtitle,
          onTap: () => context.go('/profile/preferences'),
        ),
        _NavTile(
          icon: Icons.memory_rounded,
          title: l.accountDeviceProfile,
          subtitle: l.accountDeviceProfileSubtitle(
            ref.watch(deviceProfileProvider).label,
          ),
          onTap: () => context.go('/onboarding'),
        ),
        const SizedBox(height: 8),
        SettingsSectionTitle(l.sectionCloudSync),
        _NavTile(
          icon: Icons.account_circle_outlined,
          title: l.settingsCloudAccount,
          subtitle: l.settingsCloudSignIn,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CloudAccountScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(l.settingsSyncUnavailable),
          subtitle: Text(l.settingsSyncUnavailableHelp),
        ),
      ],
    );
  }
}

/// ─── RÉSEAU ──────────────────────────────────────────────────────
class _NetworkSection extends ConsumerWidget {
  const _NetworkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSectionTitle(l.sectionAntiThrottle),
        SettingsSwitchTile(
          title: l.tlsImpersonation,
          subtitle: l.tlsImpersonationSubtitle,
          value: s.useTlsImpersonation,
          onChanged: n.setTlsImpersonation,
          icon: Icons.shield_outlined,
        ),
        SettingsSwitchTile(
          title: l.localVideoProxy,
          subtitle: l.localVideoProxySubtitle,
          value: s.localVideoProxy,
          onChanged: n.setLocalVideoProxy,
          icon: Icons.router_outlined,
        ),
        const _DnsProviderTile(),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionCloudflare),
        SettingsActionTile(
          title: l.cloudflareReset,
          subtitle: l.cloudflareResetSubtitle,
          icon: Icons.restore_outlined,
          onTap: () async {
            n.setTlsImpersonation(false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.snackCloudflareReset),
                  backgroundColor: const Color(0xFF00CFE8),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _DnsProviderTile extends ConsumerWidget {
  const _DnsProviderTile();

  static const _options = <String>[
    '1.1.1.1 (Cloudflare DoH)',
    '8.8.8.8 (Google DoH)',
    '9.9.9.9 (Quad9 DoH)',
    'Automatique (Système)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.dns_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l.dnsProvider, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            l.dnsProviderSubtitle,
            style: const TextStyle(fontSize: 11),
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _options.contains(s.dnsProvider)
                  ? s.dnsProvider
                  : _options.last,
              isDense: true,
              items: [
                for (final o in _options)
                  DropdownMenuItem(
                    value: o,
                    child: Text(o == _options.last ? l.settingsSystemAutomatic : o),
                  ),
              ],
              onChanged: (v) {
                if (v != null) n.setDnsProvider(v);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── LECTEUR ─────────────────────────────────────────────────────
class _PlayerSection extends ConsumerWidget {
  const _PlayerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSectionTitle(l.sectionEngines),
        const _PlayerEngineTile(),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Sous-titres'),
        const _SubtitleModeTile(),
        const SizedBox(height: 8),
        SettingsSectionTitle(l.sectionAudioNight),
        SettingsNavTile(
          icon: Icons.nightlight_outlined,
          title: l.audioAndNightFocus,
          subtitle: l.audioAndNightFocusSubtitle,
          onTap: () => showAudioControlsSheet(context),
        ),
        const SizedBox(height: 8),
        SettingsSectionTitle(l.sectionZapping),
        SettingsSwitchTile(
          title: l.instantZapping,
          subtitle: l.instantZappingSubtitle,
          value: s.zeroLagPrefetch,
          onChanged: n.setZeroLagPrefetch,
          icon: Icons.fast_forward_outlined,
        ),
        const SizedBox(height: 8),
        SettingsSectionTitle(l.sectionMemory),
        const MemorySettingsPanel(),
      ],
    );
  }
}

class _SubtitleModeTile extends ConsumerWidget {
  const _SubtitleModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final labels = <VodSubtitleMode, String>{
      VodSubtitleMode.defaultSelection: l.settingsSubtitleDefault,
      VodSubtitleMode.forcedOnly: l.settingsSubtitleForced,
      VodSubtitleMode.disabled: l.settingsSubtitleOff,
    };
    final mode = ref.watch(advancedSettingsProvider).vodSubtitleMode;
    return SettingsNavTile(
      icon: Icons.subtitles_outlined,
      title: l.settingsSubtitleMoviesSeries,
      subtitle: labels[mode]!,
      onTap: () async {
        final picked = await showDialog<VodSubtitleMode>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l.settingsSubtitles),
            children: [
              for (final entry in labels.entries)
                ListTile(
                  autofocus: entry.key == mode,
                  selected: entry.key == mode,
                  leading: Icon(
                    entry.key == mode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(entry.value),
                  onTap: () => Navigator.of(ctx).pop(entry.key),
                ),
            ],
          ),
        );
        if (picked != null) {
          await ref
              .read(advancedSettingsProvider.notifier)
              .setVodSubtitleMode(picked);
        }
      },
    );
  }
}

class _PlayerEngineTile extends ConsumerWidget {
  const _PlayerEngineTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    return SettingsNavTile(
      icon: Icons.play_circle_outline,
      title: l.enginesTile,
      subtitle: l.enginesSubtitle(
        s.playerLive.primary.label,
        s.playerVod.primary.label,
      ),
      onTap: () => showPlayerEngineConfigSheet(context),
    );
  }
}

/// ─── SÉCURITÉ ────────────────────────────────────────────────────
class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSectionTitle(l.sectionParental),
        _NavTile(
          icon: Icons.gpp_good_outlined,
          title: l.parentalControl,
          subtitle: l.parentalControlSubtitle,
          onTap: () => context.go('/parental'),
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.settingsProtectedPlayback),
        const WidevineConfigTile(),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionResilience),
        SettingsSwitchTile(
          title: l.autoReconnectLive,
          subtitle: l.autoReconnectLiveSubtitle,
          value: s.zeroLagPrefetch, // réutilise le flag existant pour la démo
          onChanged: n.setZeroLagPrefetch,
          icon: Icons.sync_rounded,
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionLegal),
        _NavTile(
          icon: Icons.balance_outlined,
          title: l.legalNotice,
          subtitle: l.legalNoticeSubtitle,
          onTap: () => context.go('/legal?flow=settings'),
        ),
      ],
    );
  }
}

/// ─── AUDIO ───────────────────────────────────────────────────────
class _AudioSection extends ConsumerWidget {
  const _AudioSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSectionTitle(l.nightFocusTitle),
        SettingsSwitchTile(
          title: l.nightFocusEnable,
          subtitle: l.nightFocusEnableSubtitle,
          value: s.nightFocusEnabled,
          onChanged: n.setNightFocus,
          icon: Icons.nightlight_round,
        ),
        SettingsSwitchTile(
          title: l.dialogueBoost,
          subtitle: l.dialogueBoostSubtitle,
          value: s.nightFocusDialogueBoost,
          onChanged: n.setNightFocusDialogueBoost,
          icon: Icons.record_voice_over,
        ),
        SettingsSwitchTile(
          title: l.bassKiller,
          subtitle: l.bassKillerSubtitle,
          value: s.nightFocusBassKiller,
          onChanged: n.setNightFocusBassKiller,
          icon: Icons.equalizer,
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionAvSync),
        SettingsSwitchTile(
          title: l.audioShift,
          subtitle: l.audioShiftSubtitle,
          value: s.nightFocusAudioShiftMs != 0,
          onChanged: (v) => n.setNightFocusAudioShiftMs(v ? 0 : 50),
          icon: Icons.timer_outlined,
        ),
        if (s.nightFocusAudioShiftMs != 0) ...[
          SettingsActionTile(
            title: l.manualAvCalibration,
            subtitle: l.manualAvCalibrationSubtitle(s.nightFocusAudioShiftMs),
            icon: Icons.timer_outlined,
            onTap: () => _showAvSyncDialog(context, ref),
          ),
        ],
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionOutput),
        SettingsSwitchTile(
          title: l.volumeNormalization,
          subtitle: l.volumeNormalizationSubtitle,
          value: s.nightFocusVolumeNormalization,
          onChanged: n.setNightFocusVolumeNormalization,
          icon: Icons.volume_up_outlined,
        ),
      ],
    );
  }

  Future<void> _showAvSyncDialog(BuildContext context, WidgetRef ref) async {
    final n = ref.read(advancedSettingsProvider.notifier);
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: '0');

    final cancelFocus = FocusNode();
    final confirmFocus = FocusNode();
    final fieldFocus = FocusNode();

    void requestFocus(FocusNode focus) {
      if (context.mounted) {
        FocusScope.of(context).requestFocus(focus);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.avSyncDialogTitle),
        content: Focus(
          focusNode: fieldFocus,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                final ms = int.tryParse(controller.text) ?? 0;
                n.setNightFocusAudioShiftMs(ms);
                Navigator.pop(ctx);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                requestFocus(cancelFocus);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: controller,
            focusNode: fieldFocus,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: l.avSyncDialogLabel,
              hintText: l.avSyncDialogHint,
            ),
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              final ms = int.tryParse(controller.text) ?? 0;
              n.setNightFocusAudioShiftMs(ms);
              Navigator.pop(ctx);
            },
          ),
        ),
        actions: [
          Focus(
            focusNode: cancelFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.pop(ctx);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(confirmFocus);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                requestFocus(fieldFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
          ),
          Focus(
            focusNode: confirmFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                final ms = int.tryParse(controller.text) ?? 0;
                n.setNightFocusAudioShiftMs(ms);
                Navigator.pop(ctx);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(cancelFocus);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                requestFocus(fieldFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FilledButton(
              onPressed: () {
                final ms = int.tryParse(controller.text) ?? 0;
                n.setNightFocusAudioShiftMs(ms);
                Navigator.pop(ctx);
              },
              child: Text(l.apply),
            ),
          ),
        ],
      ),
    );

    cancelFocus.dispose();
    confirmFocus.dispose();
    fieldFocus.dispose();
  }
}

/// ─── AVANCÉ ──────────────────────────────────────────────────────
class _AdvancedSection extends ConsumerWidget {
  const _AdvancedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsSectionTitle(l.sectionAccessibility),
        SettingsSwitchTile(
          title: l.highContrast,
          subtitle: l.highContrastSubtitle,
          value: ref.watch(advancedSettingsProvider).highContrast,
          onChanged:
              ref.read(advancedSettingsProvider.notifier).setHighContrast,
          icon: Icons.contrast_outlined,
        ),
        SettingsSwitchTile(
          title: l.dpadNavigation,
          subtitle: l.dpadNavigationSubtitle,
          value: ref.watch(advancedSettingsProvider).dpadNavigation,
          onChanged:
              ref.read(advancedSettingsProvider.notifier).setDpadNavigation,
          icon: Icons.tv_rounded,
        ),
        SettingsSwitchTile(
          title: l.fontSize,
          subtitle: l.fontSizeSubtitle,
          value: ref.watch(advancedSettingsProvider).fontSizeScale > 1.0,
          onChanged: (value) {
            ref.read(advancedSettingsProvider.notifier).setFontSizeScale(
                  value ? 1.3 : 1.0,
                );
          },
          icon: Icons.format_size_outlined,
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionRecommendations),
        _NavTile(
          icon: Icons.recommend_rounded,
          title: l.matchmaking,
          subtitle: l.matchmakingSubtitle,
          onTap: () => context.go('/matchmaking'),
        ),
        _NavTile(
          icon: Icons.filter_list_rounded,
          title: l.settingsCategoryFilters,
          subtitle: l.settingsCategoryFiltersHelp,
          onTap: () => context.push('/category-filters'),
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionDiagnostics),
        if (Platform.isAndroid)
          _NavTile(
            icon: Icons.system_update_alt,
            title: l.updateTitle,
            subtitle: l.updateSettingsSubtitle,
            onTap: () => showUpdateDialog(context),
          ),
        _NavTile(
          icon: Icons.cleaning_services_outlined,
          title: l.clearCaches,
          subtitle: l.clearCachesSubtitle,
          onTap: () => _clearAllCaches(context, ref),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        _NavTile(
          icon: Icons.restart_alt_outlined,
          title: l.resetApp,
          subtitle: l.resetAppSubtitle,
          onTap: () => _factoryReset(context, ref),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        const _AdvancedEntry(),
      ],
    );
  }

  static Future<void> _clearAllCaches(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    // Purge réelle : cache mémoire des images Flutter + cache disque
    // flutter_cache_manager (pochettes/stickers) + images vivantes.
    PaintingBinding.instance.imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
    // Vide aussi le cache disque en arrière-plan → le snack reflète la réalité.
    await DefaultCacheManager().emptyCache();
    // Guide TV (tampon disque + cache mémoire) et métadonnées TMDB/OMDb/TVmaze :
    // ils seront retéléchargés au prochain besoin.
    await EpgBufferStore.instance.clearAll();
    await ConditionalPlaylistCache.instance.clear();
    await CatalogHttpValidators.instance.clear();
    await ConditionalXmltvCache.instance.clear();
    await (await VideoCacheManager.instance).clear();
    ref.read(epgDataCacheProvider).invalidate();
    await HiveSync.writeAsync('metadata_cache', (box) => box.clear());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackCacheCleared)),
      );
    }
  }

  static Future<void> _factoryReset(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);

    final cancelFocus = FocusNode();
    final confirmFocus = FocusNode();

    void requestFocus(FocusNode focus) {
      if (context.mounted) {
        FocusScope.of(context).requestFocus(focus);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetAppDialogTitle),
        content: Text(l.resetAppDialogBody),
        actions: [
          Focus(
            focusNode: cancelFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.pop(ctx);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(confirmFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
          ),
          Focus(
            focusNode: confirmFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.pop(ctx);
                unawaited(_performFactoryReset(context, ref));
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(cancelFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _performFactoryReset(context, ref);
              },
              child: Text(l.resetAppDialogConfirm),
            ),
          ),
        ],
      ),
    );

    cancelFocus.dispose();
    confirmFocus.dispose();
  }

  static Future<void> _performFactoryReset(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);

    // 1) Purge caches (mémoire + disque)
    PaintingBinding.instance.imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
    await DefaultCacheManager().emptyCache();

// 2) Clear all Hive boxes
    final boxNames = [
      'history',
      'recently_watched',
      'search_history',
      'metadata_cache',
      'downloads',
      'epg_cache',
      'settings_backup',
      'history',
    ];
    for (final name in boxNames) {
      await safeAsync(
        () async {
          // Si la box est déjà ouverte (typage posé à l'initialisation par un
          // service, ex. `downloads` en Box<DownloadTask>), la réouvrir sans
          // type levait « already open and of type Box<...> ». On réutilise donc
          // l'instance existante, puis on la ferme pour purger le cache Hive.
          final box = Hive.isBoxOpen(name)
              ? Hive.box<dynamic>(name)
              : await Hive.openBox(name);
          await box.clear();
          await box.close();
        },
        context: '_performFactoryReset Hive box $name',
      );
    }

    // 3) Clear SharedPreferences keys
    await safeAsync(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      },
      context: '_performFactoryReset SharedPreferences',
    );

    // 4) Clear flutter_cache_manager disk cache
    await DefaultCacheManager().emptyCache();
    await ConditionalPlaylistCache.instance.clear();
    await CatalogHttpValidators.instance.clear();
    await ConditionalXmltvCache.instance.clear();

    // 5) Clear Flutter image cache
    PaintingBinding.instance.imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();

    // 6) Navigate to onboarding (reset complete)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.resetCompleted)),
      );
      context.go('/onboarding');
    }
  }
}

/// Porte d'entrée des réglages sensibles.
///
/// Discrète par choix : une longue pression sur une zone vide, en bas de
/// l'onglet Avancé. Un utilisateur qui ne sait pas qu'elle existe ne la
/// rencontrera jamais ; un appui simple ne l'ouvre pas, ce qui évite le
/// déclencheur accidentel au doigt.
class _AdvancedEntry extends StatelessWidget {
  const _AdvancedEntry();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l.advancedHiddenHint,
      child: TvFocus(
        onLongPress: () => _open(context),
        child: InkWell(
          canRequestFocus: false,
          onLongPress: () => _open(context),
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                '· · ·',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (await requestAdvancedAccess(context) && context.mounted) {
      await context.push('/settings/advanced');
    }
  }
}
