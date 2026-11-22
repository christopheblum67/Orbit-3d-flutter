import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orbit_3d_flutter/core/utils/image_cache_config.dart';
import 'package:orbit_3d_flutter/core/utils/poster_metrics.dart';

/// Wrapper `CachedNetworkImage` avec gestion de cache bornée (disque + mémoire).
///
/// Utilise `OrbitCacheManager` (5000 objets max, TTL 30 jours).
/// Placeholder/error unifiés pour cohérence UX.
/// Supporte l'injection d'en-têtes HTTP (ex. cookies Cloudflare) via [httpHeaders].
class OrbitCachedImage extends StatefulWidget {
  const OrbitCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.filterQuality = FilterQuality.medium,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.httpHeaders,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final FilterQuality filterQuality;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final Map<String, String>? httpHeaders;

  @override
  State<OrbitCachedImage> createState() => _OrbitCachedImageState();
}

class _OrbitCachedImageState extends State<OrbitCachedImage> {
  static const _maxPendingRetries = 4;
  static int _pendingRetries = 0;
  Timer? _retry;
  int _attempt = 0;

  void _cancelRetry() {
    if (_retry != null) {
      _retry!.cancel();
      _retry = null;
      _pendingRetries--;
    }
  }

  @override
  void didUpdateWidget(OrbitCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _cancelRetry();
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _cancelRetry();
    super.dispose();
  }

  void _retryIfTransient(Object error) {
    final retryable = error is SocketException ||
        error is TimeoutException ||
        (error is HttpExceptionWithStatus &&
            (error.statusCode == 408 ||
                error.statusCode >= 500));
    if (!retryable ||
        _attempt != 0 ||
        _retry != null ||
        _pendingRetries >= _maxPendingRetries) {
      return;
    }
    _pendingRetries++;
    _retry = Timer(
      Duration(milliseconds: 1000 + widget.imageUrl.hashCode.abs() % 500),
      () {
        _retry = null;
        _pendingRetries--;
        if (mounted) setState(() => _attempt++);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return widget.errorWidget
              ?.call(context, widget.imageUrl, Exception('Empty URL')) ??
          const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth = widget.width ?? constraints.maxWidth;
        final decodeWidth = widget.memCacheWidth ??
            (widget.memCacheHeight != null
                ? null
                : logicalWidth.isFinite && logicalWidth > 0
                    ? math.min(
                        800,
                        (logicalWidth * MediaQuery.devicePixelRatioOf(context))
                            .ceil(),
                      )
                    : 800);
        return _ScrollGate(
          placeholder: (context) => (widget.placeholder ??
              (context, url) =>
                  const SizedBox.expand())(context, widget.imageUrl),
          child: () => PosterMetrics.enabled
              ? _PosterProbe(
                  key: ValueKey(widget.imageUrl),
                  builder: (probe) => _image(probe, decodeWidth),
                )
              : _image(null, decodeWidth),
        );
      },
    );
  }

  Widget _image(_PosterProbeState? probe, int? decodeWidth) {
    final basePlaceholder = widget.placeholder ??
        (context, url) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
    final baseError = widget.errorWidget ??
        (context, url, error) => const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            );
    return CachedNetworkImage(
      key: ValueKey(_attempt),
      imageUrl: widget.imageUrl,
      httpHeaders: widget.httpHeaders,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      imageBuilder: probe == null
          ? null
          : (context, provider) {
              probe.onImage();
              return Image(
                image: provider,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                filterQuality: widget.filterQuality,
              );
            },
      placeholder: (context, url) {
        probe?.onPlaceholder();
        return basePlaceholder(context, url);
      },
      errorWidget: (context, url, error) {
        probe?.onError();
        _retryIfTransient(error);
        return baseError(context, url, error);
      },
      memCacheWidth: decodeWidth,
      memCacheHeight: widget.memCacheHeight,
      fadeInDuration: widget.fadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
      filterQuality: widget.filterQuality,
      maxWidthDiskCache: widget.maxWidthDiskCache ?? 800,
      maxHeightDiskCache: widget.maxHeightDiskCache ?? 800,
      cacheManager: OrbitCacheManager.shared,
    );
  }
}

/// Retarde le démarrage du chargement tant que la liste défile très vite
/// (`Scrollable.recommendDeferredLoadingForContext`). Les tuiles qui quittent
/// l'écran avant la fin du fling ne lancent aucun téléchargement ni décodage ;
/// les vignettes visibles à l'arrêt passent en premier.
class _ScrollGate extends StatefulWidget {
  const _ScrollGate({required this.placeholder, required this.child});

  final WidgetBuilder placeholder;
  final Widget Function() child;

  @override
  State<_ScrollGate> createState() => _ScrollGateState();
}

class _ScrollGateState extends State<_ScrollGate> {
  bool _started = false;
  Timer? _retry;

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      if (Scrollable.recommendDeferredLoadingForContext(context)) {
        PosterMetrics.recordDeferred();
        _retry ??= Timer(const Duration(milliseconds: 100), () {
          _retry = null;
          if (mounted) setState(() {});
        });
        return widget.placeholder(context);
      }
      _started = true;
    }
    return widget.child();
  }
}

class _PosterProbe extends StatefulWidget {
  const _PosterProbe({super.key, required this.builder});

  final Widget Function(_PosterProbeState probe) builder;

  @override
  State<_PosterProbe> createState() => _PosterProbeState();
}

class _PosterProbeState extends State<_PosterProbe> {
  final Stopwatch _watch = Stopwatch()..start();
  bool _sawPlaceholder = false;
  bool _done = false;

  void onPlaceholder() => _sawPlaceholder = true;

  void onImage() {
    if (_done) return;
    _done = true;
    if (_sawPlaceholder) {
      PosterMetrics.recordLoaded(_watch.elapsedMilliseconds);
    } else {
      PosterMetrics.recordImmediate();
    }
  }

  void onError() {
    if (_done) return;
    _done = true;
    PosterMetrics.recordError();
  }

  @override
  void dispose() {
    if (!_done) PosterMetrics.recordAbandoned();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(this);
}
