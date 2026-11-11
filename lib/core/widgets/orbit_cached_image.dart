import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/image_cache_config.dart';
import 'package:orbit_3d_flutter/core/utils/poster_metrics.dart';

/// Wrapper `CachedNetworkImage` avec gestion de cache bornée (disque + mémoire).
///
/// Utilise `OrbitCacheManager` (5000 objets max, TTL 30 jours).
/// Placeholder/error unifiés pour cohérence UX.
class OrbitCachedImage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget?.call(context, imageUrl, Exception('Empty URL')) ??
          const SizedBox.shrink();
    }

    return _ScrollGate(
      placeholder: (context) => (placeholder ??
          (context, url) => const SizedBox.expand())(context, imageUrl),
      child: () => PosterMetrics.enabled
          ? _PosterProbe(
              key: ValueKey(imageUrl),
              builder: (probe) => _image(probe),
            )
          : _image(null),
    );
  }

  Widget _image(_PosterProbeState? probe) {
    final basePlaceholder = placeholder ??
        (context, url) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
    final baseError = errorWidget ??
        (context, url, error) => const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            );
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: probe == null
          ? null
          : (context, provider) {
              probe.onImage();
              return Image(
                image: provider,
                width: width,
                height: height,
                fit: fit,
                filterQuality: filterQuality,
              );
            },
      placeholder: (context, url) {
        probe?.onPlaceholder();
        return basePlaceholder(context, url);
      },
      errorWidget: (context, url, error) {
        probe?.onError();
        return baseError(context, url, error);
      },
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      filterQuality: filterQuality,
      maxWidthDiskCache: maxWidthDiskCache ?? 800,
      maxHeightDiskCache: maxHeightDiskCache ?? 800,
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
