import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Sprint 3 — Création / Édition de profil :
/// - nom (formatté), type Adulte/Enfant/Expert,
/// - avatar « dégradé orbital » + initiale du prénom,
/// - protection par code PIN (pavé TV) pour Enfant/Expert.
///
/// Sprint 5 — abandon du masquage automatique : aucun contenu n'est masqué
/// par l'UI. Les booléens `hideAdultContent`/`hideViolentContent` du modèle
/// restent (compat données) mais ne sont plus édités ici.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.profileId});

  /// Identifiant du profil à modifier (`null` = création).
  final String? profileId;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  ProfileType _type = ProfileType.adult;
  int _gradientIndex = 0;
  String? _pinHash;
  bool _saving = false;
  bool _submitted = false;
  UserProfile? _loadedTarget;

  bool get _isEdit => widget.profileId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _fillFromProfile(UserProfile profile) {
    if (_loadedTarget?.id == profile.id) return;
    _loadedTarget = profile;
    _nameController.text = profile.firstName;
    _type = profile.profileType;
    final raw = profile.avatarUrl.trim();
    final idx = raw.startsWith(ProfileAvatar.orbitGradientPrefix)
        ? int.tryParse(
              raw.substring(ProfileAvatar.orbitGradientPrefix.length),
            ) ??
            -1
        : -1;
    _gradientIndex = (idx >= 0 && idx < orbitGradientOptions.length) ? idx : 0;
    _pinHash = profile.pinHash;
  }

  UserProfile _avatarPreviewProfile() {
    return UserProfile(
      id: 'preview',
      firstName: _nameController.text.trim().isEmpty
          ? '?'
          : _nameController.text.trim(),
      dateOfBirth: DateTime(2000),
      gender: 'Non spécifié',
      favoriteGenres: const [],
      avatarUrl: '${ProfileAvatar.orbitGradientPrefix}$_gradientIndex',
    );
  }

  void _onTypeChanged(ProfileType type) {
    setState(() => _type = type);
  }

  Future<void> _openPinPad() async {
    final pin = await context.push<String>(
      '/profile/pin',
      extra: const PinPadArgs.set(),
    );
    if (pin != null && mounted) {
      setState(() => _pinHash = pin);
    }
  }

  Future<void> _onPinSwitch(bool enable) async {
    if (enable) {
      await _openPinPad();
    } else {
      setState(() => _pinHash = null);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final avatarUrl = '${ProfileAvatar.orbitGradientPrefix}$_gradientIndex';
      final now = DateTime.now();
      if (_isEdit) {
        final target = _loadedTarget;
        if (target == null) {
          setState(() => _saving = false);
          return;
        }
        final updated = target.copyWith(
          firstName: name,
          profileType: _type,
          avatarUrl: avatarUrl,
          pinHash: _pinHash,
          updatedAt: now,
        );
        await ref.read(storageServiceProvider).saveProfile(updated);
        final current = ref.read(currentProfileProvider);
        if (current?.id == updated.id) {
          ref.read(currentProfileProvider.notifier).state = updated;
          ref.read(profileTypeProvider.notifier).loadFromProfile(updated);
        }
        ref.invalidate(profilesProvider);
        if (mounted) context.pop();
        return;
      }

      final profiles =
          ref.read(profilesProvider).valueOrNull ?? const <UserProfile>[];
      final maxAllowed =
          profiles.isEmpty ? 5 : profiles.first.maxProfilesAllowed;
      if (profiles.length >= maxAllowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nombre maximal de profils atteint ($maxAllowed)'),
            ),
          );
        }
        setState(() => _saving = false);
        return;
      }

      final profile = UserProfile(
        id: const Uuid().v4(),
        firstName: name,
        dateOfBirth: DateTime(now.year - 25, 1, 1),
        gender: 'Non spécifié',
        favoriteGenres: const [],
        avatarUrl: avatarUrl,
        profileType: _type,
        pinHash: _pinHash,
        maxProfilesAllowed: maxAllowed,
      );
      await ref.read(storageServiceProvider).saveProfile(profile);
      ref.invalidate(profilesProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sauvegarde')),
        );
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showPin = _type == ProfileType.child || _type == ProfileType.expert;

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 8),
        _buildIdentityCard(),
        const SizedBox(height: 16),
        _buildTypeSection(),
        if (showPin) ...[
          const SizedBox(height: 16),
          _buildPinSection(),
        ],
        const SizedBox(height: 8),
        _buildActions(),
      ],
    );

    if (!_isEdit) return _scaffold(body);

    return _scaffold(
      ref.watch(profilesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur: $err')),
            data: (profiles) {
              UserProfile? target;
              for (final p in profiles) {
                if (p.id == widget.profileId) {
                  target = p;
                  break;
                }
              }
              if (target == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Aucun profil à modifier',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.go('/profiles'),
                        child: const Text('Choisir un profil'),
                      ),
                    ],
                  ),
                );
              }
              _fillFromProfile(target);
              return body;
            },
          ),
    );
  }

  Widget _scaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le profil' : 'Créer un profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(key: _formKey, child: body),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (context, value, _) {
              return ProfileAvatar(
                profile: _avatarPreviewProfile(),
                size: 104,
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dégradé orbital',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choisissez la couleur de votre avatar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < orbitGradientOptions.length; i++)
                      _GradientSwatch(
                        gradient: orbitGradientOptions[i],
                        selected: _gradientIndex == i,
                        onTap: () => setState(() => _gradientIndex = i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard() {
    return AppCard(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            maxLength: AppConstants.maxNameLength,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp("[a-zA-Z\\u00C0-\\u017F' -]"),
              ),
              LengthLimitingTextInputFormatter(AppConstants.maxNameLength),
            ],
            decoration: InputDecoration(
              labelText: 'Nom / Pseudo',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
              errorText: _submitted && _nameController.text.trim().isEmpty
                  ? 'Obligatoire'
                  : null,
            ),
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type de profil',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ProfileType>(
              segments: const [
                ButtonSegment(
                  value: ProfileType.adult,
                  label: Text('Adulte'),
                  icon: Icon(Icons.sentiment_satisfied_alt),
                ),
                ButtonSegment(
                  value: ProfileType.child,
                  label: Text('Enfant'),
                  icon: Icon(Icons.child_care),
                ),
                ButtonSegment(
                  value: ProfileType.expert,
                  label: Text('Expert'),
                  icon: Icon(Icons.psychology_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  _onTypeChanged(selection.first),
              showSelectedIcon: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _type == ProfileType.child
                ? 'Profil enfant · réglages par âge (gérés par PIN)'
                : _type == ProfileType.expert
                    ? 'Recommandations avancées · protection par PIN'
                    : 'Accès complet aux contenus',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    return AppCard(
      child: Column(
        children: [
          SettingsSwitchTile(
            icon: Icons.pin_outlined,
            title: 'Protéger par code PIN',
            subtitle: _pinHash != null
                ? 'Un code PIN de 4 chiffres est défini'
                : 'Demander un code PIN à la sélection du profil',
            value: _pinHash != null,
            onChanged: _onPinSwitch,
          ),
          if (_pinHash != null)
            SettingsActionTile(
              icon: Icons.pin,
              title: 'Changer le code PIN',
              subtitle: 'Saisir un nouveau code à 4 chiffres',
              onTap: _openPinPad,
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => context.pop(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Enregistrer' : 'Créer le profil'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientSwatch extends StatelessWidget {
  const _GradientSwatch({
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final OrbitGradient gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradient.start, gradient.end],
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: gradient.start.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
