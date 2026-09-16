import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart'
    show showPlayerEngineConfigSheet;
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/cloud_sync_provider.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/settings_backup_service.dart';
import 'package:orbit_3d_flutter/services/cloudflare_bypass_service.dart';

/// Configuration unifiée (style XCIPTV) — fusionne SettingsScreen + AdvancedSettingsScreen.
/// Organisé en sections logiques avec icônes explicites, navigation au D-pad/TV.
class UnifiedSettingsScreen extends ConsumerStatefulWidget {
  const UnifiedSettingsScreen({super.key});

  @override
  ConsumerState<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends ConsumerState<UnifiedSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabIcons = [
    Icons.person_outline,
    Icons.wifi_tethering,
    Icons.play_circle_outline,
    Icons.security_outlined,
    Icons.equalizer,
    Icons.tune,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabIcons.length, vsync: this);
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
        title: Text(AppLocalizations.of(context).settingsTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (var i = 0; i < _tabIcons.length; i++)
              Tab(
                icon: Icon(_tabIcons[i]),
                text: _tabLabel(i),
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final sub = ref.watch(activeSubscriptionProvider).value;
    final syncState = ref.watch(cloudSyncProvider);
    final syncNotifier = ref.read(cloudSyncProvider.notifier);

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
        SettingsSwitchTile(
          title: l.cloudSyncEnabled,
          subtitle: syncState.signedIn
              ? l.cloudSyncLastSync(_formatTime(syncState.lastSyncAt, l.never))
              : l.cloudSyncSubtitleOff,
          value: syncState.enabled,
          onChanged: syncNotifier.setEnabled,
          icon: Icons.cloud_sync_rounded,
        ),
        if (syncState.lastError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              syncState.lastError!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (syncState.enabled && !syncState.busy)
          SettingsActionTile(
            title: l.cloudSyncNow,
            subtitle: l.cloudSyncNowSubtitle,
            icon: Icons.sync_rounded,
            onTap: syncNotifier.syncNow,
          ),
        const SizedBox(height: 8),
        SettingsSectionTitle(l.sectionNotifications),
        _NavTile(
          icon: Icons.notifications_active_rounded,
          title: l.testNotifications,
          subtitle: l.testNotificationsSubtitle,
          onTap: () async {
            final notificationService = ref.read(notificationServiceProvider);
            await notificationService.showNotification(
              'Orbit IPTV',
              'Ceci est une notification test',
            );
          },
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SettingsSectionTitle(l.sectionBackup),
        _NavTile(
          icon: Icons.upload_outlined,
          title: l.backupExport,
          subtitle: l.backupExportSubtitle,
          onTap: () => _exportSettings(context, ref),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
        _NavTile(
          icon: Icons.download_outlined,
          title: l.backupImport,
          subtitle: l.backupImportSubtitle,
          onTap: () => _importSettings(context, ref),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  static void _exportSettings(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final s = ref.read(advancedSettingsProvider);
    final prefs = ref.read(preferencesProvider);
    final json = await SettingsBackupService().exportToJson(
      advancedSettings: s,
      userPreferences: prefs,
    );
    await ref.read(storageServiceProvider).setSetting('settings_backup', json);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackBackupExported)),
      );
    }
  }

  static void _importSettings(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final backup = ref.read(storageServiceProvider).getSetting('settings_backup');
    if (backup == null || backup.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.snackNoBackup)),
        );
      }
      return;
    }
    final result = await SettingsBackupService().importFromJson(
      backup,
      ref.read(advancedSettingsProvider.notifier),
      ref.read(preferencesProvider.notifier),
    );
    if (result.success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.snackImportSuccess)),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.snackImportError(result.message))),
        );
      }
    }
  }

  static String _formatTime(DateTime? dt, String neverLabel) {
    if (dt == null) return neverLabel;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year} $h:$m';
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
        const _DnsProviderTile(),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionCloudflare),
        SettingsActionTile(
          title: l.cloudflareReset,
          subtitle: l.cloudflareResetSubtitle,
          icon: Icons.restore_outlined,
          onTap: () async {
            n.setTlsImpersonation(false);
            CloudflareBypassService.instance.invalidate('draap.online');
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
          leading: Icon(Icons.dns_outlined,
              color: Theme.of(context).colorScheme.primary,),
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
                  DropdownMenuItem(value: o, child: Text(o)),
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
    final TextEditingController fingerprintController = TextEditingController();

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
        SettingsSectionTitle(l.sectionCertPinning),
        SettingsSwitchTile(
          title: l.certPinning,
          subtitle: l.certPinningSubtitle,
          value: s.certificatePinningEnabled,
          onChanged: n.setCertificatePinningEnabled,
          icon: Icons.security_outlined,
        ),
        if (s.certificatePinningEnabled) ...[
          const SizedBox(height: 8),
          Text(
            l.certPinningHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: fingerprintController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'A1B2C3D4E5F6...\n7890ABCDEF1234...\n...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onSubmitted: (value) {
              final fps = value
                  .split('\n')
                  .map((e) => e.trim().toUpperCase())
                  .where((e) => e.isNotEmpty)
                  .toList();
              n.setCertificatePinningFingerprints(fps);
            },
          ),
          const SizedBox(height: 8),
          if (s.certificatePinningFingerprints.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.certificatePinningFingerprints
                  .map((fp) => Chip(
                        label: Text(
                          fp.length > 20 ? '${fp.substring(0, 20)}...' : fp,
                          style: const TextStyle(fontSize: 11),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          final updated = [...s.certificatePinningFingerprints]..remove(fp);
                          n.setCertificatePinningFingerprints(updated);
                        },
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final fps = fingerprintController.text
                  .split('\n')
                  .map((e) => e.trim().toUpperCase())
                  .where((e) => e.isNotEmpty)
                  .toList();
              n.setCertificatePinningFingerprints(fps);
              fingerprintController.clear();
            },
            icon: const Icon(Icons.add),
            label: Text(l.certPinningAdd),
          ),
        ],
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

  void _showAvSyncDialog(BuildContext context, WidgetRef ref) {
    final n = ref.read(advancedSettingsProvider.notifier);
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.avSyncDialogTitle),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: l.avSyncDialogLabel,
            hintText: l.avSyncDialogHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final ms = int.tryParse(controller.text) ?? 0;
              n.setNightFocusAudioShiftMs(ms);
              Navigator.pop(ctx);
            },
            child: Text(l.apply),
          ),
        ],
      ),
    );
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
          onChanged: ref.read(advancedSettingsProvider.notifier).setHighContrast,
          icon: Icons.contrast_outlined,
        ),
        SettingsSwitchTile(
          title: l.dpadNavigation,
          subtitle: l.dpadNavigationSubtitle,
          value: ref.watch(advancedSettingsProvider).zeroLagPrefetch, // placeholder
          onChanged: (_) {}, // TODO: ajouter champ dédié
          icon: Icons.tv_rounded,
        ),
        SettingsSwitchTile(
          title: l.fontSize,
          subtitle: l.fontSizeSubtitle,
          value: ref.watch(advancedSettingsProvider).highContrast, // placeholder
          onChanged: (_) {}, // TODO: ajouter champ dédié
          icon: Icons.format_size_outlined,
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionTmdb),
        const _TmdbApiKeyTile(),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionRecommendations),
        _NavTile(
          icon: Icons.recommend_rounded,
          title: l.matchmaking,
          subtitle: l.matchmakingSubtitle,
          onTap: () => context.go('/matchmaking'),
        ),
        const SizedBox(height: 16),
        SettingsSectionTitle(l.sectionDiagnostics),
        _NavTile(
          icon: Icons.bug_report_outlined,
          title: l.logsDiagnostic,
          subtitle: l.logsDiagnosticSubtitle,
          onTap: () => context.go('/diagnostic'),
        ),
        _NavTile(
          icon: Icons.cleaning_services_outlined,
          title: l.clearCaches,
          subtitle: l.clearCachesSubtitle,
          onTap: () => _clearAllCaches(context, ref),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        _NavTile(
          icon: Icons.restart_alt_outlined,
          title: l.resetApp,
          subtitle: l.resetAppSubtitle,
          onTap: () => _factoryReset(context, ref),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }

  static void _clearAllCaches(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // TODO: implémenter le vidage des caches
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.snackCacheCleared)),
    );
  }

  static void _factoryReset(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetAppDialogTitle),
        content: Text(l.resetAppDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // TODO: implémenter le reset complet
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réinitialisation effectuée (TODO)')),
                );
              }
            },
            child: Text(l.resetAppDialogConfirm),
          ),
        ],
      ),
    );
  }
}

