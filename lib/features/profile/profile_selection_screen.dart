import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/navigation/route_meta.dart';
import 'package:orbit_3d_flutter/core/navigation/with_back_handling.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Sprint 2 — Sélecteur de profil :
/// grille de cartes navigable au d-pad (Focus system), avatar généré
/// (initiale ou image), animation d'entrée en cascade, et carte
/// "+" vers la création de profil (finalisée en S3).
class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key, this.startupFlow = false});

  final bool startupFlow;

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  static const int _defaultMaxProfiles = 5;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, FocusNode> _profileFocusNodes = {};
  final FocusNode _addProfileNode = FocusNode(debugLabel: 'Add profile');
  bool _authorizing = false;

  @override
  void dispose() {
    for (final node in _profileFocusNodes.values) {
      node.dispose();
    }
    _addProfileNode.dispose();
    super.dispose();
  }

  void _focusProfile(FocusNode node) {
    node.requestFocus();
    final target = node.context;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 180),
        alignment: 0.5,
      );
    }
  }

  Future<void> _selectProfile(UserProfile profile) async {
    if (!await _authorize(profile) || !mounted) return;
    await _finishSelect(profile);
  }

  Future<bool> _authorize(UserProfile profile) async {
    if (_authorizing) return false;
    if (!profile.hasPin) return true;
    _authorizing = true;
    try {
      return await context.push<bool>(
            '/profile/pin',
            extra: PinPadArgs.verify(profile),
          ) ==
          true;
    } finally {
      _authorizing = false;
    }
  }

  Future<void> _finishSelect(UserProfile profile) async {
    final refreshed = profile.copyWith(lastActiveAt: DateTime.now());
    ref.read(currentProfileProvider.notifier).setUserProfile(refreshed);
    ref.read(profileTypeProvider.notifier).loadFromProfile(refreshed);
    final storage = ref.read(storageServiceProvider);
    await storage.saveProfile(refreshed);
    await storage.setSetting('last_profile_id', profile.id);
    // Deux écritures disque : l'utilisateur a pu revenir en arrière entre-temps.
    // `ref.invalidate` était appelé une ligne AVANT la garde.
    if (!mounted) return;
    ref.invalidate(profilesProvider);

    // Small delay to ensure profile state is propagated before navigation
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    if (widget.startupFlow) {
      context.go('/startup?phase=remaining');
      return;
    } else {
      // Refresh validity for normal profile switches outside the startup flow.
      final activeSub = ref.read(activeSubscriptionProvider);
      if (activeSub != null && activeSub.type == SubscriptionType.xtream) {
        final api = ref.read(apiServiceProvider);
        if (!mounted) return;
        await ref.read(subscriptionsProvider.notifier).refreshValidity(
              activeSub.id,
              api: api,
            );
        if (!mounted) return;
      }
    }

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

  Future<void> _openEdit(UserProfile profile) async {
    if (!await _authorize(profile) || !mounted) return;
    await context.push('/profile/edit/${profile.id}');
  }

  Future<void> _openDelete(UserProfile profile) async {
    final l = AppLocalizations.of(context);
    final profiles = ref.read(profilesProvider).value ?? const [];
    if (profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.profileMustKeepOne),
        ),
      );
      return;
    }
    if (!await _authorize(profile) || !mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteProfileConfirm),
        content: Text(
          l.profileDeleteBody(profile.firstName),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
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
            child: Text(l.profileDelete),
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
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tvMode = ref.watch(tvModeNotifierProvider);
    Widget menuButton() => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        );
    return ListenableBuilder(
      listenable: tvMode,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Stack(
          children: [
            Row(
              children: [
                if (!tvMode.enabled) ...[
                  menuButton(),
                  const SizedBox(width: 4),
                ],
                if (context.canPop()) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                    tooltip: l.profileBack,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    l.profileSelectToContinue,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ProfilesCountBadge(current: current, max: max),
              ],
            ),
            if (tvMode.enabled)
              Positioned(
                left: 0,
                top: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0,
                    alwaysIncludeSemantics: true,
                    child: menuButton(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileGrid(List<UserProfile> profiles, int maxProfiles) {
    final currentProfile = ref.watch(currentProfileProvider);
    final activeProfileIndex =
        profiles.indexWhere((profile) => profile.id == currentProfile?.id);
    final nodes = [
      for (final profile in profiles)
        _profileFocusNodes.putIfAbsent(
          profile.id,
          () => FocusNode(debugLabel: 'Profile card'),
        ),
      _addProfileNode,
    ];
    return Center(
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length + 1,
        itemBuilder: (context, index) {
          final isAddCard = index == profiles.length;
          if (isAddCard) {
            return Padding(
              padding: const EdgeInsets.only(right: 28),
              child: SizedBox(
                width: 150,
                child: _AddProfileCard(
                  index: index,
                  autofocus: false,
                  focusNode: _addProfileNode,
                  onMoveLeft:
                      index > 0 ? () => _focusProfile(nodes[index - 1]) : null,
                  onTap: () => _openCreate(profiles.length, maxProfiles),
                ),
              ),
            );
          }
          final profile = profiles[index];
          return Padding(
            padding: const EdgeInsets.only(right: 28),
            child: SizedBox(
              width: 150,
              child: _ProfileCard(
                key: ValueKey(profile.id),
                profile: profile,
                index: index,
                autofocus:
                    index == (activeProfileIndex >= 0 ? activeProfileIndex : 0),
                focusNode: nodes[index],
                onMoveLeft:
                    index > 0 ? () => _focusProfile(nodes[index - 1]) : null,
                onMoveRight: () => _focusProfile(nodes[index + 1]),
                onSelect: () => _selectProfile(profile),
                onEdit: () => _openEdit(profile),
                onDelete: () => _openDelete(profile),
              ),
            ),
          );
        },
      ),
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
              message: l.profileCreateToWatch,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              height: 200,
              child: _AddProfileCard(
                index: 0,
                autofocus: true,
                focusNode: _addProfileNode,
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
        AppLocalizations.of(context).profileNavigationHelp,
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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.contextMenu): () {
          final scaffold = _scaffoldKey.currentState;
          if (scaffold == null) return;
          if (scaffold.isEndDrawerOpen) {
            scaffold.closeEndDrawer();
          } else {
            scaffold.openEndDrawer();
          }
        },
      },
      child: WithBackHandling(
        meta: const RouteMeta.popOrFallback('/home'),
        child: Scaffold(
          key: _scaffoldKey,
          endDrawer: const HomeMenuDrawer(),
          appBar: AppBar(
            leading: GoRouter.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: l.profileBack,
                    onPressed: () => GoRouter.of(context).pop(),
                  )
                : null,
            title: const SizedBox.shrink(),
            actions: [
              _ProfileSwitchButton(profile: ref.watch(currentProfileProvider)),
            ],
          ),
          body: SafeArea(
            child: profilesAsync.when(
              loading: () =>
                  const Center(child: OrbitDelayedLoadingIndicator()),
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
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard({
    super.key,
    required this.profile,
    required this.index,
    required this.autofocus,
    required this.focusNode,
    this.onMoveLeft,
    this.onMoveRight,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final UserProfile profile;
  final int index;
  final bool autofocus;
  final FocusNode focusNode;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
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

  // La carte et ses boutons Modifier/Supprimer sont imbriqués : le parcours
  // directionnel ne descend pas dans un nœud dont le rectangle englobe déjà
  // ses enfants. On pilote donc le focus entre eux explicitement.
  FocusNode get _cardNode => widget.focusNode;
  final FocusNode _editNode = FocusNode(debugLabel: 'Profile edit');
  final FocusNode _deleteNode = FocusNode(debugLabel: 'Profile delete');

  @override
  void initState() {
    super.initState();
    _cardNode.addListener(_onCardFocusChanged);
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
    _cardNode.removeListener(_onCardFocusChanged);
    _editNode.dispose();
    _deleteNode.dispose();
    super.dispose();
  }

  void _onCardFocusChanged() {
    final focused = _cardNode.hasPrimaryFocus;
    if (_focused == focused) return;
    if (focused) HapticFeedback.selectionClick();
    setState(() => _focused = focused);
  }

  void _activate() {
    HapticFeedback.heavyImpact();
    widget.onSelect();
  }

  KeyEventResult _handleCardNavigation(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (_cardNode.hasPrimaryFocus) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onMoveLeft?.call();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        widget.onMoveRight?.call();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _editNode.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (_editNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowRight) {
        _deleteNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _cardNode.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (_deleteNode.hasFocus) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        _editNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _cardNode.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String get _profileTypeLabel => switch (widget.profile.profileType) {
        ProfileType.adult => AppLocalizations.of(context).profileAdult,
        ProfileType.child => AppLocalizations.of(context).profileChild,
        ProfileType.expert => AppLocalizations.of(context).profileExpert,
      };

  Widget _buildCardContent() {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.profile;
    final isActive = ref.watch(currentProfileProvider)?.id == profile.id;
    final ringColor = _focused
        ? scheme.tertiary
        : isActive
            ? scheme.primary
            : Colors.white.withValues(alpha: 0.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: _focused ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ringColor,
                    width: _focused
                        ? 5
                        : isActive
                            ? 2
                            : 1,
                  ),
                  boxShadow: [
                    if (_focused)
                      BoxShadow(
                        color: scheme.tertiary.withValues(alpha: 0.7),
                        blurRadius: 28,
                        spreadRadius: 3,
                      )
                    else if (isActive)
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ProfileAvatar(profile: profile, size: 120),
              ),
            ),
            if (isActive)
              const Positioned(
                bottom: -6,
                child: _ActiveBadge(),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _focused
                ? scheme.tertiary
                : isActive
                    ? scheme.primary
                    : null,
          ),
        ),
        if (profile.hasPin) ...[
          const SizedBox(height: 2),
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardActionButton(
              focusNode: _editNode,
              icon: Icons.edit_rounded,
              tooltip: l.profileEdit,
              onPressed: widget.onEdit,
            ),
            const SizedBox(width: 12),
            _CardActionButton(
              focusNode: _deleteNode,
              icon: Icons.delete_outline_rounded,
              tooltip: l.profileDelete,
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isActive = ref.watch(currentProfileProvider)?.id == widget.profile.id;
    return Semantics(
      container: true,
      label: '${l.menuProfile} ${widget.profile.firstName} ($_profileTypeLabel)'
          '${isActive ? ', ${l.profileActive}' : ''}',
      child: Focus(
        focusNode: _cardNode,
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) {
          final nav = _handleCardNavigation(event);
          if (nav == KeyEventResult.handled) return nav;
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
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: _buildCardContent(),
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
    required this.focusNode,
    this.onMoveLeft,
  });

  final int index;
  final bool autofocus;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final VoidCallback? onMoveLeft;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer
                .withValues(alpha: _focused ? 0.35 : 0.18),
            border: Border.all(
              color: _focused
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.45),
              width: _focused ? 3 : 1.5,
            ),
            boxShadow: [
              if (_focused)
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.4),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Icon(Icons.add_rounded, size: 52, color: scheme.primary),
        ),
        const SizedBox(height: 14),
        Text(
          l.createNewProfile,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) {
          if (hasFocus) HapticFeedback.selectionClick();
          setState(() => _focused = hasFocus);
        },
        onKeyEvent: (node, event) {
          if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            widget.onMoveLeft?.call();
            return KeyEventResult.handled;
          }
          if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.handled;
          }
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
            AppLocalizations.of(context).profileActive,
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
    this.focusNode,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

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
        message: profile == null
            ? AppLocalizations.of(context).chooseProfile
            : AppLocalizations.of(context).profileChange,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/profiles'),
          child: avatar,
        ),
      ),
    );
  }
}
