import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/widgets/confirm_exit_app.dart';

class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final currentProfile = ref.watch(currentProfileProvider);

    return ConfirmExitApp(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Qui regarde ?'),
          leading: context.canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
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
                final isActive = currentProfile?.id == profile.id;
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
                              GestureDetector(
                                onTap: () => context.push(
                                  '/profile/edit?id=${profile.id}',
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isActive
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 3,
                                          )
                                        : null,
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 20,
                                              spreadRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ProfileAvatar(
                                      profile: profile, size: 100,),
                                ),
                              ),
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
                              if (isActive)
                                Positioned(
                                  top: -8,
                                  left: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3,),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
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
      ),
    );
  }
}
