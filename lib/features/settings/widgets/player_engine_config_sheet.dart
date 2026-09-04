import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
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
    final scheme = Theme.of(context).colorScheme;
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
                    IconButton(
                      tooltip: 'Annuler',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
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
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Sauvegarder'),
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
  });

  final PlaybackContentType type;
  final PlayerPerTypeConfig config;
  final ValueChanged<PlayerEngine> onPrimary;
  final ValueChanged<PlayerEngine> onFallback;

  IconData get _icon => switch (type) {
        PlaybackContentType.live => Icons.live_tv,
        PlaybackContentType.vod => Icons.movie_outlined,
        PlaybackContentType.series => Icons.tv_outlined,
        PlaybackContentType.replay => Icons.replay,
      };

  @override
  Widget build(BuildContext context) {
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
              label: 'Moteur Principal',
              icon: Icons.play_circle_outline,
              value: config.primary,
              onChanged: onPrimary,
            ),
            _EngineRow(
              label: 'Moteur de Secours',
              icon: Icons.sync_alt,
              value: config.fallback,
              onChanged: onFallback,
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
  });

  final String label;
  final IconData icon;
  final PlayerEngine value;
  final ValueChanged<PlayerEngine> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<PlayerEngine>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              items: [
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
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
