import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/navigation/form_back_handler.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/features/auth/widgets/profile_avatar_selector.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

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

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.profileId});

  final String? profileId;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> with FormBackHandler {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  String _avatarId = '';
  final List<String> _favoriteGenres = [];
  bool _saving = false;
  String? _loadedProfileId;
  // Visibilité / Enregistrement
  bool _profileVisible = true;
  bool _allowRecording = true;

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
           _avatarId.isNotEmpty ||
           _favoriteGenres.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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
    _avatarId = profile.avatarUrl.startsWith(ProfileAvatar.avatarIconPrefix)
        ? profile.avatarUrl.substring(ProfileAvatar.avatarIconPrefix.length)
        : '';
    _favoriteGenres
      ..clear()
      ..addAll(profile.favoriteGenres);
    // Visibilité / Enregistrement - valeurs par défaut (à étendre si stockées)
    _profileVisible = true;
    _allowRecording = true;
  }

  int? _computedAge() {
    final parsed = int.tryParse(_ageController.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed > 120 ? 120 : parsed;
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(title: const Text('Mon profil')),
        body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
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
                  FilledButton(
                    onPressed: () => context.go('/profiles'),
                    child: const Text('Choisir un profil'),
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
                        avatars: profileAvatarOptions
                            .map(
                              (a) => AvatarItem(
                                id: a.id,
                                name: a.id,
                                category: 'Par défaut',
                                assetPath: '',
                                icon: a.icon,
                                color: a.color,
                              ),
                            )
                            .toList(),
                        selectedAvatarId: _avatarId,
                        onAvatarSelected: (avatar) => setState(
                          () => _avatarId =
                              _avatarId == avatar.id ? '' : avatar.id,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        maxLength: AppConstants.maxNameLength,
                        decoration: const InputDecoration(
                          labelText: 'Nom / Pseudo',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Âge',
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
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
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
                const SizedBox(height: 16),
                // Visibilité / Enregistrement
                const SettingsSectionTitle('Visibilité & Enregistrement'),
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.visibility_outlined),
                        title: const Text('Profil visible'),
                        subtitle: const Text(
                            'Apparaître dans les recherches et recommandations'),
                        value: _profileVisible,
                        onChanged: (v) => setState(() => _profileVisible = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.video_camera_back_outlined),
                        title: const Text('Autoriser l\'enregistrement'),
                        subtitle: const Text(
                            'Permettre l\'enregistrement de mes contenus favoris'),
                        value: _allowRecording,
                        onChanged: (v) => setState(() => _allowRecording = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate() ||
                              _gender == null ||
                              _favoriteGenres.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Sélectionnez au moins un genre favori'),
                              ),
                            );
                            return;
                          }
                          setState(() => _saving = true);
                          try {
                            final age = _computedAge()!;
                            final dob = loaded.dateOfBirth;
                            final now = DateTime.now();
                            final updatedDob = DateTime(
                              now.year - age,
                              dob.month.clamp(1, 12),
                              dob.day.clamp(
                                1,
                                DateTime(now.year - age,
                                        dob.month.clamp(1, 12) + 1, 0)
                                    .day,
                              ),
                            );
                            final updated = UserProfile(
                              id: loaded.id,
                              firstName: _nameController.text.trim(),
                              dateOfBirth: updatedDob,
                              gender: _gender!,
                              favoriteGenres: _favoriteGenres,
                              avatarUrl: _avatarId.isEmpty
                                  ? ''
                                  : '${ProfileAvatar.avatarIconPrefix}$_avatarId',
                            );
                            await ref
                                .read(storageServiceProvider)
                                .saveProfile(updated);
                            final current = ref.read(currentProfileProvider);
                            if (current?.id == updated.id) {
                              ref.read(currentProfileProvider.notifier).state =
                                  updated;
                            }
                            ref.invalidate(profilesProvider);
                            if (context.mounted) context.pop();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur lors de la sauvegarde'),
                                ),
                              );
                            }
                            setState(() => _saving = false);
                          }
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
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
