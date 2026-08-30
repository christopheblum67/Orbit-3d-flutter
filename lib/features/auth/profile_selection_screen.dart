import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
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
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              childAspectRatio: 0.88,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
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
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 18,
                  ),
                  onTap: () {
                    ref.read(currentProfileProvider.notifier).state = profile;
                    context.pushReplacement('/home');
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProfileAvatar(profile: profile, size: 76),
                      const SizedBox(height: 14),
                      Text(
                        profile.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
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