import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:orbit_3d_flutter/features/settings/widgets/readme_contact_dialog.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/update_dialog.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';
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
    final tvMode = ref.watch(tvModeProvider);
    final fitTv = (ref.watch(realTvProvider) || tvMode) &&
        MediaQuery.orientationOf(context) == Orientation.landscape;
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
                  alignmentPolicy:
                      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                );
                Scrollable.ensureVisible(
                  focusContext,
                  alignmentPolicy:
                      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
                );
              }
            },
          ),
          child: LayoutBuilder(
            builder: (context, viewport) {
              final sizing = fitTv
                  ? _SettingsSizing.forViewport(
                      context, viewport, groups, standalone)
                  : null;
              return _SettingsSizingScope(
                sizing: sizing,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(fitTv ? 8 : 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gap = fitTv ? _SettingsSizing.gap : 6.0;
                      final minColumns = constraints.maxWidth >= 312 ? 4 : 1;
                      final columns = ((constraints.maxWidth + gap) / 108)
                          .floor()
                          .clamp(minColumns, 6);
                      final cellWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: fitTv
                              ? (viewport.maxHeight - 16)
                                  .clamp(0.0, double.infinity)
                              : 0,
                        ),
                        child: Column(
                          mainAxisAlignment: fitTv
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (fitTv)
                              ...groups
                            else ...[
                              Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final group in groups)
                                    SizedBox(
                                      width: cellWidth *
                                              group.children.length
                                                  .clamp(1, columns) +
                                          gap *
                                              (group.children.length
                                                      .clamp(1, columns) -
                                                  1),
                                      child: group,
                                    ),
                                ],
                              ),
                              SizedBox(height: gap),
                            ],
                            _SettingsGrid(children: standalone),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsSizing {
  const _SettingsSizing(this.diameter, this.fontSize);

  final double diameter;
  final double fontSize;
  static const gap = 4.0;

  static _SettingsSizing forViewport(
    BuildContext context,
    BoxConstraints viewport,
    List<_SettingsGroup> groups,
    List<Widget> standalone,
  ) {
    double textHeight(String text, TextStyle style, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width.clamp(1.0, double.infinity));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final width = (viewport.maxWidth - 16).clamp(1.0, double.infinity);
    double rowLabels(
        List<Widget> tiles, double rowWidth, TextStyle labelStyle) {
      final cellWidth = (rowWidth - gap * (tiles.length - 1)) / tiles.length;
      var height = 0.0;
      for (final tile in tiles.whereType<_NavTile>()) {
        final tileHeight = textHeight(tile.title, labelStyle, cellWidth - 6);
        if (tileHeight > height) height = tileHeight;
      }
      return height;
    }

    double reservedFor(double fontSize) {
      final labelStyle = Theme.of(context).textTheme.bodyMedium!.merge(
            TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          );
      final headingStyle = labelStyle.copyWith(letterSpacing: 0.8);
      var reserved = 28.0 + gap * 2 + 3 * 6.0;
      for (final group in groups) {
        reserved += textHeight(
              group.title.toUpperCase(),
              headingStyle,
              width - 16,
            ) +
            11;
        reserved += rowLabels(group.children, width - 8, labelStyle);
      }
      return reserved + rowLabels(standalone, width, labelStyle);
    }

    var fontSize = (viewport.maxHeight * 0.027).clamp(8.0, 30.0);
    var reserved = reservedFor(fontSize);
    while (fontSize > 8 && reserved + 72 > viewport.maxHeight) {
      fontSize -= 0.5;
      reserved = reservedFor(fontSize);
    }
    final diameter =
        ((viewport.maxHeight - reserved) / 3).clamp(16.0, double.infinity);
    return _SettingsSizing(diameter, fontSize);
  }
}

class _SettingsSizingScope extends InheritedWidget {
  const _SettingsSizingScope({required this.sizing, required super.child});

  final _SettingsSizing? sizing;

  static _SettingsSizing? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SettingsSizingScope>()
      ?.sizing;

  @override
  bool updateShouldNotify(_SettingsSizingScope oldWidget) =>
      sizing?.diameter != oldWidget.sizing?.diameter ||
      sizing?.fontSize != oldWidget.sizing?.fontSize;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sizing = _SettingsSizingScope.of(context);
    final compact = sizing != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionTitle(
          title,
          fontSize: sizing?.fontSize ?? 15.6,
          padding: compact
              ? const EdgeInsets.fromLTRB(4, 4, 4, 3)
              : const EdgeInsets.fromLTRB(4, 16, 4, 8),
        ),
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
      final gap =
          _SettingsSizingScope.of(context) != null ? _SettingsSizing.gap : 6.0;
      final columns = _SettingsSizingScope.of(context) != null
          ? children.length.clamp(1, 6)
          : ((constraints.maxWidth + gap) / 78)
              .floor()
              .clamp(1, children.length.clamp(1, 6));
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Column(
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) SizedBox(height: gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start;
                    i < children.length && i < start + columns;
                    i++) ...[
                  if (i > start) SizedBox(width: gap),
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
class _NavTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isTv = ref.watch(realTvProvider);
    final sizing = _SettingsSizingScope.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final targetSize = sizing?.diameter ??
          (MediaQuery.orientationOf(context) == Orientation.landscape
              ? (MediaQuery.sizeOf(context).height * 0.22).clamp(0.0, 160.0)
              : isTv
                  ? 98.8
                  : 78.0);
      final diameter = (constraints.maxWidth - 6).clamp(0.0, targetSize);
      return TvFocus(
        key: ValueKey('settings-tile-$title'),
        autofocus: autofocus,
        onActivate: onTap,
        enableTvEffects: false,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return ExcludeFocus(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: focused
                      ? Border.all(color: scheme.primary, width: 2)
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 3, vertical: sizing == null ? 4 : 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          key: ValueKey('settings-icon-$title'),
                          width: diameter,
                          height: diameter,
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
                                      color: scheme.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: iconAsset != null
                                ? Image.asset(
                                    iconAsset!,
                                    width: diameter * 0.65,
                                    height: diameter * 0.65,
                                    excludeFromSemantics: true,
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(icon,
                                          size: diameter * 0.46,
                                          color: scheme.primary),
                                      Positioned(
                                        right: diameter * 0.23,
                                        top: diameter * 0.23,
                                        child: Container(
                                          width: diameter * 0.07,
                                          height: diameter * 0.07,
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: sizing == null ? 4 : 2),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: sizing?.fontSize ?? 15.6,
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
                              fontSize: 11.7,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              ),
            );
          },
        ),
      );
    });
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
          iconAsset: 'assets/icons/settings-preferences.png',
          title: l.accountPreferences,
          onTap: () => context.go('/profile/preferences'),
        ),
        _NavTile(
          icon: Icons.memory_rounded,
          title: l.accountDeviceProfile,
          onTap: () => context.go('/onboarding?from=settings'),
        ),
      ]),
    ];
  }

  static Widget cloudBackupTile(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return _NavTile(
      icon: Icons.cloud_outlined,
      iconAsset: 'assets/icons/settings-backup.png',
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
        for (final option in _options)
          _SettingsToggle(
            title: option == _options.last ? l.settingsSystemAutomatic : option,
            value: option ==
                (_options.contains(s.dnsProvider)
                    ? s.dnsProvider
                    : _options.last),
            onChanged: (_) {
              if (s.dnsProvider != option) n.setDnsProvider(option);
            },
            checkbox: true,
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
      iconAsset: 'assets/icons/settings-accessibility.png',
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
  final _tabs = List.generate(4, (index) => FocusNode());
  late final Set<int> _visitedTabs;

  @override
  void initState() {
    super.initState();
    _visitedTabs = {0};
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
    );
    _controller.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tabs[0].requestFocus();
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
      l.settingsCategoryFilters,
      l.audioAndNightFocus,
      l.sectionMemory,
    ];
    const panels = [
      SingleChildScrollView(child: _AccessibilityOptions()),
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
      title: Text(
        title,
        style: compact ? Theme.of(context).textTheme.titleMedium : null,
      ),
      content: SizedBox(
        width: compact ? 320 : 520,
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

Future<void> _showAvSyncDialog(BuildContext context, WidgetRef ref) async {
  final n = ref.read(advancedSettingsProvider.notifier);
  final l = AppLocalizations.of(context);
  var value = ref.read(advancedSettingsProvider).nightFocusAudioShiftMs;
  var limit = value.abs() > 2000 ? ((value.abs() + 49) ~/ 50) * 50 : 2000;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void updateValue(int next) {
          setState(() {
            value = next;
            if (value.abs() >= limit) limit = value.abs() + 500;
          });
        }

        return AlertDialog(
          title: Text(l.avSyncDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.avSyncDialogHint),
                const SizedBox(height: 8),
                Text(l.audioSyncLimitations,
                    style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(
                    '${l.avSyncDialogLabel} : ${value >= 0 ? "+" : ""}$value ms'),
                TvFocus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                      return KeyEventResult.ignored;
                    }
                    final key = event.logicalKey;
                    if (key == LogicalKeyboardKey.arrowLeft ||
                        key == LogicalKeyboardKey.arrowRight) {
                      final right = key == LogicalKeyboardKey.arrowRight;
                      final increase = right ==
                          (Directionality.of(ctx) == TextDirection.ltr);
                      updateValue(value + (increase ? 50 : -50));
                      return KeyEventResult.handled;
                    }
                    if (key == LogicalKeyboardKey.arrowDown ||
                        key == LogicalKeyboardKey.select ||
                        key == LogicalKeyboardKey.enter) {
                      node.nextFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: ExcludeFocus(
                    child: SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        tickMarkShape: SliderTickMarkShape.noTickMark,
                      ),
                      child: Slider(
                        value: value.toDouble(),
                        min: -limit.toDouble(),
                        max: limit.toDouble(),
                        divisions: limit ~/ 25,
                        label: '$value ms',
                        onChanged: (v) => updateValue(v.round()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                n.setNightFocusAudioShiftMs(value);
                Navigator.pop(ctx);
              },
              child: Text(l.apply),
            ),
          ],
        );
      },
    ),
  );
}

/// ─── AVANCÉ ──────────────────────────────────────────────────────
class _AdvancedSection {
  static List<_SettingsGroup> groups(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return [
      _SettingsGroup(title: l.sectionDiagnostics, children: [
        _PlayerAudioSection.engineTile(context),
        _AccountSection.cloudBackupTile(context, ref),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          _NavTile(
            icon: Icons.system_update_alt,
            iconAsset: 'assets/icons/settings-update.png',
            title: l.updateTitle,
            onTap: () => showUpdateDialog(context),
          ),
      ]),
    ];
  }

  static List<Widget> standalone(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return [
      _NavTile(
        icon: Icons.contact_support_outlined,
        iconAsset: 'assets/icons/settings-contact.png',
        title: l.legalNotice,
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => ReadmeContactDialog(
            onLegal: () {
              Navigator.pop(dialogContext);
              context.go('/legal?flow=settings');
            },
          ),
        ),
      ),
      _NavTile(
        icon: Icons.restart_alt_outlined,
        iconAsset: 'assets/icons/settings-reset.png',
        title: l.resetApp,
        onTap: () => _factoryReset(context, ref),
      ),
      const _AdvancedEntry(),
    ];
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
        const Divider(),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l.tabNetwork,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        const _DnsProviderTile(),
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
    final size =
        _SettingsSizingScope.of(context)?.diameter.clamp(16.0, 60.0) ?? 60.0;
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
                  width: size,
                  height: size,
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
