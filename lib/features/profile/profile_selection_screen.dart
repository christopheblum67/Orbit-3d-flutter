import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/profile/pin_pad_screen.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

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

  Future<void> _selectProfile(UserProfile profile) async {
    // Enfant/Expert protégé par PIN : vérification avant de continuer.
    if ((profile.isChild || profile.isExpert) && profile.hasPin) {
      ref.read(currentProfileProvider.notifier).state = profile;
      final ok = await context.push<bool>(
        '/profile/pin',
        extra: PinPadArgs.verify(profile),
      );
      if (!mounted) return;
      if (ok != true) {
        ref.read(currentProfileProvider.notifier).state = null;
        ref.read(profileTypeProvider.notifier).clear();
        return;
      }
    }
    await _finishSelect(profile);
  }

  Future<void> _finishSelect(UserProfile profile) async {
    final refreshed = profile.copyWith(lastActiveAt: DateTime.now());
    ref.read(currentProfileProvider.notifier).state = refreshed;
    ref.read(profileTypeProvider.notifier).loadFromProfile(refreshed);
    final storage = ref.read(storageServiceProvider);
    await storage.saveProfile(refreshed);
    await storage.setSetting('last_profile_id', profile.id);
    ref.invalidate(profilesProvider);
    if (!mounted) return;
    context.pushReplacement('/home');
  }

  void _openCreate(int current, int max) {
    if (current >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nombre maximal de profils atteint ($max)'),
        ),
      );
      return;
    }
    context.push('/profile/create');
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
          _ProfilesCountBadge(current: current, max: max),
        ],
      ),
    );
  }

  Widget _buildProfileGrid(List<UserProfile> profiles, int maxProfiles) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisExtent: 200,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: profiles.length + 1,
      itemBuilder: (context, index) {
        final isAddCard = index == profiles.length;
        if (isAddCard) {
          return _AddProfileCard(
            index: index,
            autofocus: false,
            onTap: () => _openCreate(profiles.length, maxProfiles),
          );
        }
        final profile = profiles[index];
        return _ProfileCard(
          profile: profile,
          index: index,
          autofocus: index == 0,
          onSelect: () => _selectProfile(profile),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.manage_accounts_rounded,
              title: 'Aucun profil pour le moment',
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
    final profilesAsync = ref.watch(profilesProvider);
    return Scaffold(
      body: SafeArea(
        child: profilesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Impossible de charger les profils',
            message: '$error',
            action: FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
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
    );
  }
}

class _ProfilesCountBadge extends StatelessWidget {
  const _ProfilesCountBadge({required this.current, required this.max});

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            '$current / $max',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  const _ProfileTypeBadge({required this.profileType});

  final ProfileType profileType;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (profileType) {
      ProfileType.child => (
          'Enfant',
          Icons.child_care,
          const Color(0xFF00CFE8)
        ),
      ProfileType.expert => (
          'Expert',
          Icons.psychology_rounded,
          const Color(0xFF8A72FF)
        ),
      ProfileType.adult => (
          'Adulte',
          Icons.sentiment_satisfied_alt,
          const Color(0xFFFF4D8D),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({
    required this.profile,
    required this.index,
    required this.autofocus,
    required this.onSelect,
  });

  final UserProfile profile;
  final int index;
  final bool autofocus;
  final VoidCallback onSelect;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard>
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

  Widget _buildCardContent() {
    final scheme = Theme.of(context).colorScheme;
    final profile = widget.profile;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: _focused
              ? scheme.tertiary
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: _focused ? 2.5 : 1,
        ),
        boxShadow: [
          if (_focused)
            BoxShadow(
              color: scheme.tertiary.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OrbitAvatar(profile: profile, enlarged: _focused),
          const SizedBox(height: 12),
          Text(
            profile.firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          _ProfileTypeBadge(profileType: profile.profileType),
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
              width: _focused ? 74 : 66,
              height: _focused ? 74 : 66,
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
                size: 38,
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
              'Créer un nouveau profil',
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
    );
  }
}

/// Carte « + » : anneau orbital tournant autour de l'avatar généré.
class _OrbitAvatar extends StatefulWidget {
  const _OrbitAvatar({required this.profile, required this.enlarged});

  final UserProfile profile;
  final bool enlarged;

  @override
  State<_OrbitAvatar> createState() => _OrbitAvatarState();
}

class _OrbitAvatarState extends State<_OrbitAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const base = 108.0;
    final diameter = widget.enlarged ? base + 10 : base;
    final disc = diameter - 8;
    final avatarSize = disc - 12;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _spin,
          builder: (context, _) => Transform.rotate(
            angle: _spin.value * 2 * math.pi,
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    scheme.tertiary,
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: disc,
          height: disc,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerLow,
          ),
          alignment: Alignment.center,
          child: ProfileAvatar(
            profile: widget.profile,
            size: avatarSize,
          ),
        ),
      ],
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
