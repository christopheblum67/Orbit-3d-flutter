import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Écran de sélection de profils pour le mode Duo (2-4 profils) :
/// le profil courant est toujours inclus ; on ajoute 1 à 3 autres profils.
/// Même présentation visuelle que la page « Qui regarde ? ».
class DuoProfileSelectionScreen extends ConsumerStatefulWidget {
  const DuoProfileSelectionScreen({super.key});

  @override
  ConsumerState<DuoProfileSelectionScreen> createState() =>
      _DuoProfileSelectionScreenState();
}

class _DuoProfileSelectionScreenState
    extends ConsumerState<DuoProfileSelectionScreen> {
  static const int maxAdditional = 3;

  final Set<String> _selectedIds = {};
  UserProfile? _currentProfile;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final currentProfile = ref.watch(currentProfileProvider);
    _currentProfile = currentProfile;

    return Scaffold(
      endDrawer: const HomeMenuDrawer(),
      body: SafeArea(
        child: profilesAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return const Center(child: Text('Aucun profil disponible'));
            }
            return _buildBody(context, profiles, currentProfile);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<UserProfile> profiles,
    UserProfile? currentProfile,
  ) {
    final others = profiles.where((p) => p.id != currentProfile?.id).toList();
    final othersAscending = others.sortedByDisplay();
    final totalSelected = _selectedIds.length + 1;
    final ready = _selectedIds.isNotEmpty;

    return Column(
      children: [
        _buildHeader(context, totalSelected),
        Expanded(
          child: others.isEmpty
              ? _buildEmptyOthers(context)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisExtent: 210,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: othersAscending.length,
                  itemBuilder: (context, index) {
                    final profile = othersAscending[index];
                    final selected = _selectedIds.contains(profile.id);
                    final disabled = !selected &&
                        _selectedIds.length >= maxAdditional;
                    return _DuoProfileCard(
                      profile: profile,
                      index: index,
                      selected: selected,
                      disabled: disabled,
                      autofocus: index == 0 && !ready,
                      onToggle: () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(profile.id);
                          } else if (!disabled) {
                            _selectedIds.add(profile.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        _buildFooter(context, totalSelected, ready),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int totalSelected) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
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
                  'Mode Duo',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentProfile == null
                      ? 'Choisissez 1 à $maxAdditional profil(s) supplémentaire(s)'
                      : 'Avec « ${_currentProfile!.firstName} » — choisissez 1 à '
                          '$maxAdditional autre(s) profil(s)',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ProfilesCountBadge(current: totalSelected, max: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyOthers(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_outlined, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'Créez au moins un 2e profil',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Le mode Duo nécessite au moins 2 profils au total.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, int totalSelected, bool ready) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalSelected >= 4
                ? '4 profils — équipe complète pour le Duo'
                : ready
                    ? '$totalSelected profils sélectionnés — prêt pour le Duo'
                    : 'Sélectionnez au moins 1 profil supplémentaire '
                        '(${_selectedIds.length + 1}/4)',
            style: TextStyle(
              color: ready ? scheme.primary : scheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: ready ? _launchDuo : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Lancer le Duo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchDuo() {
    final current = _currentProfile;
    if (current == null) return;
    if (_selectedIds.isEmpty) return;

    final group = [current.id, ..._selectedIds];
    context.go('/matchmaking/duo', extra: group);
  }
}

/// Carte profil sélectionnable en mode Duo : même présentation que la page
/// « Qui regarde ? » (anneau orbital, badge de type, focus d-pad) avec un
/// état de sélection (coche / verrou lorsque le maximum est atteint).
class _DuoProfileCard extends ConsumerStatefulWidget {
  const _DuoProfileCard({
    required this.profile,
    required this.index,
    required this.selected,
    required this.disabled,
    required this.autofocus,
    required this.onToggle,
  });

  final UserProfile profile;
  final int index;
  final bool selected;
  final bool disabled;
  final bool autofocus;
  final VoidCallback onToggle;

  @override
  ConsumerState<_DuoProfileCard> createState() => _DuoProfileCardState();
}

class _DuoProfileCardState extends ConsumerState<_DuoProfileCard>
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
    widget.onToggle();
  }

  Widget _buildCardContent() {
    final scheme = Theme.of(context).colorScheme;
    final profile = widget.profile;
    final highlight = widget.selected || widget.disabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: _focused
              ? scheme.tertiary
              : widget.selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
          width: _focused
              ? 2.5
              : widget.selected
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
          else if (widget.selected)
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Stack(
        children: [
          Opacity(
            opacity: widget.disabled ? 0.45 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OrbitAvatar(
                  profile: profile,
                  enlarged: _focused || highlight,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.selected ? scheme.primary : null,
                      ),
                ),
                const SizedBox(height: 6),
                ProfileTypeBadge(profileType: profile.profileType),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.selected
                    ? scheme.primary
                    : widget.disabled
                        ? scheme.surfaceContainerHighest
                        : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.selected
                        ? Icons.check_circle
                        : widget.disabled
                            ? Icons.lock_outline
                            : Icons.circle_outlined,
                    size: 14,
                    color: widget.selected
                        ? Colors.white
                        : widget.disabled
                            ? scheme.onSurfaceVariant
                            : scheme.outline,
                  ),
                  if (widget.selected || widget.disabled) ...[
                    const SizedBox(width: 4),
                    Text(
                      widget.selected ? 'Sélectionné' : 'Max atteint',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: widget.selected
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        if (hasFocus) HapticFeedback.selectionClick();
        setState(() => _focused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          if (widget.disabled) return KeyEventResult.ignored;
          _activate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.disabled ? null : _activate,
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
    );
  }
}

extension on List<UserProfile> {
  /// Tri alphabétique stable (crée une copie triée).
  List<UserProfile> sortedByDisplay() {
    final copy = [...this];
    copy.sort(
      (a, b) => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
    );
    return copy;
  }
}