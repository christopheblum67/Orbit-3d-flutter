import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/widgets/widgets.dart';
import '../../models/channel.dart';
import '../../services/stream_helpers.dart';

class PlayerRouteData {
  const PlayerRouteData({
    required this.streamUrl,
    this.title,
    this.channels = const [],
    this.index = 0,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int index;
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.streamUrl,
    this.title,
    this.channels = const [],
    this.initialIndex = 0,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int initialIndex;

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
  late final List<Channel> _channels;
  late int _index;
  VideoPlayerController? _controller;
  VideoPlayerController? _cachedNext;
  int? _cachedNextIndex;
  VideoPlayerController? _cachedPrev;
  int? _cachedPrevIndex;
  int? _preloadTarget;
  _PlayerStatus _status = _PlayerStatus.loading;
  int _attempt = 0;
  bool _handlingError = false;
  bool _autorecovered = false;
  int _generation = 0;

  bool get _canZap => _channels.length > 1;
  bool get _hasNext => _canZap && _index < _channels.length - 1;
  bool get _hasPrevious => _canZap && _index > 0;

  String get _activeStreamUrl {
    if (_channels.isEmpty) return widget.streamUrl;
    return _channels[_index].streamUrl.isNotEmpty
        ? _channels[_index].streamUrl
        : widget.streamUrl;
  }

  @override
  void initState() {
    super.initState();
    _channels = widget.channels;
    _index = widget.initialIndex;
    if (_channels.isNotEmpty) {
      if (_index < 0) _index = 0;
      if (_index >= _channels.length) _index = _channels.length - 1;
    }
    _initializePlayer();
  }

  void _initializePlayer() {
    _generation++;
    _handlingError = false;
    _autorecovered = false;
    _attempt = 0;
    _startAttempt();
    _startPreload();
  }

  Future<void> _startAttempt() async {
    final gen = _generation;
    if (!mounted) return;
    if (_attempt >= _playbackUserAgents.length ||
        !isLikelyStreamUrl(_activeStreamUrl)) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }
    _setStatus(_PlayerStatus.loading);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_activeStreamUrl),
      httpHeaders: {
        'User-Agent': _playbackUserAgents[_attempt],
        'Accept': '*/*',
        'Referer': 'https://sofia.rabaden.eu/',
      },
    );
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Orbit3D video error: $e');
      if (_controller == controller) {
        _onFailure(gen);
      } else {
        _disposeController(controller);
      }
      return;
    }
    if (!mounted || gen != _generation || _controller != controller) {
      _disposeController(controller);
      return;
    }
    if (controller.value.hasError) {
      if (_controller == controller) {
        _onFailure(gen);
      } else {
        _disposeController(controller);
      }
      return;
    }
    controller.play();
    if (!mounted || gen != _generation || _controller != controller) {
      _disposeController(controller);
      return;
    }
    _setStatus(_PlayerStatus.ready);
  }

  void _onControllerUpdate() {
    if (!mounted || _status != _PlayerStatus.ready) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    debugPrint('Orbit3D video error: ${controller.value.errorDescription}');
    _handleActiveError();
  }

  void _handleActiveError() {
    if (!mounted || _handlingError) return;
    final gen = _generation;
    _handlingError = true;
    _disposeActive();
    if (!mounted || gen != _generation) {
      _handlingError = false;
      return;
    }
    if (!_autorecovered) {
      _autorecovered = true;
      _attempt = 0;
      _handlingError = false;
      _startAttempt();
      return;
    }
    _attempt = _playbackUserAgents.length;
    _handlingError = false;
    _setStatus(_PlayerStatus.error);
  }

  void _onFailure(int gen) {
    if (!mounted || _handlingError || gen != _generation) return;
    _handlingError = true;
    _disposeActive();
    if (!mounted || gen != _generation) {
      _handlingError = false;
      return;
    }
    _attempt++;
    if (_attempt >= _playbackUserAgents.length) {
      _handlingError = false;
      _setStatus(_PlayerStatus.error);
      return;
    }
    _handlingError = false;
    _startAttempt();
  }

  void _goNext() {
    if (_hasNext) _switchTo(_index + 1);
  }

  void _goPrevious() {
    if (_hasPrevious) _switchTo(_index - 1);
  }

  void _switchTo(int target) {
    if (!mounted ||
        target == _index ||
        target < 0 ||
        target >= _channels.length) {
      return;
    }
    _generation++;
    _autorecovered = false;
    _handlingError = false;
    final forward = target > _index;
    final oldActive = _controller;
    final newActive = _takeCachedFor(target);
    if (forward) {
      _disposeCachedPrev();
    } else {
      _disposeCachedNext();
    }
    _index = target;
    _preloadTarget = null;
    _controller = newActive;
    if (oldActive != null) {
      oldActive.removeListener(_onControllerUpdate);
      if (oldActive.value.isInitialized && !oldActive.value.hasError) {
        oldActive.pause();
        if (forward) {
          _cachedPrev = oldActive;
          _cachedPrevIndex = target - 1;
        } else {
          _cachedNext = oldActive;
          _cachedNextIndex = target + 1;
        }
      } else {
        oldActive.dispose();
      }
    }
    if (newActive != null) {
      newActive.addListener(_onControllerUpdate);
      newActive.play();
      _setStatus(_PlayerStatus.ready);
    } else {
      _attempt = 0;
      _startAttempt();
    }
    _startPreload();
  }

  VideoPlayerController? _takeCachedFor(int target) {
    VideoPlayerController? cached;
    if (_cachedNextIndex == target) {
      cached = _cachedNext;
      _cachedNext = null;
      _cachedNextIndex = null;
    } else if (_cachedPrevIndex == target) {
      cached = _cachedPrev;
      _cachedPrev = null;
      _cachedPrevIndex = null;
    }
    if (cached == null) return null;
    cached.removeListener(_onControllerUpdate);
    if (!cached.value.isInitialized || cached.value.hasError) {
      cached.dispose();
      return null;
    }
    return cached;
  }

  Future<void> _startPreload() async {
    final gen = _generation;
    if (!mounted || _channels.isEmpty) return;
    final target = _index + 1;
    if (target >= _channels.length) return;
    if (_cachedNext != null || _preloadTarget == target) return;
    if (!isLikelyStreamUrl(_channels[target].streamUrl)) return;
    _preloadTarget = target;
    for (var attempt = 0; attempt < _playbackUserAgents.length; attempt++) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_channels[target].streamUrl),
        httpHeaders: {
          'User-Agent': _playbackUserAgents[attempt],
          'Accept': '*/*',
          'Referer': 'https://sofia.rabaden.eu/',
        },
      );
      try {
        await controller.initialize();
      } catch (e) {
        debugPrint('Orbit3D preload error: $e');
        _disposeController(controller);
        continue;
      }
      if (!mounted || gen != _generation || _preloadTarget != target) {
        _disposeController(controller);
        if (_preloadTarget == target) _preloadTarget = null;
        return;
      }
      if (controller.value.hasError) {
        _disposeController(controller);
        continue;
      }
      if (!mounted || gen != _generation || _cachedNext != null) {
        _disposeController(controller);
        return;
      }
      controller.pause();
      _cachedNext = controller;
      _cachedNextIndex = target;
      _preloadTarget = null;
      return;
    }
    if (mounted && gen == _generation && _preloadTarget == target) {
      _preloadTarget = null;
    }
  }

  void _disposeController(VideoPlayerController controller) {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
  }

  void _disposeActive() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    _disposeController(controller);
  }

  void _disposeCachedNext() {
    final controller = _cachedNext;
    _cachedNext = null;
    _cachedNextIndex = null;
    if (controller == null) return;
    _disposeController(controller);
  }

  void _disposeCachedPrev() {
    final controller = _cachedPrev;
    _cachedPrev = null;
    _cachedPrevIndex = null;
    if (controller == null) return;
    _disposeController(controller);
  }

  void _setStatus(_PlayerStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _retry() async {
    _generation++;
    _handlingError = false;
    _autorecovered = false;
    _disposeCachedNext();
    _disposeCachedPrev();
    _attempt = 0;
    _startAttempt();
    _startPreload();
  }

  @override
  void dispose() {
    _generation++;
    _disposeActive();
    _disposeCachedNext();
    _disposeCachedPrev();
    _preloadTarget = null;
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
    final currentTitle = _channels.isEmpty
        ? (widget.title ?? 'Lecture')
        : _channels[_index].name;
    return Scaffold(
      appBar: AppBar(title: Text(currentTitle)),
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
      bottomNavigationBar: _canZap
          ? _ZapBar(
              index: _index,
              total: _channels.length,
              onPrevious: _hasPrevious ? _goPrevious : null,
              onNext: _hasNext ? _goNext : null,
            )
          : null,
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

class _ZapBar extends StatelessWidget {
  const _ZapBar({
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Chaîne précédente',
              onPressed: onPrevious,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${index + 1} / $total',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Zapping rapide',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Chaîne suivante',
              onPressed: onNext,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ),
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