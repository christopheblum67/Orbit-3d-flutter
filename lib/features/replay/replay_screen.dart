import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

class ReplayScreen extends ConsumerWidget {
  const ReplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replaysAsync = ref.watch(replaysProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Replay')),
      body: replaysAsync.when(
        data: (replays) => ListView.builder(
          itemCount: replays.length,
          itemBuilder: (context, index) {
            final replay = replays[index];
            return ListTile(
              leading: const Icon(Icons.replay),
              title: Text(replay.title),
              subtitle: Text('${replay.startTime} - ${replay.endTime}'),
              onTap: () {
                context.push(
                    '/player?url=${Uri.encodeComponent(replay.streamUrl)}&title=${Uri.encodeComponent(replay.title)}',);
              },
            );
          },
        ),
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.replay,
          title: 'Replays indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(replaysProvider),
        ),
      ),
    );
  }
}
