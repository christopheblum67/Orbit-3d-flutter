import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.15,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
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
                    horizontal: 10,
                    vertical: 16,
                  ),
                  onTap: () {
                    ref.read(currentProfileProvider.notifier).state = profile;
                    ref
                        .read(storageServiceProvider)
                        .setSetting('last_profile_id', profile.id);
                    context.pushReplacement('/home');
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            ProfileAvatar(profile: profile, size: 100),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: GestureDetector(
                                onTap: () => context.push(
                                  '/profile/edit?id=${profile.id}',
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
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
