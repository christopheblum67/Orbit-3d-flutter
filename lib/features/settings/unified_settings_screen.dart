import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/services/epg_buffer_store.dart';
import 'package:orbit_3d_flutter/services/conditional_playlist_cache.dart';
import 'package:orbit_3d_flutter/services/catalog_http_validators.dart';
import 'package:orbit_3d_flutter/services/conditional_xmltv_cache.dart';
import 'package:orbit_3d_flutter/services/video_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/features/settings/category_filter_screen.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart'
    show showPlayerEngineConfigSheet;
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/update_dialog.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/features/settings/cloud_account_screen.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_activity_sync_provider.dart';
import 'package:orbit_3d_flutter/services/settings_backup_service.dart';

/// Configuration unifiée (style XCIPTV) — fusionne SettingsScreen + AdvancedSettingsScreen.
/// Organisé en sections logiques avec icônes explicites, navigation au D-pad/TV.
class UnifiedSettingsScreen extends ConsumerStatefulWidget {
  const UnifiedSettingsScreen({super.key});

  @override
  ConsumerState<UnifiedSettingsScreen> createState() =>
      _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends ConsumerState<UnifiedSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final groups = [
      ..._AccountSection.groups(context),
      ..._AdvancedSection.groups(context, ref),
    ];
    final standalone = [
      _PlayerAudioSection.combinedTile(context),
      ..._AdvancedSection.standalone(context, ref),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: AppLocalizations.of(context).backTooltip,
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: TvSafeArea(
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(
            requestFocusCallback: (
              node, {
              alignment,
              alignmentPolicy,
              duration,
              curve,
            }) {
              node.requestFocus();
              final focusContext = node.context;
              if (focusContext != null) {
                Scrollable.ensureVisible(
                  focusContext,
                  alignment: 0,
                  duration: const Duration(milliseconds: 120),
                );
              }
            },
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 6.0;
                final columns =
                    ((constraints.maxWidth + gap) / 84).floor().clamp(1, 8);
                final cellWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final group in groups)
                          SizedBox(
                            width: cellWidth *
                                    group.children.length.clamp(1, columns) +
                                gap *
                                    (group.children.length.clamp(1, columns) -
                                        1),
                            child: group,
                          ),
                      ],
                    ),
                    const SizedBox(height: gap),
                    _SettingsGrid(children: standalone),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionTitle(title),
        _SettingsGrid(children: children),
      ],
    );
    if (children.length < 2) return content;
    return DecoratedBox(
      key: ValueKey('settings-group-$title'),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: content,
      ),
    );
  }
}

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 6.0;
      final columns = ((constraints.maxWidth + gap) / 78).floor().clamp(1, 8);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Column(
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) const SizedBox(height: gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start;
                    i < children.length && i < start + columns;
                    i++) ...[
                  if (i > start) const SizedBox(width: gap),
                  SizedBox(width: width, child: children[i]),
                ],
              ],
            ),
          ],
        ],
      );
    });
  }
}

