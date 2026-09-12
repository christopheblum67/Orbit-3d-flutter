import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/src/cache_manager.dart';
import 'package:flutter_cache_manager/src/config/config.dart';

/// Wrapper `CachedNetworkImage` avec configuration de cache bornée par défaut.
///
/// - Disque : limite via `maxNrOfCacheObjects` (5000 objets) + TTL 30 jours
/// - Placeholder/error centralisés pour cohérence UX.
class CachedImage extends StatelessWidget {
  const CachedImage({
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

  // Config de cache bornée (statique = appliquée à toutes les instances)
  static const int _maxObjects = 5000;

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
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
      cacheManager: CacheManager(
        Config(
          'orbit_image_cache',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: _maxObjects,
        ),
      ),
    );
  }
}