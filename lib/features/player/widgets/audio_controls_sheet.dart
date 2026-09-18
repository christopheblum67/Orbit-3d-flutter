import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Sous-fenêtre « Audio & Night Focus » ouverte depuis le lecteur.
///
/// Le **moteur interne** (`video_player`/ExoPlayer) embarque désormais un
/// processeur audio natif « Night Focus » (Dialogue Boost, Bass Killer, gain
/// vocal, décalage A/V) actif quand le switch maître est ON. Tous les réglages
/// sont persistés (SharedPreferences) et poussés au natif à chaque changement
/// via [NightFocusAudioService] ; le player ré-applique la config à la lecture.
Future<void> showAudioControlsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const AudioControlsSheet(),
  );
}

class AudioControlsSheet extends ConsumerStatefulWidget {
  const AudioControlsSheet({super.key});

  @override
  ConsumerState<AudioControlsSheet> createState() => _AudioControlsSheetState();
}

class _AudioControlsSheetState extends ConsumerState<AudioControlsSheet> {
  bool get _nightFocusEnabled => ref.watch(
        advancedSettingsProvider.select((s) => s.nightFocusEnabled),
      );

  bool get _dialogueBoost => ref.watch(
        advancedSettingsProvider.select((s) => s.nightFocusDialogueBoost),
      );

  bool get _bassKiller => ref.watch(
        advancedSettingsProvider.select((s) => s.nightFocusBassKiller),
      );

  double get _vocalGainDb => ref.watch(
        advancedSettingsProvider.select((s) => s.nightFocusVocalGainDb),
      );

  int get _audioShiftMs => ref.watch(
        advancedSettingsProvider.select((s) => s.nightFocusAudioShiftMs),
      );

  bool get _volumeNormalization => ref.watch(
        advancedSettingsProvider.select(
          (s) => s.nightFocusVolumeNormalization,
        ),
      );

  AdvancedSettingsNotifier get _notifier =>
      ref.read(advancedSettingsProvider.notifier);

  // Focus nodes for TV/D-pad navigation
  final _closeFocus = FocusNode();
  final _nightFocusSwitchFocus = FocusNode();
  final _dialogueBoostFocus = FocusNode();
  final _bassKillerFocus = FocusNode();
  final _vocalGainSliderFocus = FocusNode();
  final _shiftMinusFocus = FocusNode();
  final _shiftPlusFocus = FocusNode();
  final _resetFocus = FocusNode();

