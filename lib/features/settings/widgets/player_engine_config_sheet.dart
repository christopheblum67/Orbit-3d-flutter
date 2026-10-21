import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
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

  @override
  void initState() {
    super.initState();
    final s = ref.read(advancedSettingsProvider);
    _draft = {
      for (final t in PlaybackContentType.values) t: s.configFor(t),
    };
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

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
              fontWeight: e.isExternal ? FontWeight.normal : FontWeight.w600,
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
                    Expanded(
                      child: Text(
                        l.enginesTile,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TvFocus(
                      autofocus: true,
                      onActivate: () => Navigator.of(context).pop(),
                      child: IconButton(
                        tooltip: l.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                        child: Text(
                          l.enginesDescription,
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
                          dropdownItems: dropdownItems,
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TvFocus(
                        onActivate: () => Navigator.of(context).pop(),
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: Text(l.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TvFocus(
                        autofocus: true,
                        onActivate: _save,
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
    required this.dropdownItems,
  });

  final PlaybackContentType type;
  final PlayerPerTypeConfig config;
  final ValueChanged<PlayerEngine> onPrimary;
  final ValueChanged<PlayerEngine> onFallback;
  final List<DropdownMenuItem<PlayerEngine>> dropdownItems;

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
              dropdownItems: dropdownItems,
            ),
            _EngineRow(
              label: l.fallbackEngine,
              icon: Icons.sync_alt,
              value: config.fallback,
              onChanged: onFallback,
              dropdownItems: dropdownItems,
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineRow extends StatefulWidget {
  const _EngineRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.dropdownItems,
  });

  final String label;
  final IconData icon;
  final PlayerEngine value;
  final ValueChanged<PlayerEngine> onChanged;
  final List<DropdownMenuItem<PlayerEngine>> dropdownItems;

  @override
  State<_EngineRow> createState() => _EngineRowState();
}

class _EngineRowState extends State<_EngineRow> {
  late FocusNode _focusNode;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() => _isDropdownOpen = !_isDropdownOpen);
    if (!_isDropdownOpen) {
      // Forcer la fermeture via le focus system
      _focusNode.requestFocus();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      if (!_isDropdownOpen) {
        // Ouvrir le dropdown
        setState(() => _isDropdownOpen = true);
        // Le DropdownButton gère son overlay interne
      } else {
        // Fermer le dropdown (la sélection se fait via onChanged)
        setState(() => _isDropdownOpen = false);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.gameButtonB) {
      if (_isDropdownOpen) {
        setState(() => _isDropdownOpen = false);
        return KeyEventResult.handled;
      }
    }
    // Laisser les flèches haut/bas naviguer dans le dropdown ouvert
    if (_isDropdownOpen &&
        (event.logicalKey == LogicalKeyboardKey.arrowUp ||
         event.logicalKey == LogicalKeyboardKey.arrowDown)) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.label, style: const TextStyle(fontSize: 13)),
          ),
          TvFocus(
            focusNode: _focusNode,
            onActivate: _toggleDropdown,
            onKeyEvent: _onKey,
            onFocusChange: (hasFocus) {
              if (!hasFocus && _isDropdownOpen) {
                setState(() => _isDropdownOpen = false);
              }
            },
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PlayerEngine>(
                value: widget.value,
                isDense: true,
                isExpanded: false,
                borderRadius: BorderRadius.circular(12),
                items: widget.dropdownItems,
                onChanged: (v) {
                  if (v != null) {
                    widget.onChanged(v);
                    setState(() => _isDropdownOpen = false);
                  }
                },
                // Style pour indiquer visuellement le focus
                style: TextStyle(
                  fontSize: 13,
                  color: _isDropdownOpen
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: _isDropdownOpen ? FontWeight.w600 : FontWeight.normal,
                ),
                dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                icon: Icon(
                  _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