/// ─── Tuile de navigation réutilisable ────────────────────────────
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.onTap,
    this.iconAsset,
    this.autofocus = false,
  });

  final IconData icon;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Focus initial (premier élément de l'écran, en mode TV).
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TvFocus(
      autofocus: autofocus,
      onActivate: onTap,
      enableTvEffects: false,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return ExcludeFocus(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surfaceContainer,
                          border: Border.all(
                            color: scheme.primary
                                .withValues(alpha: focused ? 1 : 0.5),
                            width: focused ? 2.5 : 1,
                          ),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color:
                                        scheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: iconAsset != null
                              ? Image.asset(
                                  iconAsset!,
                                  width: 36,
                                  height: 36,
                                  excludeFromSemantics: true,
                                )
                              : Icon(icon, size: 26, color: scheme.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: focused ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ─── COMPTE ──────────────────────────────────────────────────────
class _AccountSection {
  static List<_SettingsGroup> groups(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      _SettingsGroup(title: l.sectionAccountProfile, children: [
        _NavTile(
          // Premier élément focusable de l'écran : focus initial en mode TV.
          autofocus: true,
          icon: Icons.manage_accounts_rounded,
          iconAsset: 'assets/icons/settings-profile.png',
          title: l.accountProfiles,
          onTap: () => context.go('/profiles'),
        ),
        _NavTile(
          icon: Icons.subscriptions_rounded,
          iconAsset: 'assets/icons/settings-subscription.png',
          title: l.accountSubscriptions,
          onTap: () => context.go('/subscriptions'),
        ),
        _NavTile(
          icon: Icons.settings_outlined,
          title: l.accountPreferences,
          onTap: () => context.go('/profile/preferences'),
        ),
        _NavTile(
          icon: Icons.memory_rounded,
          title: l.accountDeviceProfile,
          onTap: () => context.go('/onboarding'),
        ),
      ]),
    ];
  }

  static Widget cloudBackupTile(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _NavTile(
      icon: Icons.cloud_outlined,
      title: l.sectionBackup,
      onTap: () => _showSettingsDialog(
        context,
        title: '${l.settingsCloudAccount} · ${l.sectionBackup}',
        compact: true,
        child: _CloudBackupOptions(screenContext: context, screenRef: ref),
      ),
    );
  }

  static List<Widget> cloudStatus(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final syncState = ref.watch(encryptedActivitySyncProvider);
    return [
      if (syncState.error != null ||
          syncState.realtimeError != null ||
          syncState.conflictScope != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            syncState.conflictScope != null
                ? l.cloudConflictHelp
                : l.cloudOperationFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (syncState.unlocked)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
              l.cloudSyncLastSync(_formatTime(syncState.lastSyncAt, l.never))),
        ),
      if (syncState.unlocked && syncState.busy)
        ListTile(title: Text(l.cloudStartingSync)),
    ];
  }

  static Future<void> _exportSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final s = ref.read(advancedSettingsProvider);
    final prefs = ref.read(preferencesProvider);
    final json = await SettingsBackupService().exportToJson(
      advancedSettings: s,
      userPreferences: prefs,
    );
    // L'export est du vrai I/O : l'utilisateur peut quitter les réglages entre
    // l'appel et l'écriture. `context.mounted` ne protégeait que le SnackBar,
    // la ligne suivante lisait `ref` sans garde.
    if (!context.mounted) return;
    await ref.read(storageServiceProvider).setSetting('settings_backup', json);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackBackupExported)),
      );
    }
  }

  static Future<void> _importSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final backup =
        ref.read(storageServiceProvider).getSetting('settings_backup');
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
    // L'import réécrit les réglages : l'écran peut avoir été quitté entre-temps.
    if (!context.mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.snackImportSuccess)));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(l.snackImportError(result.message))));
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

class _CloudBackupOptions extends ConsumerWidget {
  const _CloudBackupOptions({
    required this.screenContext,
    required this.screenRef,
  });

  final BuildContext screenContext;
  final WidgetRef screenRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final syncState = ref.watch(encryptedActivitySyncProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGrid(children: [
          _NavTile(
            autofocus: true,
            icon: Icons.account_circle_outlined,
            title: l.settingsCloudAccount,
            subtitle: l.settingsCloudSignIn,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const CloudAccountScreen()),
            ),
          ),
          _NavTile(
            icon: Icons.upload_outlined,
            title: l.backupExport,
            subtitle: l.backupExportSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              unawaited(
                  _AccountSection._exportSettings(screenContext, screenRef));
            },
          ),
          _NavTile(
            icon: Icons.download_outlined,
            title: l.backupImport,
            subtitle: l.backupImportSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              unawaited(
                  _AccountSection._importSettings(screenContext, screenRef));
            },
          ),
          if (syncState.unlocked &&
              !syncState.busy &&
              syncState.conflictScope == null)
            _NavTile(
              icon: Icons.sync_rounded,
              title: l.cloudSyncNow,
              subtitle: l.cloudSyncNowSubtitle,
              onTap: () =>
                  ref.read(encryptedActivitySyncProvider.notifier).syncAll(),
            ),
        ]),
        ..._AccountSection.cloudStatus(context, ref),
      ],
    );
  }
}

class _DnsProviderTile extends ConsumerWidget {
  const _DnsProviderTile();

  static const _options = <String>[
    '1.1.1.1 (Cloudflare DoH)',
    '8.8.8.8 (Google DoH)',
    'Automatique (Système)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.dnsProvider),
        Text(l.dnsProviderSubtitle,
            style: Theme.of(context).textTheme.bodySmall),
        DropdownButton<String>(
          isExpanded: true,
          value:
              _options.contains(s.dnsProvider) ? s.dnsProvider : _options.last,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          items: [
            for (final o in _options)
              DropdownMenuItem(
                value: o,
                child: Text(
                  o == _options.last ? l.settingsSystemAutomatic : o,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) n.setDnsProvider(v);
          },
        ),
      ],
    );
  }
}

/// ─── LECTURE & AUDIO ─────────────────────────────────────────────
class _PlayerAudioSection {
  static Widget engineTile(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _NavTile(
      icon: Icons.play_circle_outline,
      iconAsset: 'assets/icons/settings-player.png',
      title: l.enginesTile,
      onTap: () => showPlayerEngineConfigSheet(context),
    );
  }

  static Widget combinedTile(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _NavTile(
      icon: Icons.tune_rounded,
      title: l.sectionAccessibility,
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => const _CombinedSettingsDialog(),
      ),
    );
  }
}

