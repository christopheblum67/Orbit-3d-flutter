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

const _playbackUserAgents = <String>[
  'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
  'Orbit3D/1.0 (Linux; Android 14; FireTV) ExoPlayerLib/2.19.1',
  'ExoPlayer/2.19.1',
];

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  _PlayerStatus _status = _PlayerStatus.loading;
  int _attempt = 0;
  bool _handlingError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _attempt = 0;
    _handlingError = false;
    await _startAttempt();
  }

  Future<void> _startAttempt() async {
    if (!mounted) return;
    if (_attempt >= _playbackUserAgents.length) {
      setState(() {
        _status = _PlayerStatus.error;
      });
      return;
    }
    setState(() {
      _status = _PlayerStatus.loading;
    });
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.streamUrl),
      httpHeaders: {'User-Agent': _playbackUserAgents[_attempt]},
    );
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Orbit3D video error: $e');
      _onFailure();
      return;
    }
    if (!mounted || _controller != controller) return;
    if (controller.value.hasError) {
      _onFailure();
      return;
    }
    controller.play();
    setState(() {
      _status = _PlayerStatus.ready;
    });
  }

  void _onControllerUpdate() {
    if (!mounted || _status == _PlayerStatus.ready) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    _onFailure();
  }

  void _onFailure() {
    if (!mounted || _handlingError) return;
    final failedAttempt = _attempt;
    _handlingError = true;
    _disposeController();
    _attempt++;
    if (!mounted || _attempt != failedAttempt + 1) return;
    _startAttempt();
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