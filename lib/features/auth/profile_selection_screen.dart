import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/user_profile.dart';
import '../../core/widgets/widgets.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Qui regarde ?')),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return EmptyState(
              icon: Icons.face_outlined,
              title: 'Aucun profil pour le moment',
              message: 'Crée ton premier profil pour commencer à regarder.',
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Créer un profil'),
                onPressed: () => context.push('/profile/create'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1),
                duration: Duration(
                  milliseconds: 350 + (index * 70),
                ),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0, 1),
                    child: Transform.scale(scale: value, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () {
                      ref.read(currentProfileProvider.notifier).state = profile;
                      context.pushReplacement('/live');
                    },
                    child: Row(
                      children: [
                        _ProfileAvatar(profile: profile),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.firstName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile.favoriteGenres.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/create'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau profil'),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = profile.firstName.isNotEmpty
        ? profile.firstName[0].toUpperCase()
        : '?';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: scheme.onPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}