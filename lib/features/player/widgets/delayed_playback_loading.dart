import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/video_error_state.dart';
import 'package:orbit_3d_flutter/core/widgets/video_loading_state.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class DelayedPlaybackLoading extends StatefulWidget {
  const DelayedPlaybackLoading({
    super.key,
    required this.onRetry,
    this.delay = const Duration(seconds: 45),
    this.initialChild = const VideoLoadingState(),
  });

  final VoidCallback onRetry;
  final Duration delay;
  final Widget initialChild;

  @override
  State<DelayedPlaybackLoading> createState() => _DelayedPlaybackLoadingState();
}

class _DelayedPlaybackLoadingState extends State<DelayedPlaybackLoading> {
  Timer? _timer;
  bool _delayed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _delayed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_delayed) return widget.initialChild;
    final l = AppLocalizations.of(context);
    return VideoErrorState(
      title: l.playbackDelayedTitle,
      message: l.playbackDelayedMessage,
      autoFocusRetry: true,
      onRetry: widget.onRetry,
      onContinueWaiting: () {
        setState(() => _delayed = false);
        _startTimer();
      },
    );
  }
}
