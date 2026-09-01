import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../core/widgets/widgets.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../providers/providers.dart';
import '../../services/stream_helpers.dart';
import '../../services/stream_prewarm_service.dart';

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

class PlayerScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

enum _PlayerStatus { loading, error, ready }

const _playbackUserAgents = <String>[
  'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
  'Orbit3D/1.0 (Linux; Android 14; FireTV) ExoPlayerLib/2.19.1',
  'ExoPlayer/2.19.1',
];

/// Durée maximale accordée à initialise() avant de basculer sur le
/// prochain User-Agent : évite de bloquer le zapping sur un flux muet.
const _probTimeout = Duration(seconds: 12);

/// Durée d'affichage de la barre d'info avant masquage automatique.
const _infoBarDuration = Duration(milliseconds: 4500);

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  List<Channel> _channels = const [];
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
  bool _showInfo = false;
  Timer? _infoTimer;
  bool _volumeToZap = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerScreen');

  bool get _canZap => _channels.length > 1;
  bool get _hasNext => _canZap && _index < _channels.length - 1;
  bool get _hasPrevious => _canZap && _index > 0;

  String get _activeStreamUrl {
    if (_channels.isEmpty) return widget.streamUrl;
    return _channels[_index].streamUrl.isNotEmpty
        ? _channels[_index].streamUrl
        : widget.streamUrl;
  }

  Channel? get _currentChannel =>
      _channels.isEmpty ? null : _channels[_index];

  static String _refererFor(Uri uri) {
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    return '${uri.scheme}://${uri.host}:$port/';
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

  @override
  void dispose() {
    _infoTimer?.cancel();
    _focusNode.dispose();
    _generation++;
    _disposeActive();
    _disposeCachedNext();
    _disposeCachedPrev();
    _preloadTarget = null;
    super.dispose();
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
    if (!isLikelyStreamUrl(_activeStreamUrl)) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }
    // Flux préchauffé par la grille Live TV : zapping sans démarrage à froid.
    final prewarmed = StreamPrewarmService.instance.take(_activeStreamUrl);
    if (prewarmed != null) {
      _controller = prewarmed;
      prewarmed.addListener(_onControllerUpdate);
      prewarmed.play();
      if (!mounted || gen != _generation || _controller != prewarmed) {
        _disposeController(prewarmed);
        return;
      }
      _setStatus(_PlayerStatus.ready);
      _showInfoBrief();
      return;
    }
    if (_attempt >= _playbackUserAgents.length) {
      if (gen == _generation) _setStatus(_PlayerStatus.error);
      return;
    }
    _setStatus(_PlayerStatus.loading);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_activeStreamUrl),
      httpHeaders: {
        'User-Agent': _playbackUserAgents[_attempt],
        'Accept': '*/*',
        'Referer': _refererFor(Uri.parse(_activeStreamUrl)),
      },
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    try {
      await controller.initialize().timeout(_probTimeout);
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
    _showInfoBrief();
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
      _showInfoBrief();
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
          'Referer': _refererFor(Uri.parse(_channels[target].streamUrl)),
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      try {
        await controller.initialize().timeout(_probTimeout);
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

  void _showInfoBrief() {
    _infoTimer?.cancel();
    if (!mounted) return;
    setState(() => _showInfo = true);
    _infoTimer = Timer(_infoBarDuration, () {
      if (mounted) setState(() => _showInfo = false);
    });
  }

  void _toggleInfo() {
    _infoTimer?.cancel();
    setState(() => _showInfo = !_showInfo);
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  void _toggleVolumeZap() {
    setState(() => _volumeToZap = !_volumeToZap);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      _goPrevious();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown) {
      _goNext();
      return KeyEventResult.handled;
    }
    if (_volumeToZap) {
      if (key == LogicalKeyboardKey.audioVolumeUp) {
        _goNext();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.audioVolumeDown) {
        _goPrevious();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _toggleInfo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _currentChannel?.name ?? widget.title ?? 'Lecture';
    return Scaffold(
      appBar: AppBar(title: Text(currentTitle)),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (_status) {
              _PlayerStatus.loading => const VideoLoadingState(),
              _PlayerStatus.error => VideoErrorState(onRetry: _retry),
              _PlayerStatus.ready => Stack(
                  fit: StackFit.expand,
                  children: [
                    _ReadyPlayer(
                      controller: _controller!,
                      onTap: _toggleInfo,
                    ),
                    if (_showInfo && _currentChannel != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: _InfoBar(
                            channel: _currentChannel!,
                            onClose: _toggleInfo,
                          ),
                        ),
                      ),
                  ],
                ),
            },
          ),
        ),
      ),
      bottomNavigationBar: _canZap
          ? _ZapBar(
              index: _index,
              total: _channels.length,
              volumeToZap: _volumeToZap,
              onPrevious: _hasPrevious ? _goPrevious : null,
              onNext: _hasNext ? _goNext : null,
              onToggleVolumeZap: _toggleVolumeZap,
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
    required this.volumeToZap,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleVolumeZap,
  });

  final int index;
  final int total;
  final bool volumeToZap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToggleVolumeZap;

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
                    volumeToZap
                        ? 'Zapping rapide · volume = chaîne'
                        : 'Zapping rapide',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: volumeToZap
                  ? 'Volume normal'
                  : 'Changer de chaîne avec le volume',
              onPressed: onToggleVolumeZap,
              icon: Icon(
                volumeToZap ? Icons.tap_and_play : Icons.volume_up,
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

class _InfoBar extends ConsumerWidget {
  const _InfoBar({required this.channel, this.onClose});

  final Channel channel;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final epgAsync = ref.watch(channelEpgProvider(channel.epgChannelId));
    final (nowProgram, nextProgram) = _nowAndNext(epgAsync.value ?? const []);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.72),
                Colors.black.withOpacity(0.28),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (epgAsync.isLoading && nowProgram == null)
                      Text(
                        'Programme en cours de chargement…',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      )
                    else
                      _EpgRow(now: nowProgram, next: nextProgram),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Masquer les infos',
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpgRow extends StatelessWidget {
  const _EpgRow({required this.now, required this.next});

  final EPGProgram? now;
  final EPGProgram? next;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = now;
    if (current == null) {
      return const Row(
        children: [
          Icon(Icons.tv_off_rounded, size: 14, color: Colors.white54),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Programme non disponible',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq_rounded, size: 14, color: scheme.tertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${_fmt(current.start)} - ${_fmt(current.end)}   ${current.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (next != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Suivant : ${_fmt(next!.start)}   ${next!.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

(EPGProgram?, EPGProgram?) _nowAndNext(List<EPGProgram> programs) {
  final now = DateTime.now();
  EPGProgram? current;
  EPGProgram? next;
  for (final program in programs) {
    if (!program.start.isAfter(now) && program.end.isAfter(now)) {
      current = program;
      break;
    }
  }
  if (current != null) {
    final index = programs.indexOf(current);
    if (index + 1 < programs.length && programs[index + 1].start.isAfter(now)) {
      next = programs[index + 1];
    }
  } else if (programs.isNotEmpty) {
    next = programs.firstWhere(
      (p) => p.start.isAfter(now),
      orElse: () => programs.last,
    );
  }
  return (current, next);
}

String _fmt(DateTime time) => DateFormat('HH:mm').format(time);

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