import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Sous-fenêtre « Audio & Night Focus » ouverte depuis le lecteur.
///
/// Le **moteur interne** (`video_player`/ExoPlayer) embarque désormais un
/// processeur audio natif « Night Focus » (Dialogue Boost, Bass Killer, gain
/// vocal, décalage A/V) actif quand le switch maître est ON. Tous les réglages
/// sont persistés (SharedPreferences) et poussés au natif à chaque changement
/// via [NightFocusAudioService] ; le player ré-applique la config à la lecture.
Future<void> showAudioControlsSheet(
  BuildContext context, {
  bool focusAudioSync = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => AudioControlsSheet(focusAudioSync: focusAudioSync),
  );
}

class AudioControlsSheet extends ConsumerStatefulWidget {
  const AudioControlsSheet({super.key, this.focusAudioSync = false});

  final bool focusAudioSync;

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

  void _keepVisible(FocusNode focus, bool focused) {
    if (!focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = focus.context;
      if (mounted && target != null && focus.hasFocus) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 180),
          alignment: 0.5,
        );
      }
    });
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
  }) {
    return TvFocus(
      focusNode: focusNode,
      onFocusChange: (focused) => _keepVisible(focusNode, focused),
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
      child: ExcludeFocus(
        child: Switch(
          value: value,
          onChanged: onChanged,
        ),
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
    FocusNode? leftFocusNode,
    FocusNode? rightFocusNode,
  }) {
    return TvFocus(
      focusNode: focusNode,
      onFocusChange: (focused) => _keepVisible(focusNode, focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              leftFocusNode != null) {
            _requestFocus(leftFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              rightFocusNode != null) {
            _requestFocus(rightFocusNode);
            return KeyEventResult.handled;
          }
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
      child: ExcludeFocus(
        child: CheckboxListTile(
          enabled: enabled,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: title,
          subtitle: subtitle,
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
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
    bool autofocus = false,
  }) {
    return TvFocus(
      focusNode: focusNode,
      onFocusChange: (focused) => _keepVisible(focusNode, focused),
      autofocus: autofocus,
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
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: ExcludeFocus(
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
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
    return TvFocus(
      focusNode: focusNode,
      onFocusChange: (focused) => _keepVisible(focusNode, focused),
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
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: ExcludeFocus(
        child: TextButton(
          onPressed: onPressed,
          child: child,
        ),
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
    return TvFocus(
      focusNode: focusNode,
      onFocusChange: (focused) => _keepVisible(focusNode, focused),
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
      child: ExcludeFocus(
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
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
                        Expanded(
                          child: Text(
                            l.audioAndNightFocus,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _buildTvIconButton(
                          focusNode: _closeFocus,
                          autofocus: !widget.focusAudioSync,
                          nextFocusNode: _nightFocusSwitchFocus,
                          prevFocusNode: _resetFocus,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icons.close,
                          tooltip: l.close,
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
                          l.audioNightHelp,
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
                                      l.audioNightTitle,
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontSize: 14,
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
                                  ),
                                ],
                              ),
                              LayoutBuilder(builder: (context, constraints) {
                                final horizontal = constraints.maxWidth >= 240;
                                final rtl = Directionality.of(context) ==
                                    TextDirection.rtl;
                                final dialogue = _buildTvCheckboxListTile(
                                  focusNode: _dialogueBoostFocus,
                                  leftFocusNode: horizontal && rtl
                                      ? _bassKillerFocus
                                      : null,
                                  rightFocusNode: horizontal && !rtl
                                      ? _bassKillerFocus
                                      : null,
                                  nextFocusNode: _bassKillerFocus,
                                  prevFocusNode: _nightFocusSwitchFocus,
                                  enabled: _nightFocusEnabled,
                                  value: _dialogueBoost,
                                  onChanged: (v) async {
                                    await _notifier
                                        .setNightFocusDialogueBoost(v ?? false);
                                    await _push();
                                  },
                                  title: Text(
                                    l.audioDialogueBoost,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    l.audioDialogueHelp,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                                final bass = _buildTvCheckboxListTile(
                                  focusNode: _bassKillerFocus,
                                  leftFocusNode: horizontal && !rtl
                                      ? _dialogueBoostFocus
                                      : null,
                                  rightFocusNode: horizontal && rtl
                                      ? _dialogueBoostFocus
                                      : null,
                                  nextFocusNode:
                                      _nightFocusEnabled && _dialogueBoost
                                          ? _vocalGainSliderFocus
                                          : _shiftMinusFocus,
                                  prevFocusNode: _dialogueBoostFocus,
                                  enabled: _nightFocusEnabled,
                                  value: _bassKiller,
                                  onChanged: (v) async {
                                    await _notifier
                                        .setNightFocusBassKiller(v ?? false);
                                    await _push();
                                  },
                                  title: Text(
                                    l.audioBassLimiter,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    l.audioBassHelp,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                                if (!horizontal) {
                                  return Column(children: [dialogue, bass]);
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: dialogue),
                                    const SizedBox(width: 8),
                                    Expanded(child: bass),
                                  ],
                                );
                              }),
                              if (_nightFocusEnabled && _dialogueBoost) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l.audioVocalGain,
                                        style: const TextStyle(fontSize: 12),
                                      ),
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
                                  label:
                                      '+${_vocalGainDb.toStringAsFixed(1)} dB',
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
                                  Expanded(
                                    child: Text(
                                      l.audioSyncTitle,
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.audioSyncLimitations,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildTvIconButton(
                                    focusNode: _shiftMinusFocus,
                                    autofocus: widget.focusAudioSync,
                                    nextFocusNode: _shiftPlusFocus,
                                    prevFocusNode:
                                        _nightFocusEnabled && _dialogueBoost
                                            ? _vocalGainSliderFocus
                                            : _bassKillerFocus,
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
                                        fontSize: 14,
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
                                      await _notifier
                                          .setNightFocusAudioShiftMs(0);
                                      await _push();
                                    },
                                    child: Text(l.reset),
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
        ),
      ),
    );
  }
}
