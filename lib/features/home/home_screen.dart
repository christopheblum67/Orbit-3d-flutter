import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

import 'package:orbit_3d_flutter/features/home/solar_system_navigator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isM3u = ref.watch(sourceTypeProvider).valueOrNull == 'm3u';
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: const SolarSystemNavigator()),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final today = DateTime.now();
    final dateLabel = DateFormat('EEE d MMM', 'fr_FR').format(today);
    final timeLabel = DateFormat('HH:mm', 'fr_FR').format(today);
    final lastRefresh = ref.watch(lastRefreshTimestampProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _ClockBlock(date: _capitalize(dateLabel), time: timeLabel),
          const Spacer(),
          TvFocus(
            onActivate: () => context.go('/settings'),
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TvFocus(
            onActivate: () => context.go('/search'),
            child: GestureDetector(
              onTap: () => context.go('/search'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _UpdateStack(
            tooltip: 'Mettre à jour toutes les données',
            onPressed: _refreshAll,
            lastRefresh: lastRefresh,
          ),
          const SizedBox(width: 16),
          const ShaderMask(
            shaderCallback: _logoGradient,
            child: Text(
              'Orbit IPTV',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(liveChannelsProvider);
    ref.invalidate(moviesProvider);
    ref.invalidate(seriesProvider);
    ref.invalidate(radioChannelsProvider);
    ref.invalidate(replaysProvider);
    ref.invalidate(epgProgramsProvider);
    ref.invalidate(epgDataCacheProvider);
    ref.read(lastRefreshTimestampProvider.notifier).state = DateTime.now();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Mise à jour en cours…'),
          duration: Duration(milliseconds: 1800),
        ),
      );
  }

  Widget _buildBottomBar(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final current = ref.watch(currentProfileProvider);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),),
      ),
      child: Row(
        children: [
          const _SubStatusChip(),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/profiles'),
            child: Row(
              children: [
                Text(
                  'Profil : ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 13,),
                ),
                const SizedBox(width: 8),
                _buildProfileAvatar(context, current,
                    profilesAsync.valueOrNull ?? const <UserProfile>[],),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    UserProfile? current,
    List<UserProfile> profiles,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (current == null || profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            const Text(
              'Choisir',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,),
            ),
          ],
        ),
      );
    }
    final idx = profiles.indexWhere((p) => p.id == current.id);
    final color = _profileColor(idx);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: color.withValues(alpha: 0.3),
            child: Text(
              current.firstName.isNotEmpty
                  ? current.firstName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11,),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            current.firstName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static const List<Color> _profileColors = [
    Color(0xFF00CFE8),
    Color(0xFFFFB300),
    Color(0xFFB388FF),
    Color(0xFFFF6FA8),
  ];

  Color _profileColor(int index) {
    if (index < 0) return _profileColors.first;
    return _profileColors[index % _profileColors.length];
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _SubStatusChip extends ConsumerWidget {
  const _SubStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(activeSubscriptionProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final name = sub?.name ?? '';
    final validity = sub?.validityLabel ?? '';
    if (name.isEmpty) {
      return const _NoSubscriptionChip();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: scheme.primary.withValues(alpha: 0.4),
              ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (validity.isNotEmpty)
                Text(
                  validity,
                  style: TextStyle(
                    color: scheme.primary.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.go('/subscriptions'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00CFE8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.4),),
            ),
            child: const Text(
              'Changer',
              style: TextStyle(
                color: Color(0xFF00CFE8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoSubscriptionChip extends StatelessWidget {
  const _NoSubscriptionChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.amberAccent,
                  size: 16,
                ),
              const SizedBox(width: 6),
              Text(
                'Aucun abo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => context.go('/subscriptions'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00CFE8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00CFE8).withValues(alpha: 0.4),),
            ),
            child: const Text(
              'Changer',
              style: TextStyle(
                color: Color(0xFF00CFE8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dégradé du logo Orbit IPTV.
Shader _logoGradient(Rect bounds) => const LinearGradient(
      colors: [Color(0xFF00CFE8), Color(0xFFB388FF)],
    ).createShader(bounds);

/// Horloge affichée à gauche de la barre d'accueil (date + heure réelles).
class _ClockBlock extends StatelessWidget {
  const _ClockBlock({required this.date, required this.time});

  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF00CFE8)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Formate un timestamp en "il y a XhYY" ou "il y a X min".
String _formatRelative(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inHours > 0) {
    return 'Mis à jour il y a ${diff.inHours}h${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  }
  return 'Mis à jour il y a ${diff.inMinutes} min';
}

/// Bouton de mise à jour avec la date de la dernière actualisation en dessous.
class _UpdateStack extends StatelessWidget {
  const _UpdateStack({
    required this.onPressed,
    required this.tooltip,
    required this.lastRefresh,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final DateTime? lastRefresh;

  @override
  Widget build(BuildContext context) {
    final label = switch (lastRefresh) {
      null => 'Jamais mis à jour',
      final ts => _formatRelative(ts.toLocal()),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UpdateButton(
          tooltip: tooltip,
          onPressed: onPressed,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({
    required this.onPressed,
    this.tooltip = 'Mettre à jour',
    this.icon = Icons.refresh_rounded,
    this.color = const Color(0xFF00CFE8),
  });

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}