import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/utils/image_cache_config.dart';

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

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ??
          (context, url) => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      errorWidget: errorWidget ??
          (context, url, error) => const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 32,
              ),
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      filterQuality: filterQuality,
      maxWidthDiskCache: maxWidthDiskCache ?? 800,
      maxHeightDiskCache: maxHeightDiskCache ?? 800,
      cacheManager: OrbitCacheManager(),
    );
  }
}