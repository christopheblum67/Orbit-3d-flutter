import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/tv_focus.dart';

class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live TV')),
      body: channelsAsync.when(
        data: (channels) => ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return TvFocus(
              onActivate: () {
                context.push(
                  '/player?url=${Uri.encodeComponent(channel.streamUrl)}&title=${Uri.encodeComponent(channel.name)}',
                );
              },
              child: ListTile(
                leading: const Icon(Icons.live_tv),
                title: Text(channel.name),
                subtitle: Text(channel.group),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
