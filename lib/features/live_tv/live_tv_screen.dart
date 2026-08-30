import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/tv_focus.dart';
import '../../core/widgets/widgets.dart';

class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live TV')),
      body: channelsAsync.when(
        data: (channels) {
          if (channels.isEmpty) {
            return const EmptyState(
              icon: Icons.live_tv_outlined,
              title: 'Aucune chaîne disponible',
              message: 'Ajoute une source de chaînes dans les réglages.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              void onOpen() {
                context.push(
                  '/player?url=${Uri.encodeComponent(channel.streamUrl)}&title=${Uri.encodeComponent(channel.name)}',
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TvFocus(
                  onActivate: onOpen,
                  child: ChannelTile(
                    title: channel.name,
                    subtitle: channel.group,
                    icon: Icons.live_tv,
                    imageUrl: channel.logoUrl,
                    onTap: onOpen,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}