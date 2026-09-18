import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/navigation/route_meta.dart';
import 'package:orbit_3d_flutter/core/navigation/with_back_handling.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Sprint 2 — Sélecteur de profil :
/// grille de cartes navigable au d-pad (Focus system), avatar généré
/// (initiale + anneau orbital), animation d'entrée en cascade, et carte
/// "+" vers la création de profil (finalisée en S3).
class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  static const int _defaultMaxProfiles = 5;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _selectProfile(UserProfile profile) async {
    // Enfant/Expert protégé par PIN : vérification avant de continuer.
    if ((profile.isChild || profile.isExpert) && profile.hasPin) {
      ref.read(currentProfileProvider.notifier).setUserProfile(profile);
      final ok = await context.push<bool>(
        '/profile/pin',
        extra: PinPadArgs.verify(profile),
      );
      if (!mounted) return;
      if (ok != true) {
        ref.read(currentProfileProvider.notifier).setUserProfile(null);
        ref.read(profileTypeProvider.notifier).clear();
        return;
      }
    }
    await _finishSelect(profile);
  }

  Future<void> _finishSelect(UserProfile profile) async {
    final refreshed = profile.copyWith(lastActiveAt: DateTime.now());
    ref.read(currentProfileProvider.notifier).setUserProfile(refreshed);
    ref.read(profileTypeProvider.notifier).loadFromProfile(refreshed);
    final storage = ref.read(storageServiceProvider);
    await storage.saveProfile(refreshed);
    await storage.setSetting('last_profile_id', profile.id);
    ref.invalidate(profilesProvider);
    if (!mounted) return;
    
    // Small delay to ensure profile state is propagated before navigation
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    
    // `go` (et non pushReplacement) : réinitialise proprement la pile vers le
    // shell. `pushReplacement` provoque un « pop » de la route courante que le
    // PopScope(canPop:false) de WithBackHandling peut bloquer → écran gris.
    context.go('/home');
  }

  void _openCreate(int current, int max) {
    if (current >= max) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.maxProfilesReached(max)),
        ),
      );
      return;
    }
    context.push('/profile/create');
  }

  void _openEdit(UserProfile profile) {
    context.push('/profile/edit/${profile.id}');
  }

  void _openDelete(UserProfile profile) {
    final l = AppLocalizations.of(context);
    final profiles = ref.read(profilesProvider).value ?? const [];
    if (profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins un profil doit rester sur l\'appareil'),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteProfileConfirm),
        content: Text(
          '« ${profile.firstName} » et ses préférences seront supprimés '
          'définitivement. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final storage = ref.read(storageServiceProvider);
              await storage.deleteProfile(profile.id);
              if (profile.id ==
                  ref
                      .read(storageServiceProvider)
                      .getSetting('last_profile_id')) {
                await storage.setSetting('last_profile_id', null);
              }
              final current = ref.read(currentProfileProvider);
              if (current?.id == profile.id) {
                ref.read(currentProfileProvider.notifier).setUserProfile(null);
                ref.read(profileTypeProvider.notifier).clear();
              }
              ref.invalidate(profilesProvider);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  int _maxFor(List<UserProfile> profiles) {
    return profiles.isEmpty
        ? _defaultMaxProfiles
        : profiles.first.maxProfilesAllowed;
  }

  Widget _buildHeader(int current, int max) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 4),
          if (context.canPop()) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
              tooltip: 'Retour',
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qui regarde ?',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez un profil pour continuer',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ProfilesCountBadge(current: current, max: max),
        ],
      ),
    );
  }

  Widget _buildProfileGrid(List<UserProfile> profiles, int maxProfiles) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      scrollDirection: Axis.horizontal,
      itemCount: profiles.length + 1,
      itemBuilder: (context, index) {
        final isAddCard = index == profiles.length;
        if (isAddCard) {
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: SizedBox(
              width: 170,
              child: _AddProfileCard(
                index: index,
                autofocus: false,
                onTap: () => _openCreate(profiles.length, maxProfiles),
              ),
            ),
          );
        }
        final profile = profiles[index];
        return Padding(
          padding: const EdgeInsets.only(right: 18),
          child: SizedBox(
            width: 340,
            child: _ProfileCard(
              profile: profile,
              index: index,
              autofocus: index == 0,
              onSelect: () => _selectProfile(profile),
              onEdit: () => _openEdit(profile),
              onDelete: () => _openDelete(profile),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              icon: Icons.manage_accounts_rounded,
              title: l.noProfilesYet,
              message: 'Créez votre premier profil pour commencer à regarder.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240,
              height: 180,
              child: _AddProfileCard(
                index: 0,
                autofocus: true,
                onTap: () => _openCreate(0, _defaultMaxProfiles),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 6),
      child: Text(
        'Flèches + OK pour naviguer · Touchez une carte pour sélectionner',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profilesAsync = ref.watch(profilesProvider);
    return WithBackHandling(
      meta: const RouteMeta.popOrFallback('/home'),
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const HomeMenuDrawer(),
        appBar: AppBar(
          leading: GoRouter.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Retour',
                  onPressed: () => GoRouter.of(context).pop(),
                )
              : null,
          title: Text(l.whoIsWatching),
          actions: [
            _ProfileSwitchButton(profile: ref.watch(currentProfileProvider)),
          ],
        ),
        body: SafeArea(
          child: profilesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyState(
              icon: Icons.cloud_off_rounded,
              title: l.failedToLoadProfiles,
              message: '$error',
              action: FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l.retry),
                onPressed: () => ref.invalidate(profilesProvider),
              ),
            ),
            data: (profiles) {
              final maxProfiles = _maxFor(profiles);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(profiles.length, maxProfiles),
                  Expanded(
                    child: profiles.isEmpty
                        ? _buildEmptyState()
                        : _buildProfileGrid(profiles, maxProfiles),
                  ),
                  _buildFooter(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard({
    required this.profile,
    required this.index,
    required this.autofocus,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final UserProfile profile;
  final int index;
  final bool autofocus;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
    );
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 600));
    Future<void>.delayed(delay, () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _activate() {
    HapticFeedback.heavyImpact();
    widget.onSelect();
  }

  String get _profileTypeLabel => switch (widget.profile.profileType) {
        ProfileType.adult => 'adulte',
        ProfileType.child => 'enfant',
        ProfileType.expert => 'expert',
      };

  String get _lastActiveLabel {
    final at = widget.profile.lastActiveAt;
    if (at == null) return 'Nouveau profil';
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (now.day == at.day &&
        DateTime(now.year, now.month, now.day) ==
            DateTime(at.year, at.month, at.day)) {
      return 'aujourd\'hui';
    }
    if (diff.inHours < 48) return 'hier';
    return DateFormat('d MMM', 'fr_FR').format(at);
  }

  Widget _buildCardContent() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.profile;
    final currentProfile = ref.watch(currentProfileProvider);
    final isActive = currentProfile?.id == profile.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: _focused
              ? scheme.tertiary
              : isActive
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
          width: _focused
              ? 2.5
              : isActive
                  ? 2
                  : 1,
        ),
        boxShadow: [
          if (_focused)
            BoxShadow(
              color: scheme.tertiary.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            )
          else if (isActive)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.5),
              blurRadius: 28,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Stack(
        children: [
          Row(
            children: [
              // Avatar (gauche)
              Semantics(
                button: true,
                label: 'Modifier le profil ${profile.firstName}',
                onTap: widget.onEdit,
                child: GestureDetector(
                  onTap: widget.onEdit,
                  child: OrbitAvatar(
                    profile: profile,
                    enlarged: _focused || isActive,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Informations (droite)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isActive ? scheme.primary : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ProfileTypeBadge(profileType: profile.profileType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            profile.hasPin
                                ? Icons.lock_outline_rounded
                                : Icons.history_rounded,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              profile.hasPin
                                  ? 'Protégé par ${profile.profileType == ProfileType.child ? 'code enfant' : 'code'}'
                                  : 'Dernière activité : $_lastActiveLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Actions (bord droit)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CardActionButton(
                    icon: Icons.edit_rounded,
                    tooltip: 'Modifier',
                    onPressed: widget.onEdit,
                  ),
                  const SizedBox(height: 8),
                  _CardActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Supprimer',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
          if (isActive)
            const Positioned(
              top: -8,
              left: -8,
              child: _ActiveBadge(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(currentProfileProvider)?.id == widget.profile.id;
    return Semantics(
      container: true,
      label: 'Profil ${widget.profile.firstName} ($_profileTypeLabel)'
          '${isActive ? ', actif' : ''}',
      child: Focus(
        autofocus: widget.autofocus,
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
          child: AnimatedScale(
            scale: _focused ? 1.06 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: _buildCardContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatefulWidget {
  const _AddProfileCard({
    required this.index,
    required this.autofocus,
    required this.onTap,
  });

  final int index;
  final bool autofocus;
  final VoidCallback onTap;

  @override
  State<_AddProfileCard> createState() => _AddProfileCardState();
}

class _AddProfileCardState extends State<_AddProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
    );
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 600));
    Future<void>.delayed(delay, () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _activate() {
    HapticFeedback.heavyImpact();
    widget.onTap();
  }

  Widget _buildCardContent() {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final borderColor =
        _focused ? scheme.primary : scheme.primary.withValues(alpha: 0.45);
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: borderColor,
        radius: AppConstants.radiusLg,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color:
              scheme.primaryContainer.withValues(alpha: _focused ? 0.35 : 0.18),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            if (_focused)
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _focused ? 58 : 52,
              height: _focused ? 58 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.tertiary],
                ),
              ),
              child: Icon(
                Icons.add,
                size: 30,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ajouter un profil',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l.createNewProfile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.createNewProfile,
      onTap: widget.onTap,
      child: Focus(
        autofocus: widget.autofocus,
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
          child: AnimatedScale(
            scale: _focused ? 1.04 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: _buildCardContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge « Actif » positionné dans l'angle de la carte profil sélectionnée.
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Actif',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action sur la carte profil (Modifier / Supprimer), focalisable au d-pad.
class _CardActionButton extends StatefulWidget {
  const _CardActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_CardActionButton> createState() => _CardActionButtonState();
}

class _CardActionButtonState extends State<_CardActionButton> {
  bool _focused = false;

  void _activate() {
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.tooltip,
      onTap: _activate,
      child: Focus(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _focused
                  ? scheme.tertiaryContainer
                  : scheme.surfaceContainerHighest,
              border: Border.all(
                color: _focused ? scheme.tertiary : scheme.outlineVariant,
                width: _focused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _focused ? 0.35 : 0.18),
                  blurRadius: _focused ? 10 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 21,
              color: _focused
                  ? scheme.onTertiaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordure en pointillés (carte « Ajouter un profil »).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final iterator = path.computeMetrics().iterator;
    while (iterator.moveNext()) {
      final metric = iterator.current;
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _ProfileSwitchButton extends StatelessWidget {
  const _ProfileSwitchButton({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget avatar;
    if (profile == null) {
      avatar = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(
          Icons.person_outline,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
      );
    } else {
      avatar = ProfileAvatar(profile: profile!, size: 34);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 10),
      child: Tooltip(
        message: profile == null ? 'Choisir un profil' : 'Changer de profil',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/profiles'),
          child: avatar,
        ),
      ),
    );
  }
}
