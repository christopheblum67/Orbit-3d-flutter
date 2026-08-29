import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

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
                context.push('/player?url=${Uri.encodeComponent(replay.streamUrl)}&title=${Uri.encodeComponent(replay.title)}');
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
