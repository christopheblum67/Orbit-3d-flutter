import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';

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
    if (!mounted) return;
    ref.invalidate(deviceProfileProvider);

    // Après le profil, on lance la création d'abonnement
    await _showSubscriptionCreation();
  }

  Future<void> _showSubscriptionCreation() async {
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SubscriptionCreationDialog(
        onSaved: () {
          Navigator.of(ctx).pop(true);
        },
        onCancel: () {
          Navigator.of(ctx).pop(false);
        },
      ),
    );

    if (result == true && mounted) {
      await _showCategoryFilters();
    } else if (mounted) {
      // Si annulé, on redemande la création
      await _showSubscriptionCreation();
    }
  }

  Future<void> _showCategoryFilters() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CategoryFiltersDialog(
        onSaved: () {
          Navigator.of(ctx).pop(true);
        },
        onSkip: () {
          Navigator.of(ctx).pop(false);
        },
      ),
    );

    if (mounted) {
      await _showRestartDialog();
    }
  }

  Future<void> _showRestartDialog() async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            Text(
              'Configuration terminée',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'La configuration initiale est terminée.\n\n'
          'L\'application doit redémarrer pour appliquer tous les réglages.',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TvFocus(
                  autofocus: true,
                  onActivate: () {
                    Navigator.of(ctx).pop();
                    SystemNavigator.pop();
                  },
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      SystemNavigator.pop();
                    },
                    child: const Text('Redémarrer maintenant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final l = AppLocalizations.of(context);
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
            label: l.memory,
            value: specs.memoryLabel,
          ),
          _DeviceRow(
            icon: Icons.wifi_rounded,
            label: 'Connexion',
            value: specs.connectionLabel,
          ),
          _DeviceRow(
            icon: Icons.straighten_rounded,
            label: l.sdkAndroid,
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
    final l = AppLocalizations.of(context);
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Row(
        children: [
          Expanded(
            child: TvFocus(
              onActivate: _saving
                  ? null
                  : () => setState(() {
                        _adjusting = !_adjusting;
                        _selected = null;
                      }),
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
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: TvFocus(
              autofocus: true,
              onActivate: _saving ? null : _validate,
              child: FilledButton.icon(
                onPressed: _saving ? null : _validate,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(l.confirmAndContinue),
              ),
            ),
          ),
        ],
      ),
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
                    final l = AppLocalizations.of(context);
                    return Center(child: Text(l.diagnosticUnavailable));
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

/// Dialog de création d'abonnement au premier lancement
class _SubscriptionCreationDialog extends ConsumerStatefulWidget {
  const _SubscriptionCreationDialog({
    super.key,
    required this.onSaved,
    required this.onCancel,
  });

  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  ConsumerState<_SubscriptionCreationDialog> createState() =>
      _SubscriptionCreationDialogState();
}

class _SubscriptionCreationDialogState
    extends ConsumerState<_SubscriptionCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _nameFocus = FocusNode();
  final _baseUrlFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _m3uFocus = FocusNode();
  final _submitFocus = FocusNode();
  final _typeFocus = FocusNode();
  SubscriptionType _type = SubscriptionType.xtream;
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uUrlController.dispose();
    _nameFocus.dispose();
    _baseUrlFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _m3uFocus.dispose();
    _submitFocus.dispose();
    _typeFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(focus);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final sub = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        type: _type,
        baseUrl: _type == SubscriptionType.xtream
            ? _baseUrlController.text.trim()
            : null,
        username: _type == SubscriptionType.xtream
            ? _usernameController.text.trim()
            : null,
        password: _type == SubscriptionType.xtream
            ? _passwordController.text.trim()
            : null,
        m3uUrl: _type == SubscriptionType.m3u
            ? _m3uUrlController.text.trim()
            : null,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await ref.read(subscriptionsProvider.notifier).addSubscription(sub);

      // Active l'abonnement et recharge les données
      await ref.read(subscriptionsProvider.notifier).setActive(sub.id);
      await ref.read(subscriptionsProvider.notifier).testConnection(sub);

      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      title: Text(
        'Créer votre premier abonnement',
        style: TextStyle(color: scheme.onSurface, fontSize: 18),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. NOM
                  TvFocus(
                    focusNode: _nameFocus,
                    onFocusChange: (hasFocus) {},
                    child: TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'abonnement',
                        prefixIcon: Icon(Icons.edit_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => _requestFocus(_typeFocus),
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. TYPE XTREAM / M3U (EN HAUT - tabbar)
                  TvFocus(
                    focusNode: _typeFocus,
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        if (_type != SubscriptionType.m3u) {
                          setState(() => _type = SubscriptionType.m3u);
                          _requestFocus(_m3uFocus);
                        }
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        if (_type != SubscriptionType.xtream) {
                          setState(() => _type = SubscriptionType.xtream);
                          _requestFocus(_baseUrlFocus);
                        }
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        final nextFocus = _type == SubscriptionType.xtream
                            ? _baseUrlFocus
                            : _m3uFocus;
                        _requestFocus(nextFocus);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type de source',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<SubscriptionType>(
                          segments: [
                            ButtonSegment(
                              value: SubscriptionType.xtream,
                              label: Text('Xtream Codes'),
                              icon: const Icon(Icons.tv_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: SubscriptionType.m3u,
                              label: Text('M3U Playlist'),
                              icon: const Icon(Icons.playlist_play_outlined, size: 18),
                            ),
                          ],
                          selected: {_type},
                          onSelectionChanged: (Set<SubscriptionType> newSelection) {
                            setState(() => _type = newSelection.first);
                          },
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. CHAMPS SELON TYPE
                  if (_type == SubscriptionType.xtream) ...[
                    TvFocus(
                      child: TextFormField(
                        controller: _baseUrlController,
                        focusNode: _baseUrlFocus,
                        decoration: InputDecoration(
                          labelText: 'URL du serveur (baseUrl)',
                          prefixIcon: const Icon(Icons.link_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => _requestFocus(_usernameFocus),
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TvFocus(
                      child: TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => _requestFocus(_passwordFocus),
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TvFocus(
                      focusNode: _passwordFocus,
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent) return KeyEventResult.ignored;
                        if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.space ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                          _requestFocus(_submitFocus);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                  ] else ...[
                    TvFocus(
                      focusNode: _m3uFocus,
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent) return KeyEventResult.ignored;
                        if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.space ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                          _requestFocus(_submitFocus);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextFormField(
                        controller: _m3uUrlController,
                        focusNode: _m3uFocus,
                        decoration: InputDecoration(
                          labelText: 'URL Playlist M3U',
                          prefixIcon: const Icon(Icons.playlist_play_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TvFocus(
          focusNode: _submitFocus,
          autofocus: false,
          onActivate: _saving ? null : _save,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA) {
              _save();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.gameButtonB) {
              widget.onCancel();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              final prevFocus = _type == SubscriptionType.xtream
                  ? _passwordFocus
                  : _m3uFocus;
              _requestFocus(prevFocus);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : widget.onCancel,
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Créer'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dialog de sélection des filtres de catégories
class _CategoryFiltersDialog extends ConsumerStatefulWidget {
  const _CategoryFiltersDialog({
    super.key,
    required this.onSaved,
    required this.onSkip,
  });

  final VoidCallback onSaved;
  final VoidCallback onSkip;

  @override
  ConsumerState<_CategoryFiltersDialog> createState() =>
      _CategoryFiltersDialogState();
}

class _CategoryFiltersDialogState extends ConsumerState<_CategoryFiltersDialog> {
  final List<String> _allCategories = const [
    'Films',
    'Séries',
    'Sport',
    'Actualités',
    'Documentaires',
    'Enfants',
    'Musique',
    'Cinéma',
    'Divertissement',
    'Sciences',
    'Technologie',
    'Nature',
    'Histoire',
    'Culture',
    'Art',
  ];

  late List<String> _selectedCategories;
  late FocusNode _listFocus;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _listFocus = FocusNode();
    _selectedCategories = [];
  }

  @override
  void dispose() {
    _listFocus.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      title: Text(
        'Filtres de catégories',
        style: TextStyle(color: scheme.onSurface, fontSize: 18),
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionnez les catégories à afficher\n(les autres seront masquées)',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TvFocus(
                focusNode: _listFocus,
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_focusedIndex < _allCategories.length - 1) {
                      setState(() => _focusedIndex++);
                    }
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_focusedIndex > 0) {
                      setState(() => _focusedIndex--);
                    }
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.space ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                    if (_focusedIndex < _allCategories.length) {
                      _toggleCategory(_allCategories[_focusedIndex]);
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _allCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = _allCategories[index];
                      final isSelected = _selectedCategories.contains(category);
                      final isFocused = index == _focusedIndex;
                      return Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus) setState(() => _focusedIndex = index);
                        },
                        child: TvFocus(
                          onActivate: () => _toggleCategory(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primary.withValues(alpha: 0.2)
                                  : (isFocused
                                      ? scheme.surfaceContainerHighest
                                      : scheme.surfaceContainerLow),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? scheme.primary
                                    : (isFocused
                                        ? scheme.primary
                                        : scheme.outlineVariant),
                                width: isSelected ? 2 : (isFocused ? 2 : 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? scheme.primary
                                      : (isFocused
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 15,
                                      fontWeight:
                                          isSelected || isFocused
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedCategories.clear());
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Tout désélectionner'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedCategories = List.from(_allCategories));
                  },
                  icon: const Icon(Icons.checklist),
                  label: const Text('Tout sélectionner'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: [
              Expanded(
                child: TvFocus(
                  autofocus: true,
                  onActivate: widget.onSkip,
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: const Text('Ignorer'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TvFocus(
                  onActivate: widget.onSaved,
                  child: FilledButton(
                    onPressed: widget.onSaved,
                    child: const Text('Enregistrer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}