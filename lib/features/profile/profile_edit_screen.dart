import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_picker_grid.dart';
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
  ConsumerState<ProfileEditScreen> createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  ProfileType _type = ProfileType.adult;
  int _gradientIndex = 0;
  String? _remoteAvatarUrl;
  String? _pinHash;
  DateTime? _dateOfBirth;
  String _gender = 'Non spécifié';
  final List<String> _favoriteGenres = [];
  bool _saving = false;
  bool _submitted = false;
  UserProfile? _loadedTarget;

  /// Valeurs initiales du formulaire (pour la détection de modifications).
  String _baseName = '';
  ProfileType _baseType = ProfileType.adult;
  int _baseGradientIndex = 0;
  String? _baseRemoteAvatarUrl;
  String? _basePinHash;
  DateTime? _baseDateOfBirth;
  String _baseGender = 'Non spécifié';
  final List<String> _baseFavoriteGenres = [];

  /// `true` si le formulaire contient des modifications non sauvegardées
  /// (utilisé par la garde de retour « quitter sans sauvegarder ? »).
  bool get isDirty {
    if (_isEdit && _loadedTarget == null) return false;
    return _nameController.text.trim() != _baseName ||
        _type != _baseType ||
        _gradientIndex != _baseGradientIndex ||
        _remoteAvatarUrl != _baseRemoteAvatarUrl ||
        _pinHash != _basePinHash ||
        _dateOfBirth != _baseDateOfBirth ||
        _gender != _baseGender ||
        !_listEquals(_favoriteGenres, _baseFavoriteGenres);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Propose la garde « quitter sans sauvegarder ? » si le formulaire est sale,
  /// puis quitte via [router.pop] si confirmé.
  Future<void> handleBack() async {
    if (!await confirmLeave() || !mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Quitter sans sauvegarder ?'),
        content: const Text(
          'Des modifications non sauvegardées seront perdues. Quitter quand même ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Montre la boîte de dialogue « quitter sans sauvegarder ? » si le
  /// formulaire est sale et retourne si l'utilisateur confirme le départ.
  Future<bool> confirmLeave() async {
    if (!isDirty) return true;
    return _confirmDiscard();
  }

  static const _ageRanges = [
    (label: '- 12 ans', min: 0, max: 12),
    (label: '13 - 17 ans', min: 13, max: 17),
    (label: '18 - 24 ans', min: 18, max: 24),
    (label: '25 - 34 ans', min: 25, max: 34),
    (label: '35 - 44 ans', min: 35, max: 44),
    (label: '45 - 54 ans', min: 45, max: 54),
    (label: '55 ans et plus', min: 55, max: 100),
  ];

  static const _genderOptions = ['Homme', 'Femme', 'Autre'];

  static const _genreOptions = [
    'Action',
    'Aventure',
    'Animation',
    'Comédie',
    'Comédie romantique',
    'Drame',
    'Horreur',
    'Thriller',
    'Policier',
    'Crime',
    'Guerre',
    'Historique',
    'Western',
    'Sci-Fi',
    'Fantasy',
    'Super-héros',
    'Mystère',
    'Romance',
    'Musical',
    'Musique',
    'Biopic',
    'Documentaire',
    'Tournoi',
    'Enfants',
    'Famille',
    'Suspense',
    'Noir & Blanc',
    'Classique',
  ];

  int get _ageRangeIndex {
    if (_dateOfBirth == null) return 2;
    final age = DateTime.now().difference(_dateOfBirth!).inDays ~/ 365;
    for (var i = 0; i < _ageRanges.length; i++) {
      if (age >= _ageRanges[i].min && age <= _ageRanges[i].max) return i;
    }
    return 2;
  }

  DateTime _dateForRange(int index) {
    final now = DateTime.now();
    return DateTime(now.year - _ageRanges[index].max, now.month, now.day);
  }

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
    _dateOfBirth = profile.dateOfBirth;
    _gender = profile.gender.isEmpty ? 'Non spécifié' : profile.gender;
    _favoriteGenres
      ..clear()
      ..addAll(profile.favoriteGenres);
    final raw = profile.avatarUrl.trim();
    final isIcon = raw.startsWith(ProfileAvatar.avatarIconPrefix);
    final isOrbital = raw.startsWith(ProfileAvatar.orbitGradientPrefix);
    if (!isIcon && !isOrbital && raw.isNotEmpty) {
      _remoteAvatarUrl = raw;
    } else {
      _remoteAvatarUrl = null;
    }
    final idx = isOrbital
        ? int.tryParse(
              raw.substring(ProfileAvatar.orbitGradientPrefix.length),
            ) ??
            -1
        : -1;
    _gradientIndex = (idx >= 0 && idx < orbitGradientOptions.length) ? idx : 0;
    _pinHash = profile.pinHash;
    _captureBaseline();
  }

  void _captureBaseline() {
    _baseName = _nameController.text.trim();
    _baseType = _type;
    _baseGradientIndex = _gradientIndex;
    _baseRemoteAvatarUrl = _remoteAvatarUrl;
    _basePinHash = _pinHash;
    _baseDateOfBirth = _dateOfBirth;
    _baseGender = _gender;
    _baseFavoriteGenres
      ..clear()
      ..addAll(_favoriteGenres);
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
      avatarUrl: _remoteAvatarUrl ??
          '${ProfileAvatar.orbitGradientPrefix}$_gradientIndex',
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
      final avatarUrl = _remoteAvatarUrl ??
          '${ProfileAvatar.orbitGradientPrefix}$_gradientIndex';
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
          dateOfBirth: _dateOfBirth ?? _dateForRange(_ageRangeIndex),
          gender: _gender.isEmpty ? 'Non spécifié' : _gender,
          favoriteGenres: List.of(_favoriteGenres),
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
        dateOfBirth: _dateOfBirth ?? _dateForRange(_ageRangeIndex),
        gender: _gender.isEmpty ? 'Non spécifié' : _gender,
        favoriteGenres: List.of(_favoriteGenres),
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
        const SizedBox(height: 16),
        _buildAvatarPickerCard(),
        const SizedBox(height: 8),
        _buildIdentityCard(),
        const SizedBox(height: 16),
        _buildPersonalCard(),
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
          onPressed: handleBack,
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
                        onTap: () => setState(() {
                          _remoteAvatarUrl = null;
                          _gradientIndex = i;
                        }),
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

  Widget _buildAvatarPickerCard() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avatars',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisissez un avatar 3D parmi 30 modèles',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          AvatarPickerGrid(
            selectedImageUrl: _remoteAvatarUrl ?? '',
            onAvatarSelected: (url) => setState(() {
              _remoteAvatarUrl = url;
            }),
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

  Widget _buildPersonalCard() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Âge',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'La tranche d\'âge sert aux réglages du profil',
            style:
                textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _ageRanges.length; i++)
                _ProfileChoiceChip(
                  label: _ageRanges[i].label,
                  selected: _ageRangeIndex == i,
                  onTap: () => setState(() {
                    _dateOfBirth = _dateForRange(i);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Genre',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                for (final option in _genderOptions)
                  ButtonSegment(value: option, label: Text(option)),
              ],
              selected: {_gender},
              onSelectionChanged: (selection) =>
                  setState(() => _gender = selection.first),
              showSelectedIcon: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Genres de films favoris',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisissez un ou plusieurs styles pour les recommandations',
            style:
                textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in _genreOptions)
                _ProfileChoiceChip(
                  label: genre,
                  selected: _favoriteGenres.contains(genre),
                  onTap: () => setState(() {
                    if (_favoriteGenres.contains(genre)) {
                      _favoriteGenres.remove(genre);
                    } else {
                      _favoriteGenres.add(genre);
                    }
                  }),
                ),
            ],
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
              onPressed: _saving ? null : handleBack,
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

/// Puces focales du pad (tranche d'âge / genre de film), sélectionnables
/// et navigables au d-pad avec retour haptique.
class _ProfileChoiceChip extends StatefulWidget {
  const _ProfileChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ProfileChoiceChip> createState() => _ProfileChoiceChipState();
}

class _ProfileChoiceChipState extends State<_ProfileChoiceChip> {
  bool _focused = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlighted = widget.selected || _focused;
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) HapticFeedback.selectionClick();
        setState(() => _focused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          _activate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _activate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.selected
                  ? scheme.primary
                  : _focused
                      ? scheme.tertiary
                      : scheme.outlineVariant,
              width: widget.selected ? 2 : (_focused ? 2 : 1),
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: scheme.tertiary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selected) ...[
                Icon(
                  Icons.check_circle,
                  size: 17,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: highlighted
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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