class _CombinedSettingsDialog extends StatefulWidget {
  const _CombinedSettingsDialog();

  @override
  State<_CombinedSettingsDialog> createState() =>
      _CombinedSettingsDialogState();
}

class _CombinedSettingsDialogState extends State<_CombinedSettingsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final _tabs = List.generate(5, (index) => FocusNode());
  final _visitedTabs = <int>{0};

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _tabs.length, vsync: this);
    _controller.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tabs.first.requestFocus();
    });
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() => _visitedTabs.add(_controller.index));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    for (final node in _tabs) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [
      l.sectionAccessibility,
      l.tabNetwork,
      l.settingsCategoryFilters,
      l.audioAndNightFocus,
      l.sectionMemory,
    ];
    const panels = [
      SingleChildScrollView(child: _AccessibilityOptions()),
      SingleChildScrollView(child: _DnsProviderTile()),
      CategoryFilterScreen(embedded: true),
      SingleChildScrollView(child: _AudioOptions()),
      SingleChildScrollView(child: MemorySettingsPanel()),
    ];
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: 640,
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(children: [
                Expanded(
                  child: Text(l.settingsTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: l.close,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            TabBar(
              controller: _controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: [
                for (var index = 0; index < labels.length; index++)
                  Focus(
                    focusNode: _tabs[index],
                    onFocusChange: (focused) {
                      if (focused) {
                        if (_controller.index != index) {
                          _controller.animateTo(index);
                        }
                        final target = _tabs[index].context;
                        if (target != null) {
                          Scrollable.ensureVisible(target);
                        }
                      }
                    },
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                        return KeyEventResult.ignored;
                      }
                      final direction =
                          event.logicalKey == LogicalKeyboardKey.arrowRight
                              ? 1
                              : event.logicalKey == LogicalKeyboardKey.arrowLeft
                                  ? -1
                                  : 0;
                      final rtl =
                          Directionality.of(context) == TextDirection.rtl;
                      final next = index + (rtl ? -direction : direction);
                      if (direction == 0 || next < 0 || next >= _tabs.length) {
                        return KeyEventResult.ignored;
                      }
                      _tabs[next].requestFocus();
                      return KeyEventResult.handled;
                    },
                    child: AnimatedBuilder(
                      animation: _tabs[index],
                      builder: (context, child) => DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: _tabs[index].hasFocus
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        child: child,
                      ),
                      child: Tab(text: labels[index]),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: IndexedStack(
                    index: _controller.index,
                    children: [
                      for (var index = 0; index < panels.length; index++)
                        ExcludeFocus(
                          excluding: index != _controller.index,
                          child: _visitedTabs.contains(index)
                              ? panels[index]
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showSettingsDialog(
  BuildContext context, {
  required String title,
  required Widget child,
  bool compact = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : null,
      contentPadding: compact ? const EdgeInsets.fromLTRB(16, 8, 16, 0) : null,
      title: Text(title),
      content: SizedBox(
        width: compact ? 440 : 520,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: SingleChildScrollView(child: child),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).close),
        ),
      ],
    ),
  );
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.title,
    required this.value,
    required this.onChanged,
    this.checkbox = false,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool checkbox;

  @override
  Widget build(BuildContext context) {
    return TvFocus(
      onActivate: () => onChanged(!value),
      onFocusChange: (focused) {
        if (focused) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 180),
            alignment: 0.5,
          );
        }
      },
      child: ExcludeFocus(
        child: checkbox
            ? CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(title, style: const TextStyle(fontSize: 12)),
                value: value,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              )
            : SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title),
                value: value,
                onChanged: onChanged,
              ),
      ),
    );
  }
}

