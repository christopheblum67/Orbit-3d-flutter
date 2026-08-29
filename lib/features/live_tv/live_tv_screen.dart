import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final channels = [
      Channel(id: '1', name: 'Chaîne 1', logoUrl: '', streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8', group: 'Général'),
      Channel(id: '2', name: 'Chaîne 2', logoUrl: '', streamUrl: 'https://test-streams.mux.dev/tos_ismc/main.m3u8', group: 'Sport'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Live TV')),
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.live_tv),
          title: Text(channels[index].name),
          subtitle: Text(channels[index].group),
          onTap: () {
            context.push('/player?url=${Uri.encodeComponent(channels[index].streamUrl)}&title=${Uri.encodeComponent(channels[index].name)}');
          },
        ),
      ),
    );
  }
}
