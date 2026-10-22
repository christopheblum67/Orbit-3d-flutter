import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/navigation/form_back_handler.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/auth/widgets/profile_avatar_selector.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

const List<String> _allGenres = [
  'Action',
  'Aventure',
  'Animation & Manga',
  'Comédie',
  'Crime & Policier',
  'Documentaire',
  'Drame',
  'Fantastique',
  'Horreur',
  'Romance',
  'Science-Fiction',
  'Thriller',
  'Guerre & Histoire',
  'Western',
  'Les Classiques',
  'Cinéma Indépendant',
];

const List<String> _genderOptions = [
  'Homme',
  'Femme',
  'Autre',
  'Non spécifié',
];

String _profileTypeToString(ProfileType t) {
  switch (t) {
    case ProfileType.child:
      return 'Enfant';
    case ProfileType.expert:
      return 'Expert';
    case ProfileType.adult:
      return 'Adulte';
  }
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.profileId});

  final String? profileId;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen>
    with FormBackHandler {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _nameFocus = FocusNode();
  final _ageFocus = FocusNode();
  String? _gender;
  ProfileType? _profileType;
  String _avatarId = '';
  final List<String> _favoriteGenres = [];
  bool _saving = false;
  String? _loadedProfileId;

  @override
  bool get isFormDirty {
    // Vérifie si le formulaire a été modifié par rapport aux valeurs initiales
    return _formKey.currentState?.validate() != true || _hasUnsavedChanges();
  }

  bool _hasUnsavedChanges() {
    // Logique simplifiée : si le formulaire a été touché
    // Dans une version plus complète, on comparerait aux valeurs initiales
    return _nameController.text.isNotEmpty ||
        _ageController.text.isNotEmpty ||
        _gender != null ||
        _profileType != null ||
        _avatarId.isNotEmpty ||
        _favoriteGenres.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _nameFocus.dispose();
    _ageFocus.dispose();
    super.dispose();
  }

  void _fillFromProfile(UserProfile profile) {
    if (_loadedProfileId == profile.id) return;
    _loadedProfileId = profile.id;
    _nameController.text = profile.firstName;
    final now = DateTime.now();
    var age = now.year - profile.dateOfBirth.year;
    if (now.month < profile.dateOfBirth.month ||
        (now.month == profile.dateOfBirth.month &&
            now.day < profile.dateOfBirth.day)) {
      age--;
    }
    if (age > 0 && age < 120) _ageController.text = age.toString();
    _gender = _genderOptions.contains(profile.gender) ? profile.gender : null;
    _profileType = profile.profileType;
    _avatarId = profile.avatarUrl.startsWith(ProfileAvatar.avatarIconPrefix)
        ? profile.avatarUrl.substring(ProfileAvatar.avatarIconPrefix.length)
        : '';
    _favoriteGenres
      ..clear()
      ..addAll(profile.favoriteGenres);
  }

  int? _computedAge() {
    final parsed = int.tryParse(_ageController.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed > 120 ? 120 : parsed;
  }

  /// Enregistre le profil [loaded]. Partagé entre l'activation au D-pad
  /// ([TvFocus.onActivate]) et le tap tactile ([FilledButton.onPressed]).
  Future<void> _save(UserProfile loaded) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate() ||
        _gender == null ||
        _profileType == null ||
        _favoriteGenres.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un genre favori'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    final result = await safeAsync<void>(
      () async {
        final age = _computedAge()!;
        final dob = loaded.dateOfBirth;
        final now = DateTime.now();
        final updatedDob = DateTime(
          now.year - age,
          dob.month.clamp(1, 12),
          dob.day.clamp(
            1,
            DateTime(
              now.year - age,
              dob.month.clamp(1, 12) + 1,
              0,
            ).day,
          ),
        );
        final updated = loaded.copyWith(
          firstName: _nameController.text.trim(),
          dateOfBirth: updatedDob,
          gender: _gender!,
          profileType: _profileType!,
          favoriteGenres: _favoriteGenres,
          avatarUrl: _avatarId.isEmpty
              ? ''
              : '${ProfileAvatar.avatarIconPrefix}$_avatarId',
          updatedAt: DateTime.now(),
        );
        await ref.read(storageServiceProvider).saveProfile(updated);
        // Écriture disque, donc suspension possible.
        // Trois lectures de `ref` suivaient, la garde
        // `context.mounted` n'arrivait qu'après, à la ligne du `context.pop()`.
        if (!mounted) return;
        final current = ref.read(currentProfileProvider);
        if (current?.id == updated.id) {
          ref.read(currentProfileProvider.notifier).setUserProfile(updated);
        }
        ref.invalidate(profilesProvider);
        if (!mounted) return;
        context.pop();
      },
      context: 'ProfileEditScreen.saveProfile',
    );
    if (result.isFailure) {
      // `context.mounted` protège le SnackBar, mais le `setState` juste après
      // ne l'était pas : sur erreur d'écriture, l'utilisateur a souvent déjà
      // quitté l'écran.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorSaving)),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(profilesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await onWillPop();
        if (canPop && context.mounted) {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: context.canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Retour',
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(l.myProfile),
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(l.errorGeneric(err))),
          data: (profiles) {
            final targetId =
                widget.profileId ?? ref.watch(currentProfileProvider)?.id;
            UserProfile? target;
            for (final p in profiles) {
              if (p.id == targetId) {
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
                    TvFocus(
                      autofocus: true,
                      onActivate: () => context.go('/profiles'),
                      child: FilledButton(
                        onPressed: () => context.go('/profiles'),
                        child: Text(l.chooseProfile),
                      ),
                    ),
                  ],
                ),
              );
            }
            _fillFromProfile(target);
            final loaded = target;

            final age = _computedAge();
            final isAdult = age != null && age >= 18;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SettingsSectionTitle('Avatar & Identité'),
                  AppCard(
                    child: Column(
                      children: [
                        ProfileAvatarSelector(
                          avatars: const [],
                          selectedAvatarId: _avatarId,
                          onAvatarSelected: (avatar) => setState(
                            () => _avatarId =
                                _avatarId == avatar.id ? '' : avatar.id,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 20),
                        Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                (event.logicalKey == LogicalKeyboardKey.enter ||
                                    event.logicalKey == LogicalKeyboardKey.select ||
                                    event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                              _ageFocus.requestFocus();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            maxLength: AppConstants.maxNameLength,
                            decoration: InputDecoration(
                              labelText: l.nameOrNickname,
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () => _ageFocus.requestFocus(),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Obligatoire'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          focusNode: _ageFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: InputDecoration(
                            labelText: l.age,
                            prefixIcon: const Icon(Icons.cake_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: Icon(
                              isAdult
                                  ? Icons.verified_user
                                  : Icons.no_adult_content,
                              color: isAdult ? scheme.tertiary : scheme.error,
                            ),
                          ),
                          validator: (v) {
                            final parsed = int.tryParse(v?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Âge obligatoire';
                            }
                            if (parsed > 120) return 'Âge invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdult
                                    ? Icons.verified_user
                                    : Icons.no_adult_content,
                                size: 16,
                                color: isAdult ? scheme.tertiary : scheme.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAdult
                                    ? 'Profil adulte vérifié'
                                    : 'Sous contrôle parental',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isAdult
                                          ? scheme.tertiary
                                          : scheme.error,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionTitle('Genre'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.transgender),
                      ),
                      items: _genderOptions
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),)
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v),
                      validator: (v) => v == null ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionTitle('Type de profil'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: DropdownButtonFormField<ProfileType>(
                      initialValue: _profileType,
                      decoration: const InputDecoration(
                        labelText: 'Type de profil',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: ProfileType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_profileTypeToString(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _profileType = v),
                      validator: (v) => v == null ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionTitle('Genres favoris'),
                  AppCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allGenres.map((genre) {
                        final selected = _favoriteGenres.contains(genre);
                        return FilterChip(
                          label: Text(genre),
                          selected: selected,
                          showCheckmark: true,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _favoriteGenres.add(genre);
                              } else {
                                _favoriteGenres.remove(genre);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: TvFocus(
                      autofocus: true,
                      onActivate: _saving ? null : () => _save(loaded),
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(loaded),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Enregistrer'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
