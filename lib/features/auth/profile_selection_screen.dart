import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Qui regarde ?')),
      body: profilesAsync.when(
        data: (profiles) => ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return ListTile(
              leading: CircleAvatar(child: Text(profile.firstName[0])),
              title: Text(profile.firstName),
              subtitle: Text(profile.favoriteGenres.join(', ')),
              onTap: () {
                ref.read(currentProfileProvider.notifier).state = profile;
                context.pushReplacement('/live');
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.push('/profile/create'),
      ),
    );
  }
}