class _AudioOptions extends ConsumerWidget {
  const _AudioOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsToggle(
          title: l.nightFocusEnable,
          value: s.nightFocusEnabled,
          onChanged: n.setNightFocus,
          checkbox: true,
        ),
        _SettingsToggle(
          title: l.dialogueBoost,
          value: s.nightFocusDialogueBoost,
          onChanged: n.setNightFocusDialogueBoost,
          checkbox: true,
        ),
        _SettingsToggle(
          title: l.bassKiller,
          value: s.nightFocusBassKiller,
          onChanged: n.setNightFocusBassKiller,
          checkbox: true,
        ),
        _SettingsToggle(
          title: l.audioShift,
          value: s.nightFocusAudioShiftMs != 0,
          onChanged: (value) => n.setNightFocusAudioShiftMs(value ? 50 : 0),
          checkbox: true,
        ),
        if (s.nightFocusAudioShiftMs != 0)
          TextButton.icon(
            onPressed: () => _showAvSyncDialog(context, ref),
            icon: const Icon(Icons.timer_outlined),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.manualAvCalibration),
                Text(l.manualAvCalibrationSubtitle(s.nightFocusAudioShiftMs)),
              ],
            ),
          ),
        _SettingsToggle(
          title: l.volumeNormalization,
          value: s.nightFocusVolumeNormalization,
          onChanged: n.setNightFocusVolumeNormalization,
          checkbox: true,
        ),
        Builder(
          builder: (buttonContext) => TvFocus(
            onActivate: () => showAudioControlsSheet(buttonContext),
            onFocusChange: (focused) {
              if (focused) {
                Scrollable.ensureVisible(
                  buttonContext,
                  duration: const Duration(milliseconds: 180),
                  alignment: 1,
                );
              }
            },
            child: ExcludeFocus(
              child: TextButton.icon(
                onPressed: () => showAudioControlsSheet(buttonContext),
                icon: const Icon(Icons.equalizer),
                label: Text(l.audioAndNightFocus),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Boîte de dialogue de calibration manuelle du décalage audio (ms).
///
/// Extraite en fonction de premier niveau : elle était méthode privée de
/// l'ancienne `_AudioSection`, désormais fusionnée dans [_PlayerAudioSection].
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

/// ─── AVANCÉ ──────────────────────────────────────────────────────
class _AdvancedSection {
  static List<_SettingsGroup> groups(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return [
      _SettingsGroup(title: l.sectionDiagnostics, children: [
        _PlayerAudioSection.engineTile(context),
        _AccountSection.cloudBackupTile(context, ref),
        if (Platform.isAndroid)
          _NavTile(
            icon: Icons.system_update_alt,
            title: l.updateTitle,
            onTap: () => showUpdateDialog(context),
          ),
        _NavTile(
          icon: Icons.cleaning_services_outlined,
          iconAsset: 'assets/icons/settings-cache.png',
          title: l.clearCaches,
          onTap: () => _clearAllCaches(context, ref),
        ),
      ]),
    ];
  }

  static List<Widget> standalone(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return [
      _NavTile(
        icon: Icons.contact_support_outlined,
        title: l.settingsContact,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.comingSoon)),
        ),
      ),
      _NavTile(
        icon: Icons.balance_outlined,
        title: l.legalNotice,
        onTap: () => context.go('/legal?flow=settings'),
      ),
      _NavTile(
        icon: Icons.verified_user_outlined,
        title: l.settingsActivateApp,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.comingSoon)),
        ),
      ),
      _NavTile(
        icon: Icons.restart_alt_outlined,
        title: l.resetApp,
        onTap: () => _factoryReset(context, ref),
      ),
      const _AdvancedEntry(),
    ];
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
        scrollable: true,
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
    try {
      // Only local activity boxes are reset; connection and stream data remain.
      for (final name in ['history', 'recently_watched', 'search_history']) {
        if (!Hive.isBoxOpen(name)) await Hive.openBox<dynamic>(name);
        await HiveSync.writeAsync(name, (box) => box.clear());
      }
      PaintingBinding.instance.imageCache.clearLiveImages();
      PaintingBinding.instance.imageCache.clear();
      if (context.mounted) {
        ref.invalidate(recentlyWatchedProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.resetCompleted)),
        );
        context.go('/onboarding');
      }
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('réinitialisation de l’application'),
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.resetFailed)),
        );
      }
    }
  }
}

class _AccessibilityOptions extends ConsumerWidget {
  const _AccessibilityOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsToggle(
          title: l.highContrast,
          value: s.highContrast,
          onChanged: n.setHighContrast,
          checkbox: true,
        ),
        _SettingsToggle(
          title: l.dpadNavigation,
          value: s.dpadNavigation,
          onChanged: n.setDpadNavigation,
          checkbox: true,
        ),
        _SettingsToggle(
          title: l.fontSize,
          value: s.fontSizeScale > 1,
          onChanged: (value) => n.setFontSizeScale(value ? 1.3 : 1),
          checkbox: true,
        ),
      ],
    );
  }
}

/// Porte d'entrée des réglages sensibles.
///
/// Entrée discrète, protégée par le code des réglages avancés.
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
        enableTvEffects: false,
        onActivate: () => _open(context),
        onLongPress: () => _open(context),
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return InkWell(
              canRequestFocus: false,
              onLongPress: () => _open(context),
              onTap: () => _open(context),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  key: const ValueKey('hidden-advanced-entry'),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: focused
                        ? scheme.primary.withValues(alpha: 0.04)
                        : Colors.transparent,
                    border: focused
                        ? Border.all(
                            color: scheme.primary.withValues(alpha: 0.2),
                          )
                        : null,
                  ),
                ),
              ),
            );
          },
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
