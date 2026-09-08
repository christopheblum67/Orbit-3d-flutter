import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Sprint Phase 1 — Configuration du premier lancement.
///
/// Diagnostique l'appareil (matériel, connexion, mémoire), recommande un
/// profil Eco/Standard/Ultra et applique les réglages de lecture associés.
/// L'utilisateur peut valider la recommandation ou l'ajuster manuellement,
/// navigation télécommande (d-pad).
class OnboardingConfigScreen extends ConsumerStatefulWidget {
  const OnboardingConfigScreen({super.key});

  @override
  ConsumerState<OnboardingConfigScreen> createState() =>
      _OnboardingConfigScreenState();
}

class _OnboardingConfigScreenState
    extends ConsumerState<OnboardingConfigScreen> {
  late Future<HardwareSpecs> _detection;
  HardwareSpecs? _specs;
  DeviceProfile? _selected;
  bool _adjusting = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _detection = HardwareDetectorService.analyze();
  }

  Future<void> _validate() async {
    final profile = _selected ?? _specs?.recommendedProfile;
    if (profile == null || _saving) return;
    setState(() => _saving = true);
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting(kDeviceProfileKey, profile.name);
    await storage.setSetting(kOnboardingDoneKey, true);
    // Prépare la recherche vocale : demande la permission micro pendant la
    // configuration automatique, plutôt qu'au moment de la première dictée.
    if (profile.allowsVoiceSearch) {
      unawaited(_prewarmMicrophone());
    }
    ref.invalidate(deviceProfileProvider);
    if (!mounted) return;
    context.go('/profiles');
  }

  /// Préchauffe SpeechToText (déclenche la demande d'autorisation micro)
  /// sans bloquer la navigation.
  Future<void> _prewarmMicrophone() async {
    final speech = SpeechToText();
    try {
      await speech.initialize();
    } catch (_) {}
  }

  String _profileDescription(DeviceProfile profile) {
    return switch (profile) {
      DeviceProfile.eco =>
        'Tampon long (20 s) · max 1080p · 3D désactivée · multi-vue off',
      DeviceProfile.standard =>
        'Tampon intermédiaire (10 s) · rendu 3D fluide · multi-vue x2',
      DeviceProfile.ultra =>
        'Zapping rapide (3 s · 4K HDR possible) · multi-vue x4',
    };
  }

  IconData _profileIcon(DeviceProfile profile) {
    return switch (profile) {
      DeviceProfile.eco => Icons.battery_saver_rounded,
      DeviceProfile.standard => Icons.speed_rounded,
      DeviceProfile.ultra => Icons.rocket_launch_rounded,
    };
  }

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue sur Orbit IPTV',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configuration automatique de votre appareil',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(HardwareSpecs specs) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appareil détecté',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          _DeviceRow(
            icon: Icons.tv_outlined,
            label: 'Appareil',
            value: specs.isTv ? '${specs.deviceName} (TV)' : specs.deviceName,
          ),
          _DeviceRow(
            icon: Icons.memory_rounded,
            label: 'Mémoire',
            value: specs.memoryLabel,
          ),
          _DeviceRow(
            icon: Icons.wifi_rounded,
            label: 'Connexion',
            value: specs.connectionLabel,
          ),
          _DeviceRow(
            icon: Icons.straighten_rounded,
            label: 'SDK Android',
            value: specs.sdkInt > 0 ? 'API ${specs.sdkInt}' : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(DeviceProfile profile, {bool highlight = true}) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _adjusting && _selected == profile;
    return _FocusableOption(
      onTap: _adjusting ? () => setState(() => _selected = profile) : null,
      selected: isSelected,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlight
                ? [scheme.primaryContainer, scheme.surfaceContainerLow]
                : [scheme.surfaceContainerHigh, scheme.surfaceContainerHigh],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(_profileIcon(profile), size: 26, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil ${profile.label}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profileDescription(profile),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () => setState(() {
                      _adjusting = !_adjusting;
                      _selected = null;
                    }),
            icon: Icon(_adjusting ? Icons.auto_awesome_rounded : Icons.tune),
            label: Text(
              _adjusting
                  ? 'Réinitialiser la recommandation'
                  : 'Ajuster manuellement',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : _validate,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Valider et continuer'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<HardwareSpecs>(
                future: _detection,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Analyse de l\'appareil…'),
                        ],
                      ),
                    );
                  }
                  final specs = snapshot.data;
                  if (specs == null) {
                    return const Center(child: Text('Diagnostic indisponible'));
                  }
                  _specs ??= specs;
                  final recommended = specs.recommendedProfile;
                  final displayed = _adjusting && _selected != null
                      ? _selected!
                      : recommended;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDeviceCard(specs),
                        const SizedBox(height: 16),
                        Text(
                          _adjusting
                              ? 'Choisissez un profil'
                              : 'Profil recommandé',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        _buildProfileCard(recommended, highlight: true),
                        if (_adjusting) ...[
                          const SizedBox(height: 10),
                          for (final profile in DeviceProfile.values)
                            if (profile != recommended) ...[
                              _buildProfileCard(profile, highlight: false),
                              const SizedBox(height: 10),
                            ],
                        ] else ...[
                          const SizedBox(height: 10),
                          _buildProfileHint(displayed),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHint(DeviceProfile profile) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      profile.disable3D ? 'Effets 3D et multi-vue désactivés.' : '',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Option focale (d-pad) : sélectionnable quand [onTap] n'est pas null.
class _FocusableOption extends StatefulWidget {
  const _FocusableOption({
    required this.child,
    this.onTap,
    required this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  State<_FocusableOption> createState() => _FocusableOptionState();
}

class _FocusableOptionState extends State<_FocusableOption> {
  bool _focused = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: widget.onTap != null,
      onFocusChange: (hasFocus) {
        if (hasFocus && widget.onTap != null) HapticFeedback.selectionClick();
        setState(() => _focused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (widget.onTap == null) return KeyEventResult.ignored;
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          _activate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap == null ? null : _activate,
        child: AnimatedScale(
          scale: _focused ? 1.015 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