  @override
  void dispose() {
    _closeFocus.dispose();
    _nightFocusSwitchFocus.dispose();
    _dialogueBoostFocus.dispose();
    _bassKillerFocus.dispose();
    _vocalGainSliderFocus.dispose();
    _shiftMinusFocus.dispose();
    _shiftPlusFocus.dispose();
    _resetFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
    }
  }

  Future<void> _push() async {
    await NightFocusAudioService.push(
      _nightFocusEnabled,
      dialogueBoostDb: _dialogueBoost ? 4.0 : 0,
      bassKillerCutoffHz: _bassKiller ? 120.0 : 0,
      vocalGainDb: _dialogueBoost ? _vocalGainDb : 0,
      audioDelayMs: _audioShiftMs,
      volumeNormalization: _volumeNormalization,
    );
  }

  Widget _buildTvSwitch({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            onChanged(!value);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTvCheckboxListTile({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required bool enabled,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget title,
    Widget? subtitle,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            if (enabled) onChanged(!value);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: CheckboxListTile(
        enabled: enabled,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildTvIconButton({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            onPressed();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            // For horizontal row, up/down can go to next vertical element
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildTvTextButton({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            onPressed();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }

  Widget _buildTvSlider({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            final newValue = (value + (max - min) / divisions).clamp(min, max);
            onChanged(newValue);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            final newValue = (value - (max - min) / divisions).clamp(min, max);
            onChanged(newValue);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Request initial focus on first interactive element
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestFocus(_closeFocus);
      }
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Row(
                  children: [
                    Icon(Icons.nightlight_round, color: scheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Audio & Night Focus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildTvIconButton(
                      focusNode: _closeFocus,
                      nextFocusNode: _nightFocusSwitchFocus,
                      prevFocusNode: _resetFocus,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icons.close,
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text(
                      'Optimisation sonore active : les réglages s\'appliquent '
                      'au moteur natif quand Night Focus est ON, et sont '
                      'sauvegardés pour la prochaine lecture.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                color: _nightFocusEnabled
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Optimisation Nocturne (Night Focus)',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _nightFocusEnabled
                                        ? null
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              _buildTvSwitch(
                                focusNode: _nightFocusSwitchFocus,
                                nextFocusNode: _dialogueBoostFocus,
                                prevFocusNode: _closeFocus,
                                value: _nightFocusEnabled,
                                onChanged: (v) async {
                                  await _notifier.setNightFocus(v);
                                  await _push();
                                },
                                child: const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          _buildTvCheckboxListTile(
                              focusNode: _dialogueBoostFocus,
                              nextFocusNode: _bassKillerFocus,
                              prevFocusNode: _nightFocusSwitchFocus,
                              enabled: _nightFocusEnabled,
                              value: _dialogueBoost,
                              onChanged: (v) async {
                                await _notifier
                                    .setNightFocusDialogueBoost(v ?? false);
                                await _push();
                              },
                              title: const Text(
                                'Dialogue Boost',
                                style: TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                'Rehausse la plage spectrale des voix '
                                '(1–4 kHz)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          _buildTvCheckboxListTile(
                              focusNode: _bassKillerFocus,
                              nextFocusNode: _vocalGainSliderFocus,
                              prevFocusNode: _dialogueBoostFocus,
                              enabled: _nightFocusEnabled,
                              value: _bassKiller,
                              onChanged: (v) async {
                                await _notifier
                                    .setNightFocusBassKiller(v ?? false);
                                await _push();
                              },
                              title: const Text(
                                'Bass Killer & Limiteur',
                                style: TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                'Atténue les sub-bass et compresse les '
                                'surcharges soudaines',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (_nightFocusEnabled && _dialogueBoost) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Amplification des voix :',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '+${_vocalGainDb.toStringAsFixed(1)} dB',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            _buildTvSlider(
                              focusNode: _vocalGainSliderFocus,
                              nextFocusNode: _shiftMinusFocus,
                              prevFocusNode: _bassKillerFocus,
                              value: _vocalGainDb,
                              min: 1.0,
                              max: 8.0,
                              divisions: 14,
                              label: '+${_vocalGainDb.toStringAsFixed(1)} dB',
                              onChanged: (v) async {
                                await _notifier.setNightFocusVocalGainDb(v);
                                await _push();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sync_problem,
                                color: scheme.tertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Décalage piste audio (A/V sync)',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTvIconButton(
                                focusNode: _shiftMinusFocus,
                                nextFocusNode: _shiftPlusFocus,
                                prevFocusNode: _vocalGainSliderFocus,
                                onPressed: () async {
                                  await _notifier.setNightFocusAudioShiftMs(
                                    _audioShiftMs - 50,
                                  );
                                  await _push();
                                },
                                icon: Icons.remove_circle_outline,
                                tooltip: l.audioShiftMinus50,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_audioShiftMs >= 0 ? "+" : ""}'
                                  '$_audioShiftMs ms',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildTvIconButton(
                                focusNode: _shiftPlusFocus,
                                nextFocusNode: _resetFocus,
                                prevFocusNode: _shiftMinusFocus,
                                onPressed: () async {
                                  await _notifier.setNightFocusAudioShiftMs(
                                    _audioShiftMs + 50,
                                  );
                                  await _push();
                                },
                                icon: Icons.add_circle_outline,
                                tooltip: l.audioShiftPlus50,
                              ),
                              _buildTvTextButton(
                                focusNode: _resetFocus,
                                nextFocusNode: _closeFocus,
                                prevFocusNode: _shiftPlusFocus,
                                onPressed: () async {
                                  await _notifier.setNightFocusAudioShiftMs(0);
                                  await _push();
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
