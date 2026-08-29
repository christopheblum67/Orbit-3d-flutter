import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../providers/providers.dart';
import '../../models/channel.dart';

class MultiVideoScreen extends ConsumerStatefulWidget {
  const MultiVideoScreen({super.key});

  @override
  ConsumerState<MultiVideoScreen> createState() => _MultiVideoScreenState();
}

class _MultiVideoScreenState extends ConsumerState<MultiVideoScreen> {
  List<Channel> _selectedChannels = [];

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-vidéo')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
              ),
              itemCount: _selectedChannels.length,
              itemBuilder: (context, index) => VideoTile(url: _selectedChannels[index].streamUrl),
            ),
          ),
          SizedBox(
            height: 120,
            child: channelsAsync.when(
              data: (channels) => ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final ch = channels[index];
                  return FilterChip(
                    label: Text(ch.name),
                    selected: _selectedChannels.contains(ch),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedChannels.length < 4) {
                            _selectedChannels.add(ch);
                          }
                        } else {
                          _selectedChannels.remove(ch);
                        }
                      });
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erreur: $err'),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoTile extends StatefulWidget {
  final String url;
  const VideoTile({super.key, required this.url});

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() => _controller.play()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
        : const Center(child: CircularProgressIndicator());
  }
}
