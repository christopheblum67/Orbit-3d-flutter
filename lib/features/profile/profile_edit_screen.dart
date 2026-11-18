import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_picker_grid.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/dpad_scope.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/profile_pin.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Sprint 3 — Création / Édition de profil :
/// - nom (formatté), type Adulte/Enfant/Expert,
/// - avatar DiceBear par catégorie,
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
  final _scrollController = ScrollController();
  late final FocusNode _nameFocus;
  final _firstAgeFocus = FocusNode(debugLabel: 'profile.firstAge');
  final _saveFocus = FocusNode(debugLabel: 'profile.save');
  final _identityCardKey = GlobalKey();
  ProfileType _type = ProfileType.adult;
  String _selectedDiceBearCategory = 'characters';
  String? _remoteAvatarUrl;
  String? _pinHash;
  DateTime? _dateOfBirth;
  String _gender = 'Non spécifié';
  final List<String> _favoriteGenres = [];
  bool _saving = false;
  bool _hashingPin = false;
  bool _submitted = false;
  UserProfile? _loadedTarget;

  /// Valeurs initiales du formulaire (pour la détection de modifications).
  String _baseName = '';
  ProfileType _baseType = ProfileType.adult;
  String _baseSelectedDiceBearCategory = 'characters';
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
        _selectedDiceBearCategory != _baseSelectedDiceBearCategory ||
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
    final l = AppLocalizations.of(context);
    final cancelFocus = FocusNode();
    final confirmFocus = FocusNode();

    void requestFocus(FocusNode focus) {
      if (mounted) {
        FocusScope.of(context).requestFocus(focus);
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.exitWithoutSaving),
        content: const Text(
          'Des modifications non sauvegardées seront perdues. Quitter quand même ?',
        ),
        actions: [
          Focus(
            focusNode: cancelFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.of(dialogContext).pop(false);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(confirmFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
          ),
          Focus(
            focusNode: confirmFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.of(dialogContext).pop(true);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(cancelFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Quitter'),
            ),
          ),
        ],
      ),
    );
    cancelFocus.dispose();
    confirmFocus.dispose();
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

  bool _nameEditing = false;

  bool get _dpadMode => ref.read(tvModeNotifierProvider).enabled;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode(
      debugLabel: 'profile.name',
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final isSelect = key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.gameButtonA;
        // Au D-pad, le champ reste en lecture seule tant que l'utilisateur n'a
        // pas validé dessus : sinon le clavier à l'écran s'ouvre dès l'arrivée
        // du focus et capte les flèches, ce qui bloque l'accès aux avatars.
        if (_dpadMode && !_nameEditing && isSelect) {
          setState(() => _nameEditing = true);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp && (_dpadMode || !_nameEditing)) {
          if (node.focusInDirection(TraversalDirection.up)) {
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        if (key == LogicalKeyboardKey.arrowDown || isSelect) {
          setState(() => _nameEditing = false);
          _scrollToNextSection();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    )..addListener(() {
        if (!_nameFocus.hasFocus && _nameEditing && mounted) {
          setState(() => _nameEditing = false);
        }
      });
  }

  void _scrollToNextSection() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _submitted = true);
      _nameFocus.requestFocus();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients || !mounted) return;
      final cardContext = _identityCardKey.currentContext;
      final renderObject = cardContext?.findRenderObject();
      if (renderObject is! RenderBox) return;
      final cardBottom =
          renderObject.localToGlobal(Offset(0, renderObject.size.height)).dy;
      final targetOffset = (_scrollController.offset + cardBottom - 100)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      if (mounted) _firstAgeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    _nameFocus.dispose();
    _firstAgeFocus.dispose();
    _saveFocus.dispose();
    super.dispose();
  }

  void _fillFromProfile(UserProfile profile) {
    if (_loadedTarget?.id == profile.id) return;
    _loadedTarget = profile;
    _nameController.text = profile.firstName;
    _type = profile.profileType;
    _dateOfBirth = profile.dateOfBirth;
    // Genre : défaut sur la première option valide (comme le type de profil)
    const validGenders = ['Homme', 'Femme', 'Autre'];
    _gender = validGenders.contains(profile.gender)
        ? profile.gender
        : validGenders.first;
    _favoriteGenres
      ..clear()
      ..addAll(profile.favoriteGenres);
    final raw = profile.avatarUrl.trim();
    _remoteAvatarUrl = raw.isNotEmpty &&
            !raw.startsWith(ProfileAvatar.legacyOrbitGradientPrefix)
        ? raw
        : null;
    final selectedAvatar = orbit3DAvatars.where(
      (avatar) => avatar.imageUrl == _remoteAvatarUrl,
    );
    if (selectedAvatar.isNotEmpty) {
      _selectedDiceBearCategory = selectedAvatar.first.category;
    }
    _pinHash = profile.hasPin ? profile.pinHash : null;
    _captureBaseline();
  }

  void _captureBaseline() {
    _baseName = _nameController.text.trim();
    _baseType = _type;
    _baseSelectedDiceBearCategory = _selectedDiceBearCategory;
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
      avatarUrl: _remoteAvatarUrl ?? '',
    );
  }

  Future<void> _openPinPad() async {
    if (_hashingPin || _saving) return;
    final pin = await context.push<String>(
      '/profile/pin',
      extra: const PinPadArgs.set(),
    );
    if (pin == null || !mounted) return;
    final confirmation = await context.push<String>(
      '/profile/pin',
      extra: const PinPadArgs.set(confirmation: true),
    );
    if (confirmation == null || !mounted) return;
    if (pin != confirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les codes PIN ne correspondent pas.')),
      );
      return;
    }
    setState(() => _hashingPin = true);
    try {
      final hash = await ProfilePin.create(pin);
      if (mounted) {
        setState(() => _pinHash = hash);
      }
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('création du code PIN de profil'),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de créer le code PIN.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _hashingPin = false);
      }
    }
  }

  Future<void> _onPinSwitch(bool enable) async {
    if (_hashingPin || _saving) return;
    if (enable) {
      await _openPinPad();
    } else {
      setState(() => _pinHash = null);
    }
  }

  Future<void> _save() async {
    if (_hashingPin || _saving) return;
    final l = AppLocalizations.of(context);
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      _nameFocus.requestFocus();
      final focusContext = _nameFocus.context;
      if (focusContext != null) Scrollable.ensureVisible(focusContext);
      return;
    }
    setState(() => _saving = true);
    final result = await safeAsync(
      () async {
        final name = _nameController.text.trim();
        final avatarUrl = _remoteAvatarUrl ?? '';
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
            gender: _gender,
            favoriteGenres: List.of(_favoriteGenres),
            pinHash: _pinHash,
            clearPin: _pinHash == null,
            updatedAt: now,
          );
          await ref.read(storageServiceProvider).saveProfile(updated);
          // Écriture disque : la garde arrive ligne 369, soit APRÈS les trois
          // lectures de `ref` qui suivent. Sur TV, quitter avec la télécommande
          // pendant l'écriture suffisait à le déclencher.
          if (!mounted) return;
          final current = ref.read(currentProfileProvider);
          if (current?.id == updated.id) {
            ref.read(currentProfileProvider.notifier).setUserProfile(updated);
            ref.read(profileTypeProvider.notifier).loadFromProfile(updated);
          }
          ref.invalidate(profilesProvider);
          context.pop();
          return;
        }

        final profiles =
            ref.read(profilesProvider).value ?? const <UserProfile>[];
        final maxAllowed =
            profiles.isEmpty ? 5 : profiles.first.maxProfilesAllowed;
        if (profiles.length >= maxAllowed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.maxProfilesReached(maxAllowed)),
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
          gender: _gender,
          favoriteGenres: List.of(_favoriteGenres),
          avatarUrl: avatarUrl,
          profileType: _type,
          pinHash: _pinHash,
          maxProfilesAllowed: maxAllowed,
        );
        await ref.read(storageServiceProvider).saveProfile(profile);
        if (!mounted) return;
        ref.invalidate(profilesProvider);
        context.pop();
      },
      context: '_save profile',
    );

    if (result.isFailure && mounted) {
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
    // `showPin` vit dans `_buildBody` : c'est là que la section PIN est
    // insérée. Il existait aussi ici, en doublon, sans être lu — l'avertissement
    // d'analyse signalait cette copie morte, pas une fonctionnalité manquante.

    if (!_isEdit) return _scaffold(_buildBody());

    return _scaffold(
      ref.watch(profilesProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(l.errorGeneric(err))),
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
                        child: Text(l.chooseProfile),
                      ),
                    ],
                  ),
                );
              }
              _fillFromProfile(target);
              return _buildBody();
            },
          ),
    );
  }

  Widget _buildBody() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 16),
        _buildAvatarPickerCard(),
        const SizedBox(height: 8),
        _buildIdentityCard(),
        const SizedBox(height: 16),
        _buildPersonalAndTypeCard(),
        const SizedBox(height: 16),
        _buildPinSection(),
        const SizedBox(height: 8),
        _buildActions(),
      ],
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
            child: DpadScope(child: Form(key: _formKey, child: body)),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avatar = ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (context, value, _) => ProfileAvatar(
              profile: _avatarPreviewProfile(),
              size: 104,
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thème d\'avatar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Choisissez un style, puis un avatar dans la grille',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              _buildThemeSelector(),
            ],
          );
          if (constraints.maxWidth < 480) {
            return Column(children: [
              avatar,
              const SizedBox(height: 16),
              details,
            ]);
          }
          return Row(children: [
            avatar,
            const SizedBox(width: 20),
            Expanded(child: details),
          ]);
        },
      ),
    );
  }

  Widget _buildAvatarPickerCard() {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
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
            'Thème actuel : ${avatarCategoryLabel(l, _selectedDiceBearCategory)}',
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
            categoryId: _selectedDiceBearCategory,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in avatarCategoryIds.skip(1))
          _ProfileChoiceChip(
            label: avatarCategoryLabel(l, category),
            selected: _selectedDiceBearCategory == category,
            onTap: () => setState(() {
              _selectedDiceBearCategory = category;
            }),
          ),
      ],
    );
  }

  Widget _buildIdentityCard() {
    final l = AppLocalizations.of(context);
    final wideLayout = MediaQuery.sizeOf(context).width >= 900;
    return AppCard(
      key: _identityCardKey,
      color: Colors.transparent,
      child: Column(
        children: [
          ListenableBuilder(
            listenable: ref.read(tvModeNotifierProvider),
            builder: (context, _) => TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              maxLength: AppConstants.maxNameLength,
              autofocus: !_isEdit && !wideLayout,
              readOnly: _dpadMode && !_nameEditing,
              onTap: () {
                if (!_nameEditing) setState(() => _nameEditing = true);
              },
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp("[a-zA-Z\\u00C0-\\u017F' -]"),
                ),
                LengthLimitingTextInputFormatter(AppConstants.maxNameLength),
              ],
              decoration: InputDecoration(
                labelText: l.nameOrNickname,
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
                errorText: _submitted && _nameController.text.trim().isEmpty
                    ? 'Obligatoire'
                    : null,
              ),
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
              onEditingComplete: () {
                setState(() => _nameEditing = false);
                _scrollToNextSection();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalAndTypeCard({Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      key: key,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  focusNode:
                      genre == _genreOptions.first ? _firstAgeFocus : null,
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

  Widget _buildPinSection() {
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        children: [
          SettingsSwitchTile(
            icon: Icons.pin_outlined,
            title: l.protectWithPin,
            subtitle: _pinHash != null
                ? (_pinHash == _basePinHash
                    ? 'Un code PIN de 4 chiffres est actif'
                    : 'Code PIN confirmé. Enregistrez le profil pour l’activer.')
                : 'Demander un code PIN à la sélection du profil',
            value: _pinHash != null,
            onChanged: _onPinSwitch,
          ),
          if (_pinHash != null)
            SettingsActionTile(
              icon: Icons.pin,
              title: l.changePinCode,
              subtitle: l.enterNew4DigitPin,
              onTap: _openPinPad,
            ),
          if (_hashingPin)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Création du code PIN…'),
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
              onPressed: _saving || _hashingPin ? null : handleBack,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton.icon(
              focusNode: _saveFocus,
              onPressed: _saving || _hashingPin ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _pinHash != null && _pinHash != _basePinHash
                    ? _isEdit
                        ? 'Enregistrer et activer la protection'
                        : 'Créer le profil et activer la protection'
                    : _isEdit
                        ? 'Enregistrer'
                        : 'Créer le profil',
              ),
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
    this.focusNode,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;

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
      focusNode: widget.focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) HapticFeedback.selectionClick();
        setState(() => _focused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                event.logicalKey == LogicalKeyboardKey.space)) {
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
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: highlighted
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
