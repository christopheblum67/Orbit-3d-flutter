import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/widgets/widgets.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.streamUrl, this.title});

  final String streamUrl;
  final String? title;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

enum _PlayerStatus { loading, error, ready }

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  _PlayerStatus _status = _PlayerStatus.loading;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _status = _PlayerStatus.loading;
    });
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));
      _controller = controller;
      controller.addListener(_onControllerUpdate);
      await controller.initialize();
      if (!mounted) return;
      if (controller.value.hasError) {
        debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
        setState(() {
          _status = _PlayerStatus.error;
        });
        return;
      }
      controller.play();
      setState(() {
        _status = _PlayerStatus.ready;
      });
    } catch (e) {
      debugPrint('Orbit3D video error: $e');
      if (!mounted) return;
      setState(() {
        _status = _PlayerStatus.error;
      });
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _status == _PlayerStatus.ready) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    setState(() {
      _status = _PlayerStatus.error;
    });
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
  }

  Future<void> _retry() async {
    _disposeController();
    await _initializePlayer();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Lecture')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_status) {
            _PlayerStatus.loading => const VideoLoadingState(),
            _PlayerStatus.error => VideoErrorState(onRetry: _retry),
            _PlayerStatus.ready => _ReadyPlayer(
                controller: _controller!,
                onTap: _togglePlayPause,
              ),
          },
        ),
      ),
      floatingActionButton: _status == _PlayerStatus.ready
          ? FloatingActionButton.large(
              onPressed: _togglePlayPause,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _controller!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  key: ValueKey(_controller!.value.isPlaying),
                ),
              ),
            )
          : null,
    );
  }
}

class _ReadyPlayer extends StatelessWidget {
  const _ReadyPlayer({required this.controller, required this.onTap});

  final VideoPlayerController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
