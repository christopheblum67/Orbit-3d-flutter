import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/services/night_focus_audio_service.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

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
  ConsumerState<AudioControlsSheet> createState() =>
      _AudioControlsSheetState();
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

  AdvancedSettingsNotifier get _notifier =>
      ref.read(advancedSettingsProvider.notifier);

  Future<void> _push() async {
    await NightFocusAudioService.push(
      _nightFocusEnabled,
      dialogueBoostDb: _dialogueBoost ? 4.0 : 0,
      bassKillerCutoffHz: _bassKiller ? 120.0 : 0,
      vocalGainDb: _dialogueBoost ? _vocalGainDb : 0,
      audioDelayMs: _audioShiftMs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
                    IconButton(
                      tooltip: 'Fermer',
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
                              Switch(
                                value: _nightFocusEnabled,
                                onChanged: (v) async {
                                  await _notifier.setNightFocus(v);
                                  await _push();
                                },
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            enabled: _nightFocusEnabled,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
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
                            value: _dialogueBoost,
                            onChanged: (v) async {
                              await _notifier
                                  .setNightFocusDialogueBoost(v ?? false);
                              await _push();
                            },
                          ),
                          CheckboxListTile(
                            enabled: _nightFocusEnabled,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
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
                            value: _bassKiller,
                            onChanged: (v) async {
                              await _notifier
                                  .setNightFocusBassKiller(v ?? false);
                              await _push();
                            },
                          ),
                          if (_nightFocusEnabled && _dialogueBoost) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                            Slider(
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
                              IconButton(
                                tooltip: '-50 ms',
                                onPressed: () async {
                                  await _notifier.setNightFocusAudioShiftMs(
                                    _audioShiftMs - 50,
                                  );
                                  await _push();
                                },
                                icon: const Icon(Icons.remove_circle_outline),
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
                              IconButton(
                                tooltip: '+50 ms',
                                onPressed: () async {
                                  await _notifier.setNightFocusAudioShiftMs(
                                    _audioShiftMs + 50,
                                  );
                                  await _push();
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              TextButton(
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