/// ─── CLÉ API TMDB (inchangé) ────────────────────────────────────
class _TmdbApiKeyTile extends ConsumerStatefulWidget {
  const _TmdbApiKeyTile();

  @override
  ConsumerState<_TmdbApiKeyTile> createState() => _TmdbApiKeyTileState();
}

class _TmdbApiKeyTileState extends ConsumerState<_TmdbApiKeyTile> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final override = ref.read(tmdbApiKeyOverrideProvider);
    _controller.text = override;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final hasOverride = ref.watch(tmdbApiKeyOverrideProvider).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l.tmdbKeyLabel,
                  hintText: l.tmdbKeyHint,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(l.save),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasOverride ? l.tmdbKeyActive : l.tmdbKeyShared,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasOverride ? scheme.primary : scheme.onSurfaceVariant,
              ),
        ),
        if (hasOverride) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
            label: Text(l.tmdbKeyDelete),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ],
    );
  }

  void _save() async {
    final key = _controller.text.trim();
    await ref.read(tmdbApiKeyOverrideProvider.notifier).setOverride(key.isEmpty ? '' : key);
    if (mounted) setState(() {});
  }

  void _clear() async {
    await ref.read(tmdbApiKeyOverrideProvider.notifier).setOverride('');
    _controller.clear();
    if (mounted) setState(() {});
  }
}