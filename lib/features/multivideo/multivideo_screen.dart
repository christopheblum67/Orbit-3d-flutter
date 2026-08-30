import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../providers/providers.dart';
import '../../models/channel.dart';
import '../../core/widgets/widgets.dart';
import '../../services/user_friendly_error.dart';

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
      body: channelsAsync.when(
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.live_tv_outlined,
          title: 'Chaînes indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(liveChannelsProvider),
        ),
        data: (channels) => Column(
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
              child: ListView.builder(
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
            ),
          ],
        ),
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
  VideoPlayerController? _controller;
  int _generation = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_generation;
    _failed = false;
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      old.dispose();
    }
    if (!mounted) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Orbit3D multivideo error: $e');
      if (!mounted || gen != _generation) return;
      if (_controller == controller) {
        _controller = null;
        controller.removeListener(_onControllerUpdate);
        controller.dispose();
      }
      setState(() => _failed = true);
      return;
    }
    if (!mounted || gen != _generation || _controller != controller) return;
    if (controller.value.hasError) {
      setState(() => _failed = true);
      return;
    }
    controller.play();
    setState(() {});
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    setState(() => _failed = true);
  }

  @override
  void dispose() {
    _generation++;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onControllerUpdate);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }
    if (_failed) {
      return Center(
        child: Icon(
          Icons.live_tv_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 32,
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
