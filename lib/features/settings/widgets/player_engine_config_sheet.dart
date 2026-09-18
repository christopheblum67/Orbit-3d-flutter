import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

/// Sous-fenêtre de configuration des moteurs de lecture par type de contenu
/// (Live, VOD, Séries, Replays), façon XCIPTV : une ligne par élément.
///
/// Pour chaque type on choisit un **Moteur Principal** (par défaut) et un
/// **Moteur de Secours (Fallback)**. Les choix ne sont appliqués qu'à
/// l'appui sur **Sauvegarder** ; **Annuler** referme sans rien persister.
Future<void> showPlayerEngineConfigSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const PlayerEngineConfigSheet(),
  );
}

class PlayerEngineConfigSheet extends ConsumerStatefulWidget {
  const PlayerEngineConfigSheet({super.key});

  @override
  ConsumerState<PlayerEngineConfigSheet> createState() =>
      _PlayerEngineConfigSheetState();
}

class _PlayerEngineConfigSheetState
    extends ConsumerState<PlayerEngineConfigSheet> {
  /// Copie locale non persistée : modifiée dans la sous-fenêtre, puis
  /// appliquée au provider uniquement au moment de « Sauvegarder ».
  late Map<PlaybackContentType, PlayerPerTypeConfig> _draft;

  // Focus nodes for TV/D-pad navigation
  final _closeFocus = FocusNode();
  final _cancelFocus = FocusNode();
  final _saveFocus = FocusNode();
  final Map<PlaybackContentType, FocusNode> _primaryFocusNodes = {};
  final Map<PlaybackContentType, FocusNode> _fallbackFocusNodes = {};

  @override
  void dispose() {
    _closeFocus.dispose();
    _cancelFocus.dispose();
    _saveFocus.dispose();
    for (final node in _primaryFocusNodes.values) {
      node.dispose();
    }
    for (final node in _fallbackFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final s = ref.read(advancedSettingsProvider);
    _draft = {
      for (final t in PlaybackContentType.values) t: s.configFor(t),
    };
    // Initialize focus nodes for each content type
    for (final type in PlaybackContentType.values) {
      _primaryFocusNodes[type] = FocusNode();
      _fallbackFocusNodes[type] = FocusNode();
    }
  }

  void _setPrimary(PlaybackContentType type, PlayerEngine engine) {
    setState(() {
      _draft[type] = _draft[type]!.copyWith(primary: engine);
    });
  }

  void _setFallback(PlaybackContentType type, PlayerEngine engine) {
    setState(() {
      _draft[type] = _draft[type]!.copyWith(fallback: engine);
    });
  }

  Future<void> _save() async {
    final n = ref.read(advancedSettingsProvider.notifier);
    for (final entry in _draft.entries) {
      await n.setPlayerPrimary(entry.key, entry.value.primary);
      await n.setPlayerFallback(entry.key, entry.value.fallback);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
    }
  }

  Widget _buildTvDropdownButton({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required PlayerEngine value,
    required ValueChanged<PlayerEngine> onChanged,
    required List<DropdownMenuItem<PlayerEngine>> items,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            // Let the dropdown handle opening, then move to next
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PlayerEngine>(
          value: value,
          isDense: true,
          focusNode: focusNode,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Request initial focus on close button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestFocus(_closeFocus);
      }
    });

    // Build dropdown items once
    final dropdownItems = [
      for (final e in PlayerEngine.values)
        DropdownMenuItem(
          value: e,
          child: Text(
            e.label,
            style: TextStyle(
              fontSize: 13,
              color: e.isExternal ? null : scheme.primary,
              fontWeight:
                  e.isExternal ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_input_component,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Moteurs de lecture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Focus(
                      focusNode: _closeFocus,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                          Navigator.of(context).pop();
                          return KeyEventResult.handled;
                        }
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                          // Move to first primary dropdown (Live)
                          if (_primaryFocusNodes[PlaybackContentType.live] != null) {
                            _requestFocus(_primaryFocusNodes[PlaybackContentType.live]!);
                          }
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: IconButton(
                        tooltip: 'Annuler',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                      child: Text(
                        'Choisissez le moteur utilisé pour chaque type de '
                        'contenu, ainsi que le moteur de secours en cas '
                        'd\'échec de lecture.',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (final type in PlaybackContentType.values)
                      _TypeSection(
                        type: type,
                        config: _draft[type]!,
                        onPrimary: (e) => _setPrimary(type, e),
                        onFallback: (e) => _setFallback(type, e),
                        primaryFocusNode: _primaryFocusNodes[type]!,
                        fallbackFocusNode: _fallbackFocusNodes[type]!,
                        dropdownItems: dropdownItems,
                        buildTvDropdown: _buildTvDropdownButton,
                        getNextPrimaryFocus: (currentType) {
                          final types = PlaybackContentType.values;
                          final idx = types.indexOf(currentType);
                          if (idx + 1 < types.length) {
                            return _primaryFocusNodes[types[idx + 1]]!;
                          }
                          return _cancelFocus; // After last primary, go to cancel
                        },
                        getPrevPrimaryFocus: (currentType) {
                          final types = PlaybackContentType.values;
                          final idx = types.indexOf(currentType);
                          if (idx > 0) {
                            return _fallbackFocusNodes[types[idx - 1]]!;
                          }
                          return _closeFocus; // Before first primary, go to close
                        },
                        getNextFallbackFocus: (currentType) {
                          final types = PlaybackContentType.values;
                          final idx = types.indexOf(currentType);
                          if (idx + 1 < types.length) {
                            return _primaryFocusNodes[types[idx + 1]]!;
                          }
                          return _cancelFocus; // After last fallback, go to cancel
                        },
                        getPrevFallbackFocus: (currentType) {
                          final types = PlaybackContentType.values;
                          final idx = types.indexOf(currentType);
                          if (idx > 0) {
                            return _primaryFocusNodes[types[idx]]!; // Same type's primary
                          }
                          return _closeFocus;
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        focusNode: _cancelFocus,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey == LogicalKeyboardKey.select ||
                                  event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                            Navigator.of(context).pop();
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.arrowUp)) {
                            // Go to last fallback (Replay)
                            _requestFocus(_fallbackFocusNodes[PlaybackContentType.replay]!);
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.arrowRight)) {
                            _requestFocus(_saveFocus);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: Text(l.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Focus(
                        focusNode: _saveFocus,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey == LogicalKeyboardKey.select ||
                                  event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                            _save();
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                            _requestFocus(_cancelFocus);
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.arrowUp)) {
                            _requestFocus(_fallbackFocusNodes[PlaybackContentType.replay]!);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(l.save),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.config,
    required this.onPrimary,
    required this.onFallback,
    required this.primaryFocusNode,
    required this.fallbackFocusNode,
    required this.dropdownItems,
    required this.buildTvDropdown,
    required this.getNextPrimaryFocus,
    required this.getPrevPrimaryFocus,
    required this.getNextFallbackFocus,
    required this.getPrevFallbackFocus,
  });

  final PlaybackContentType type;
  final PlayerPerTypeConfig config;
  final ValueChanged<PlayerEngine> onPrimary;
  final ValueChanged<PlayerEngine> onFallback;
  final FocusNode primaryFocusNode;
  final FocusNode fallbackFocusNode;
  final List<DropdownMenuItem<PlayerEngine>> dropdownItems;
  final Widget Function({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required PlayerEngine value,
    required ValueChanged<PlayerEngine> onChanged,
    required List<DropdownMenuItem<PlayerEngine>> items,
  }) buildTvDropdown;
  final FocusNode Function(PlaybackContentType) getNextPrimaryFocus;
  final FocusNode Function(PlaybackContentType) getPrevPrimaryFocus;
  final FocusNode Function(PlaybackContentType) getNextFallbackFocus;
  final FocusNode Function(PlaybackContentType) getPrevFallbackFocus;

  IconData get _icon => switch (type) {
        PlaybackContentType.live => Icons.live_tv,
        PlaybackContentType.vod => Icons.movie_outlined,
        PlaybackContentType.series => Icons.tv_outlined,
        PlaybackContentType.replay => Icons.replay,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _EngineRow(
              label: l.primaryEngine,
              icon: Icons.play_circle_outline,
              value: config.primary,
              onChanged: onPrimary,
              focusNode: primaryFocusNode,
              nextFocusNode: getNextPrimaryFocus(type),
              prevFocusNode: getPrevPrimaryFocus(type),
              dropdownItems: dropdownItems,
              buildTvDropdown: buildTvDropdown,
            ),
            _EngineRow(
              label: l.fallbackEngine,
              icon: Icons.sync_alt,
              value: config.fallback,
              onChanged: onFallback,
              focusNode: fallbackFocusNode,
              nextFocusNode: getNextFallbackFocus(type),
              prevFocusNode: getPrevFallbackFocus(type),
              dropdownItems: dropdownItems,
              buildTvDropdown: buildTvDropdown,
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineRow extends StatelessWidget {
  const _EngineRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.focusNode,
    required this.nextFocusNode,
    required this.prevFocusNode,
    required this.dropdownItems,
    required this.buildTvDropdown,
  });

  final String label;
  final IconData icon;
  final PlayerEngine value;
  final ValueChanged<PlayerEngine> onChanged;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final FocusNode prevFocusNode;
  final List<DropdownMenuItem<PlayerEngine>> dropdownItems;
  final Widget Function({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required PlayerEngine value,
    required ValueChanged<PlayerEngine> onChanged,
    required List<DropdownMenuItem<PlayerEngine>> items,
  }) buildTvDropdown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          buildTvDropdown(
            focusNode: focusNode,
            nextFocusNode: nextFocusNode,
            prevFocusNode: prevFocusNode,
            value: value,
            onChanged: onChanged,
            items: dropdownItems,
          ),
        ],
      ),
    );
  }
}
